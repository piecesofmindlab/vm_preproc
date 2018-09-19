function mlSTRF_FitModel(dataSet,mask,WhichModel,OptsIn)
% 
% Usage: mlSTRF_FitModel(dataSet,mask,WhichModel,Opts)
%
% Generalized model fitting code. Relies on STRFlab conventions.
% 
% Inputs: 
%   SubID = string subject id (usually initials, e.g. 'ML')
%   dataSet = query struct to retrieve dataSet (struct) from database using
%       function mlLoadData.m
%   WhichModel = string identifier for model, e.g. 'HoG_128px_Color_02_03'
%   Opts = struct array of regression options, with fields: 
%         .NoisePreds = []; % Noise predictors (e.g., 'RETROICOR_01',
%               'VoxelPCs', etc.) 
%         .ValDat = 'unwrapped'; % 'unwrapped' [default] or 'mean': how to
%               predict validation data
%         .Lags = [2,3,4]; %TRs after stimulus onset
%         .ChunkSz = 5000;
%         .DataDir = '/auto/k6/mark/BVPpilot3_FitModels/';
%         .VoxMask = 'cortex';
%         .Path = []; % string path to file. 
%
% 201X ML
% Updated 2013.08 ML

% ADD PATHS
% If you're not Mark, you'll need these paths:
% addpath(genpath('/auto/k1/mark/MyCode/mlMatlab/'));
% rmpath(genpath('/auto/k1/mark/MyCode/mlMatlab/Experiment_Code/'))

% Misc. params: 
couchServer = 'http://meth:5984';
dbName = 'strfdb-ml';
db = mlabSTRFdb(couchServer,dbName);

% INPUTS
if ~exist('OptsIn','var')
    OptsIn = struct;
end
if isempty(mask)
    mask_nm = 'None';
    mask_xfm = 'None';
else
    mask_nm = mask.name;
    mask_xfm = mask.xfm;
end
% Default options:
Opts.NoisePreds = []; % 
Opts.ValDat = 'mean'; % 
Opts.collapseVal = []; % 
Opts.Lags = [2,3,4]; %TRs after stimulus onset
Opts.ChunkSz = 5000;
Opts.DataDir = '/auto/k8/mark/fMRIDB/';
Opts.VoxMask = mask_nm; %'backhalfcortex';
Opts.Reg = 'RidgeCV';
Opts.ValSeq = []; % order sequence for repeated blocks of validation data
Opts.ValBlockSz = []; % Size (in TRs) for repeaeted blocks of validation data
Opts.Type = 'fMRI_FitModel';
Opts.DateRun = datestr(now,'yyyy/mm/dd HH:MM'); %time.strftime('%Y/%M/%d %H:%M')
Opts.Overwrite = false;
Opts.SaveWeights = false;
Opts.PredMetrics = {'cc','ccCI','ccFull','valPred'};
% Update Opts struct with input
Opts = defaultOpt(OptsIn,Opts);
% Add argument fields from other inputs
warning('Hacky bullshit! Figure out what to do with potentially different trn/val sessions!')
if isfield(dataSet,'trn')
    dstmp = dataSet.trn;
else
    dstmp = dataSet;
end
Opts.Session = dstmp.Session;
Opts.SubID = dstmp.SubID;
Opts.Task = dstmp.Task; % Subject task 
Opts.Exp = dstmp.Exp;
Opts.Detrend = dstmp.Detrend; %'Median'; % default to basic median detrending
Opts.xfm = mask_xfm;
% SERIOUSLY UGLY BULLSHIT.
is_trn_only = ~isempty(strfind(Opts.Reg,'_trnOnly')); % or: only {'trn'} in trnval
idf = [db.prefix,'_id'];
if isfield(dataSet,'trn')
    if ~isfield(dataSet.trn,[db.prefix,'_id'])
        tmp = db.query({1,dataSet.trn});
    else
        tmp = dataSet.trn;
    end
    Opts.trn_id = tmp.(idf);
end
if isfield(dataSet,'val') && ~is_trn_only
    if ~isfield(dataSet.trn,[db.prefix,'_id'])
        tmp = db.query({1,dataSet.val});
    else
        tmp = dataSet.val;
    end
    Opts.val_id = tmp.(idf);
end
if ~isfield(dataSet,'trn') && iscell(dataSet.trnval)
    for iTV = 1:length(dataSet.trnval)
        tmpq = dataSet;
        tv = dataSet.trnval{iTV};
        % More hacky bullshit
        if ismember(tv,{'val','val_Full'}) && is_trn_only
            continue
        end
        tmpq.trnval = tv;
        tmp = db.query({1,tmpq});
        Opts.([strrep(tv,'_Full','') '_id']) = tmp.(idf);
    end
end

% Last check that we have IDs incorporated
if ~isfield(Opts,'val_id') && ~is_trn_only
    error('No validation data ID found!')
end
if ~isfield(Opts,'trn_id')
    error('No training data ID found!')
end
%/SERIOUSLY UGLY BULLSHIT

% Later we will set this: Opts.Mod = WhichModel; % convention is to use TRAINING model

if size(Opts.ValSeq,1)>size(Opts.ValSeq,2)
    % Should be a horizontal vector (for consistency in database)
    Opts.ValSeq = Opts.ValSeq';
end

% Get model from database
[qStim,qMod] = WhichModel{:};
fprintf('\n\n--- Loading stimulus model! ---\n\n')
[S,M] = dbGetModels(qStim,qMod,{'trn','val'},db);
Opts.Mod = M.trn;

% Check for existence of IDENTICAL model in database:
% *identical except for these fields, which we don't care about: 
Exclude = {'DataDir','ChunkSz','AxLabel','Descr','DateRun','Overwrite'}; % do not match these items
qStr = Opts;
for iE = 1:length(Exclude);
    if isfield(qStr,Exclude{iE})
        qStr = rmfield(qStr,Exclude{iE});
    end
end
fprintf('\n\n--- Checking for existence of fit model! ---\n\n')
OldModels = db.(qStr);
if isempty(OldModels)
    % Create new ID/path
    ID = db.getUUID;
    Opts.([db.prefix,'_id']) = ID;
    Opts.Path = fullfile(Opts.DataDir,[ID,'.mat']);
elseif length(OldModels)==1
    if ~Opts.Overwrite
        fprintf('\nModel has already been run!\n\n')
        return    
    else
        fprintf('Replacing file %s\n',OldModels.Path);
        for iE = 1:length(Exclude)
            if isfield(Opts,Exclude{iE})
                OldModels.(Exclude{iE}) = Opts.(Exclude{iE});
            end
        end
        Opts = OldModels;
    end
elseif length(OldModels)>1
    error('Multiple models match this model''s parameters!')
end

% Check that path is correct
[pChk,fNm,ext] = fileparts(Opts.Path);
if ~strcmp(pChk,Opts.DataDir)
    Opts.Path = fullfile(Opts.DataDir,[fNm ext]);
end
% Get training / validation responses 
% TO DO: Change to db-based system!
if strcmp(dataSet,'FakeData')
    [FD,Wts] = FakeData(dataSet);
    trnResp0 = FD.trn;
    valResp0 = FD.val;
else
    % New 2013.03.25: always load full validation data!
%     if strfind(Opts.Exp,'BVP')
%         data = mlLoadData(SubID,dataSet,Opts.VoxMask,Opts.Task,Opts.Detrend,'single','_Full',Opts.Session);
%     else
%         data = mlLoadData(SubID,dataSet,Opts.VoxMask,Opts.Task,Opts.Detrend,'single','',Opts.Session);
%     end
%     % If data is 3D, mask data:
%     if ndims(data.trn)>2 && ndims(data.val)>2
%         data.trn= reshape(data.trn,numel(data.trn)/size(data.trn,4),size(data.trn,4));
%         data.trn = single(data.trn(data.mask(:),:)');
%         data.val = reshape(data.val,numel(data.val)/size(data.val,4),size(data.val,4));
%         data.val = single(data.val(data.mask(:),:)');
%     end
    fprintf('\n\n--- Loading fMRI Data! ---\n\n')
    data = mlLoadData(dataSet,mask,db,'single');
end

% Build design matrix from model
% (1) Add lags
if any(Opts.Lags)
    X = addLags(S.trn,Opts.Lags);
    Xval = addLags(S.val,Opts.Lags);
else
    X = S.trn;
    Xval = S.val;
end
% (2) Add nuisance/noise regressors, one by one
Opts.nNuisancePreds = 0;
for iP = 1:length(Opts.NoisePreds)
    % TO DO (maybe): add lags to nuisance preds? 
    % TO DO (For sure): Load as we load other models, from db, as / from
    % PreprocessedStimulus class
    %fin = regexp(dataSet,'_Ses','start')-1;
    %if isempty(fin)
    %    error('What session, bozo?')
    %end
    %ds = dataSet(1:fin);
    %ses = dataSet(fin+1:end);
    tmp = load(['/auto/k6/mark/' dataSet '_ModelParams/' Opts.NoisePreds{iP} '_Trn.mat']);
    X = [X,tmp.Spreproc];
    nNP = size(tmp.Spreproc,2);
    %tmp = load(['/auto/k6/mark/' dataSet '_ModelParams/' Opts.NoisePreds{iP} '_Val.mat']);
    % RespOrd??
    %nValRpt = length(Opts.ValSeq)/length(unique(Opts.ValSeq));
    %if size(tmp.Spreproc,1)==nValRpt*size(Xval,1)
    %    % Unwrap data if required
    %    Xval = unwrapValData(Xval,Opts.ValSeq,Opts.ValBlockSz);
    %end
    %
    %Xval = [Xval,tmp.Spreproc];
    %if size(tmp.Spreproc,2)==nNP % check that trn/val have same number of preds
    %    % Track number of nuisance regressors so we can get rid of them later  
    Opts.nNuisancePreds = Opts.nNuisancePreds + nNP; 
    %else
    %    error(sprintf('Number of nuisance variables for training and validation data is not the same! (%s)',Opts.NoisePreds{iP}));
    %end
end
% (3) Add ones as FIRST column 
X = [ones(size(X,1),1),X];
Xval = [ones(size(Xval,1),1),Xval];

% For intelligibility of code:
nVoxels = size(data.trn,2);
[nSamples,nParams] = size(X);

% Regress!
switch Opts.Reg % choose regression function to use
    case 'OLS'
        warning('Need to update with predMetrics field for params!')
        % Model
        model.trn = X;
        model.val = Xval;
        % Options
        if strcmp(Opts.ValDat,'unwrapped') && ~isempty(Opts.collapseVal) && Opts.collapseVal.unwrapModel % This is shitty and should be fixed to be consistent... but lots of back code uses "unwrapped"
            nValRpt = length(Opts.ValSeq)/length(unique(Opts.ValSeq));
            % nValRpt * size(data.val,1) = 10rpt * 90 data points = 900 =?= model size
            if ~nValRpt*size(data.val,1)==size(model.val,1)
                % Unwrap data if required
                model.val = unwrapValData(model.val,Opts.ValSeq,Opts.ValBlockSz);
            end
            params.collapseVal = Opts.collapseVal;
            params.collapseVal.seq = Opts.ValSeq;
            params.collapseVal.blockSz = Opts.ValBlockSz;
        end
        params.ChunkSz = Opts.ChunkSz;
        % Regression
        Result = ols(data,model,params);
        fn = fieldnames(Result);
        for iFn = 1:length(fn);
            eval([fn{iFn} ' = Result.' fn{iFn} ';']);
        end
        VarsToSave = {'valPred','cc','ccCI','ccFull','sigThresh','mask','Opts'};
        if Opts.SaveWeights
            VarsToSave = [VarsToSave,'weights'];
        end
    case 'RidgeCV'
        % Model
        model.trn = X;
        model.val = Xval;
        % Options
        if ~isempty(Opts.collapseVal)
            if Opts.collapseVal.unwrapModel
                % Unwrap data if required
                model.val = unwrapValData(model.val,Opts.ValSeq,Opts.ValBlockSz);
            end
            % Mild legacy stuff here: Opts.ValSeq & Opts.ValBlockSz were
            % originally separate parameters, "collapseVal" was added later
            params.collapseVal = Opts.collapseVal;
            params.collapseVal.seq = Opts.ValSeq;
            params.collapseVal.blockSz = Opts.ValBlockSz;
        end
        %params.nResamps = 2;% TEMP!! I SHOULD BE COMMENTED OUT EXCEPT FOR DEBUGGING!
        params.chunkSz = Opts.ChunkSz;
        params.predMetrics = Opts.PredMetrics; %'valPredFull'
        % Regression
        Result = ridgeCV(data,model,params);
        fn = fieldnames(Result);
        for iFn = 1:length(fn);
            eval([fn{iFn} ' = Result.' fn{iFn} ';']);
        end
        VarsToSave = [params.predMetrics,{'mask','sigThresh','nSigVox_byLambda','Opts'}];
        if Opts.SaveWeights
            VarsToSave = [VarsToSave,'weights'];
        end
    case 'RidgeCV_trnOnly'
        % Model
        model.trn = X;
        model.val = Xval;
        % Options
        params.chunkSz = Opts.ChunkSz;
        % Too many cv splits! Too much computation time! => switched to 3,5
        % on 2012.07.16
        params.nResamps = 3; % number of times to run cross-validation for lambdas
        params.nPartitions = 5; % determines size of train/validate chunks for Cross-validation. 10 = 90% train / 10% val
        %params.Efficient = false; % Use eig rather than SVD for big models.
        % Fewer cv splits for overall accuracy:
        pp.PP = params;
        pp.nResamps = 3;
        pp.nPartitions = 5;
        % Regression
        Result = ridgeCV_trnOnly(data,model,pp);
        fn = fieldnames(Result);
        for iFn = 1:length(fn);
            eval([fn{iFn} ' = Result.' fn{iFn} ';']);
        end
        VarsToSave = {'cc','ccCI','mask','sigThresh','nSigVox_byLambda','Opts'};
    case 'RidgeCV_Sparse'
        % Run Ridge regression
        Opt.lambda_start = 2e6; % to correspond w/ above RidgeCV
        Opt.lambda_scale = .5; % update value for lambdas
        Opt.group_idx = [1:size(S.trn,2),1:size(S.trn,2),1:size(S.trn,2)]; % Group by delays
        nResamps = 5; % number of times to run cross-validation for lambdas
        nPartitions = 10; % determines size of train/validate chunks for Cross-validation. 10 = 90% train / 10% val
        % nResamps must be <= nPartitions for this to work (see randPartition.m code for why).

        % weights is an pParameters x nVoxels matrix
        %weights = zeros(nParams,Opts.ChunkSz,length(Ks),'single');
        % Because "weights" can be very large (and taxing on memory),
        % do this in chunks...
        % Split into c chunks and run separately:
        nChunks = ceil(nVoxels/Opts.ChunkSz);
        % Preallocate cc, ccCI, weights, valPred
        cc = zeros(1,nVoxels,'single');
        ccCI = zeros(2,nVoxels,'single');
        weights = nan(nParams,nVoxels,'single');
        valPred = zeros(size(data.val),'single'); % NOTE: strong assumptions about size of matrix...
        for iChunk = 1:nChunks
            fprintf('Running chunk %d of %d...\n',iChunk,nChunks);
            ChIdx = (1:Opts.ChunkSz) + Opts.ChunkSz*(iChunk-1);
            ChIdx(ChIdx>nVoxels) = []; % clip extra voxels in last run.
            Ych = trnResp0(:,ChIdx); 
            Xch = X;
            YchVal = data.val(:,ChIdx);
            XchVal = Xval;
            [partDat partIdx] = randPartition(Ych,nPartitions,1); % Partition along 1st dimension (time samples)
            WtTmp = nan(nParams,length(ChIdx),nResamps);
            for iRS = 1:nResamps
                div = '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
                fprintf('%s\n ~~~ Running resample %d of %d... ~~~\n%s\n',div,iRS,nResamps,div);
                trIdx = ~ismember(1:nPartitions,iRS);
                Ych_RS = cat(1,partDat{trIdx});
                trainIdx = [partIdx{trIdx}]';
                Xch_RS = Xch(trainIdx,:);
                YchVal_RS = partDat{iRS};
                valIdx = partIdx{iRS}';
                XchVal_RS = Xch(valIdx,:);
                % Fit model with all Ks (for subset of voxels)
                %warning('set group_index field!')
                %Opt.group_index = ones(size(1)); % Not yet
                [WtTmp(:,:,iRS) Opts] = sparse_ridgemulti(Xch_RS,Ych_RS,XchVal_RS,YchVal_RS,Opt);
                %fprintf('Checking model predictions...\n');
                %for iK = 1:length(Ks)
                %    valPred = single(Xval*Wt(:,:,iK));
                %    % PREDICTION ACCURACY (CORRELATIONS)
                %    [cc(ChIdx,iK,iRS),Dummy]=ccMatrix(valPred,valResp_RS(:,ChIdx),1);
                %end
            end
            Wt = single(nanmean(WtTmp,3));
            weights(:,ChIdx) = Wt;
            % Having chosen weights, predict withheld data            
            fprintf('Obtaining model predictions...\n');
            % Correlations
            tmpPred = single(Xval*Wt);
            if Opts.RespOrdPreds
                % To recombine:
                v = load('/auto/k1/mark/Projects-GLab/BVP_StimPres/BVPpilot1_Movies/ValSeq.mat');
                ii = reshape(1:90,30,3);
                nidx = ii(:,v.seq);
                nidx = nidx(:);
                for iG = 1:90; 
                    tmpPredN(iG,:) = mean(tmpPred(nidx==iG,:)); 
                end
                valPred(:,ChIdx) = tmpPredN;
                clear tmpPredN
            else
                valPred(:,ChIdx) = tmpPred;
            end
            [cc(ChIdx),ccCI(:,ChIdx)]=ccMatrix(valPred(:,ChIdx),YchVal,1);
    
        end
        VarsToSave = {'cc','ccCI','valPred','mask','sigThresh','Opts'};
        if Opts.SaveWeights
            VarsToSave = [VarsToSave,'weights'];
        end

end
%clear trnResp_RS valResp_RS Wt Ychunk

% Create db entry:
status = dbSave(Opts,couchServer,dbName); % in database
% Check if entered in db correctly:
display(status)
% Save Results
save(Opts.Path,VarsToSave{:},'-v7.3') % v7.3 for large matrices. 

fprintf(' --- All done! --- \n\n')
%catch
%    mlErrorCleanup;
%    rethrow(error_struct);
%end