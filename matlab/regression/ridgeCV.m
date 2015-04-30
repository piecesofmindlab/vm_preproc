function Result = ridgeCV(data,model,params)
% Usage: Result = ridgeCV(data,model,params)
%
% Cross-validated ridge regression. Chooses optimal lambda (regularization)
% parameter based on cross validation within the training data, then
% correlates predicted response with (withheld) validation data.
% 
% For no cross validation, set params.nResamps  and params.nPartitions to 1
% To run the whole brain at once (rather than in separate chunks of voxels
% to save memory), set params.chunkSz to a value larger than the number of
% voxels in the brain. 
% 
% If .val fields from "data" and "model" are omitted, the model is fit but
% no correlation with withheld data is computed.
%
% Inputs:
% data - a struct, created by mlLoadData, with fields:
%    .trn - model training data
%    .val - model validation data
%    .mask - mask for voxel selection (whole brain, cortex only, ROI, etc)
%    .voxType - (optional?) specifies which kind of mask .mask is
% model - a struct with fields:
%    .trn - model params for training data
%    .val - model params for validation data
% params (optional) is a struct with the fields: 
%    .lambda = [] - if left empty (default), tries lambda = [0,2.^(10:20)]
%    .chunkSz = 5000 % number of voxels to run at once 
%    .nResamps = 10 % number of times to run cross-validation for lambdas
%    .nPartitions = 10 % determines size of train/validate chunks for
%                      % bootstrapping lambda values. 10=90% train/10% val
%                      % NOTE: nResamps must be <= nPartitions
%    .collapseVal = parameters if we want to predict whole validation data
%                   (not averaged data) and THEN average it. This is a
%                   struct array with fields: 
%           .seq = sequence of blocks over all validation data
%           .BlockSz = length of each block (in TRs) (usu. 30 = 1 minute)
%    .predMetrics = cell array with some subset of the following values:
%           {'cc','R2','resids','residsFull','valPred','valPredFull'}
%
% Outputs: 
% Result is a struct with fields: 
%    .weights
%    .lambda = lambda values used
%    .nSigVox_byLambda = significant voxels by lambda value (used to decide
%          on lambda)
%    % Specify which of the following you want returned in
%       "params.predMetrics"
%    [.cc] = correlation coefficient of model prediction with withheld data
%          set (if model.val and data.val are provided) 
%    [.cc_ci] = confidence interval for cc (goes with cc)
%    [.R2] = R^2 metric for explained variance
%    [.valPred] = predictions for validation timecourse
%    [.valPredFull] = predictions for validation timecourse before
%               averaging over repeats
%    [.resids] = residual error after predictions
%    [.residsFull] = residual error after prediction (before averaging of
%               repeats in the stimulus)
% 
% ML 2011.12.21 based mostly on code from DS and SN

% TO DO: 
% () PARALLELIZE?? Split run into slurm runs?? optional parameter for
%    split to multiple slurm jobs? 
% () Create option to use lambda by voxel instead of sum across voxels
% Inputs
if ~isa(model.trn,'double');
    warning('Converting design matrix to double-precision float for SVD decomposition!')
    model.trn = double(model.trn);
end
if isfield(model,'val') && ~isa(model.val,'double');
    model.val = double(model.val);
end
% Default parameter values
DefaultParams.lambdas = [0,2.^(10:20)]; % Regularization parameters for ridge regression
DefaultParams.chunkSz = 5000; % number of voxels to regress at once (memory-saving)
% TO DO: Compute based on model size?? smaller models -> larger chunks
DefaultParams.nResamps = 10; % number of times to run cross-validation for lambdas
DefaultParams.nPartitions = 10; % determines size of train/validate chunks for Cross-validation. 10 = 90% train / 10% val
DefaultParams.Verbose = true;
DefaultParams.Efficient = nan;
DefaultParams.collapseVal = [];
DefaultParams.predMetrics = {'valPred','cc','ccCI'}; %'R2','resids','residsFull','valPredFull'
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,DefaultParams);

if params.nResamps > params.nPartitions
    error('nResamps must be <= nPartitions for bootstrapping to work!')
end


fprintf('Model size is: %d channels\n',max(size(model.trn)));
if isnan(params.Efficient)
    % Choose which method based on size of models
    % This limit is (somewhat) arbitrary as of 2012.07.18!
    trnModSzLim = 20000;
    params.Efficient = max(size(model.trn))<trnModSzLim;
end
if params.Efficient
    div = repmat('-',50,1);
    fprintf('%s\nUsing A. Huth''s SVD efficiency speed-up for ridge regression.\nMay not be optimal for large models!!\n%s\n',div,div)
else
    div = repmat('-',50,1);
    fprintf('%s\nUsing eigenvalue decomposition of stimulus matrix for ridge regression.\nSlower, better for large models.\n%s\n',div,div)    
end
% Pre-allocate variables
[nTP,nVoxels] = size(data.trn);
nParams = size(model.trn,2);
cc = zeros(nVoxels,length(params.lambdas),params.nResamps);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% --- Part 1: Cross validate to find optimal lambda --- %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%[partDat partIdx] = randPartition(data.trn,params.nPartitions,1); % last argument is a dimension index (which dimension of matrix to partition)
[partDat partIdx] = contigPartition(data.trn,params.nPartitions,1); % last argument is a dimension index (which dimension of matrix to partition)
for iRS = 1:params.nResamps
    if params.Verbose; 
        div = '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
        fprintf('%s\n ~~~ Running resample %d of %d... ~~~\n%s\n',div,iRS,params.nResamps,div);
    end
    trIdx = ~ismember(1:params.nPartitions,iRS);
    trnResp_RS = cat(1,partDat{trIdx});
    trainIdx = [partIdx{trIdx}]';
    X = model.trn(trainIdx,:);
    valResp_RS = partDat{iRS};
    valIdx = partIdx{iRS}';
    Xval = model.trn(valIdx,:);
    % weights is an pParameters x nVoxels matrix
    % Because weight matrices can be very large (i.e. taxing on memory),
    % split into c chunks and run separately:
    nChunks = ceil(nVoxels/params.chunkSz);
    if params.Verbose; disp('about to start chunk loop'); end
    if params.Efficient
        % Efficient Ridge regression from A. Huth, Part (1):
        % Full multiplication for validation (here, random split of
        % training data) prediction is: 
        % valPred = (Xval*Vx) * Dx * (pinv(Ux)*Ychunk)   % NOTE: pinv(Ux) = Ux'
        % We will pre-compute the first and third terms in parentheses:
        % valPred =   XvalVx  * Dx *  UxYchunk
        if params.Verbose; disp('->Doing SVD of stimulus design matrix'); t0=clock; end
        pause(.01); % To ensure printing?
        [m,n] = size(X);
        if m>n
            [Ux,Sx,Vx] = svd(X,0);
        else
            [Vx,Sx,Ux] = svd(X',0);            
        end
        if params.Verbose; fprintf('->Done with SVD in %.2f sec\n',etime(clock,t0)); end
        % For more efficient computation:
        sx = diag(Sx);
        k = length(sx); % k = min(m,n) for an m x n matrix 
        % OR: 
        % singcutoff = (XX);
        % k = sum(sx > singcutoff);
        % sx = sx(1:k);
        Ux = Ux(:,1:k);
        Vx = Vx(:,1:k);
        XvalVx = Xval*Vx; % NOTE: No Vx', because Matlab leaves V in transposed form!
    end
    for iChunk = 1:nChunks
        fprintf('Running chunk %d of %d...\n',iChunk,nChunks);
        ChIdx = (1:params.chunkSz) + params.chunkSz*(iChunk-1);
        ChIdx(ChIdx>nVoxels) = []; % clip extra voxels in last run.
        Ychunk = trnResp_RS(:,ChIdx);
        % Fit model with all lambdas (for subset of voxels)
        if ~params.Efficient
            [Wt L] = ridgemulti(X,Ychunk,params.lambdas);
        else
            % Efficient Ridge regression from A. Huth, part (2)
            % NOTE: weights are never explicitly computed!
            % Check for nans in data?
            UxYchunk = Ux' * Ychunk;
        end
        
        if params.Verbose; fprintf('Checking model predictions...\n'); end
        for iK = 1:length(params.lambdas)
            if ~params.Efficient
                valPred = single(Xval*Wt(:,:,iK));
            else
                % Efficient Ridge regression from A. Huth, part (3)
                a = params.lambdas(iK);
                % Normalize lambda by Frobenius norm for stim matrix
                aX = a; % * norm(X,'fro');
                %Dx = Sx./(Sx.^2 + aX^2); 
                Dx = sx./(sx.^2 + aX); 
                % Dx is same btw. python & matlab
                %figure(1);
                %hold on; 
                %plot(Dx);
                %hold off;
                %keyboard;
                % XvalVx and UxYchunk computed above
                %valPred = (Dx * XvalVx) * UxYchunk; % The line below is
                % equivalent to this, but more efficient
                valPred = bsxfun(@times,Dx',XvalVx) * UxYchunk;
            end
            % PREDICTION ACCURACY (CORRELATIONS)
            [cc(ChIdx,iK,iRS),Dummy]=ccMatrix(valPred,valResp_RS(:,ChIdx),1);
            sigThreshTmp = pval2r(.005,size(valResp_RS,1));
        end
    end
end
if params.Verbose; fprintf('Choosing lambda value...\n'); end
cc_byLambdabyVox = nanmean(cc,3); % Take average prediction accuracy across cross-validations
% Difference between above / below thresh prevents biasing to low lambda
% values. Low lambdas will give more high AND low correlations, which we do
% not necessarily want.
Result.lambda = params.lambdas;
%TEMP
Result.cc_byLambdabyVox = cc_byLambdabyVox;
Result.nSigVox_byLambda = sum(cc_byLambdabyVox>sigThreshTmp)-sum(cc_byLambdabyVox<-sigThreshTmp);
[Dummy,kIdx] = max(Result.nSigVox_byLambda);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% --- Part 2: use optimal lambda to regress    --- %%%%%%%%%%%%%
%%%%%%%%%%%% --- on whole data set and predict validation data --- %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if params.Verbose;
    fprintf('Bootstrapping complete; running full regression...\n');
end

if isfield(model,'val') && isfield(data,'val')
    Result.sigThresh = pval2r(.005,size(data.val,1)); % ???
    % Validation data / model supplied - 
    X0val = model.val;
    valResp0 = data.val;
    Result.cc = zeros(1,nVoxels,'single');
    Result.ccCI = zeros(2,nVoxels,'single');
    Validation_Present = true;
    nTRsVal = size(valResp0,1);
    if ~isempty(params.collapseVal) && params.collapseVal.collapseData
        nTRsVal = nTRsVal/(length(params.collapseVal.seq)/length(unique(params.collapseVal.seq)));
    end
    Result.valPred = zeros(nTRsVal,nVoxels,'single'); % NOTE: strong assumptions about size of matrix...
else
    Validation_Present = false;
end

% Pre-allocate variables
Result.weights = zeros(nParams,nVoxels,'single');
Result.resids = zeros(size(X0val,1),nVoxels,'single');
Result.modScale = zeros(2,nVoxels,'single');
nChunks = ceil(nVoxels/params.chunkSz);
for iChunk = 1:nChunks
    if params.Verbose; fprintf('Running chunk %d of %d...\n',iChunk,nChunks); end
    ChIdx = (1:params.chunkSz) + params.chunkSz*(iChunk-1);
    ChIdx(ChIdx>nVoxels) = []; % clip extra voxels in last run.
    Ychunk = data.trn(:,ChIdx);
    % Fit model with ONE lambda:
    if ~params.Efficient
        % Shinji-style: use eigen value decomposition of stimulus
        % matrix
        %[ws L] = ridgemulti(model.trn,Ychunk,params.lambdas(kIdx));
        as = params.lambdas(kIdx);
        if size(model.trn,2)>size(model.trn,1)
            cmode = 1;
            cnum = size(model.trn,1);
        else
            cmode = 0;
            cnum = size(model.trn,2);
        end
        if cmode
            [U S] = eig(model.trn*model.trn');
        else
            [U S] = eig(model.trn'*model.trn);
        end
        ds = diag(S);
        % Preallocate weights
        ws = zeros(size(model.trn,2),size(Ychunk,2),length(as),'single');
        % Compute ridge regression for all regularization parameters
        for ii=1:length(as)
            Sd = diag(1./(ds+as(ii)));
            rc = (U*Sd*U');
            if cmode
                ws(:,:,ii) = model.trn'*rc*Ychunk;
            else
                ws(:,:,ii) = rc*model.trn'*Ychunk;
            end
        end
    else
        % Alex-style: use svd decomposition of stimulus matrix
        [m,n] = size(model.trn);
        if m>n
            [Uxp,Sxp,Vxp] = svd(model.trn,0);
        else
            [Vxp,Sxp,Uxp] = svd(model.trn',0);
        end
        % For more efficient computation:
        sxp = diag(Sxp);
        k = length(sxp); % k = min(m,n) for an m x n matrix % OR: k = sum(sxp > singcutoff);
        % sxp = sxp(1:k);
        Uxp = Uxp(:,1:k);
        Vxp = Vxp(:,1:k);
        %XvalVxp = Xval*Vxp; % NOTE: No Vxp', because Matlab leaves V in transposed form!
        a = params.lambdas(kIdx);
        % Normalize lambda by Frobenius norm for stim matrix
        aX = a; % * norm(X,'fro');
        %Dx = Sx./(Sx.^2 + aX^2);
        Dx = sxp./(sxp.^2 + aX);
        UxpYchunk = Uxp'*Ychunk;
        %ws = Vxp * diag(Dx) * UxpYchunk;
        ws = bsxfun(@times,Dx',Vxp) * UxpYchunk; % more efficient
    end
    % Done here, scaling over-fits for bad voxels; will it always??
    % Doesn't really matter if we're not using R^2 as a metric;
    %     % Scale model weights (which may be too low due to regularization (??)) to appropriate size & adjust offset:
    %     disp('Scaling model...')
    %     tic;
    %     % Note: now each voxel does NOT have the same model (X)
    %     trnPred = model.trn*ws;
    %     for iVox = 1:size(Ychunk,2);
    %         progressdot(iVox,200,2000,size(Ychunk,2));
    %         Xv = [ones(nTP,1),trnPred(:,iVox)];% X for this voxel
    %         Result.modScale(:,iVox) = inv(Xv'*Xv)*(Xv'*Ychunk(:,iVox));
    %     end
    %     toc
    % Keep final weights
    Result.weights(:,ChIdx) = ws;
    if params.Verbose; fprintf('Obtaining model predictions...\n'); end
    if Validation_Present
        % Get prediction
        fin = size(X0val,2); % Only use as many channels as are in validation data (Gets rid of noise predictors)
        % Will this be appropriate size? it will be large if validation
        % data is large OR small.
        tmpPred = single(X0val*Result.weights(1:fin,ChIdx));
        Result.valPredFull(:,ChIdx) = tmpPred;
        % Compute R^2
        if ismember('R2',params.predMetrics)
            % NOTE: this should only be done with full, UNFOLDED validation
            % data (before averaging over repeats), if we want a comparable
            % metric to variance explained by the mean
            % Test whether sizes of predictions and validation data match
            if ~all(size(valResp0(:,ChIdx))==size(tmpPred))
                error([mfilename ':PredValDataMismatch'],...
                    ['Mismatch in validation data / prediction size! either unwrap your design matrix to \n'...
                    'match data size or average your data to match design matrix size!'])
            end
            Result.resids(:,ChIdx) = valResp0(:,ChIdx)-tmpPred;
            modVar = var(Result.resids(:,ChIdx),[],1);
            totVar = var(valResp0(:,ChIdx),[],1);
            Result.R2(ChIdx) = 1-(modVar./totVar);
        end
        if ismember('ccFull',params.predMetrics)
            tmpPredRpt = separateValRepeats(tmpPred,params.collapseVal.seq,params.collapseVal.blockSz);
            tmpDatRpt = separateValRepeats(data.val(:,ChIdx),params.collapseVal.seq,params.collapseVal.blockSz);
            for iRpt = 1:size(tmpDatRpt,2)
                Result.ccFull(ChIdx,iRpt) = ccMatrix(squeeze(tmpPredRpt(:,iRpt,:)),squeeze(tmpDatRpt(:,iRpt,:)),1);
            end
        end
        % Optionally, collapse validation data back to mean
        if ~isempty(params.collapseVal) && params.collapseVal.collapseModel
            % Collapse full validation set by averaging over repeated blocks
            Result.valPred(:,ChIdx) = collapseValData(tmpPred,params.collapseVal.seq,params.collapseVal.blockSz);
        else
            Result.valPred(:,ChIdx) = tmpPred;
        end
        if ~isempty(params.collapseVal) && params.collapseVal.collapseData
            if iChunk==1
                valRespToPred = collapseValData(valResp0,params.collapseVal.seq,params.collapseVal.blockSz);
            end
        else
            valRespToPred = valResp0;
        end
        % Replace with code to compute correlation! (This is copied from DS
        % code)
        if ismember('cc',params.predMetrics)
            [Result.cc(ChIdx),Result.ccCI(:,ChIdx)]=ccMatrix(Result.valPred(:,ChIdx),valRespToPred(:,ChIdx),1);
        end
    end
end
% Cull fields to return
Rfn = fieldnames(Result);
keepers = {'nSigVox_byLambda','lambda','weights','sigThresh'};
for iPM = 1:length(Rfn)
    pm = Rfn{iPM};
    if ~ismember(pm,params.predMetrics) && isfield(Result,pm) && ~ismember(pm,keepers)
        Result = rmfield(Result,pm);
    end
end
% Keep mask data:
if isfield(data,'mask')
    Result.mask = data.mask;
end
if isfield(data,'voxType')
    Result.voxType = data.voxType;
end