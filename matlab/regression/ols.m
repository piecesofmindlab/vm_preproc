function Result = ols(data,model,params)
% Usage: Result = ols(data,model,params)
%
% (weighted) Ordinary Least Squares regression. Solves
%
%                  y = x*Result.weights + noise
%
% by minimizing
%                  ||x*Beta - y||^2
% 
% Inputs:
% data is a struct with fields "trn" and "val" for model training and
%       validation data, as well as "mask" (specifying which voxels within
%       volume are being modeled) and "voxType" to specify which type of
%       voxel selection has been performed (Create "data" variable with
%       mlLoadData)   
% model is a struct with fields "trn" and "val" for model parameters for
%       training and validation data sets. 
% params (optional) is a struct with the fields: 
%    .weights = (N x 1) vector of observation weights (e.g.
%               standard deviation of input vectors) to use in
%               weighted least squares. If not provided, assumes
%               equal weighting for all inputs. In general, not terribly
%               useful for z-scored data / models.
%    .chunkSz = 1000000 % number of voxels to run at once 
%    .collapseVal = parameters if we want to predict whole validation data
%                   (not averaged data) and THEN average it. This is a
%                   struct array with fields: 
%           .seq = sequence of blocks over all validation data
%           .BlockSz = length of each block (in TRs) (usu. 30 = 1 minute)
%    .addmean = boolean, whether to add 
% Outputs: 
% Results is a struct with fields: 
%    .weights
%    .cc = correlation coefficient of model prediction with withheld data
%          set (if model.val and data.val are provided) 
%    .cc_ci = confidence interval for cc
%    .mask = brain mask used for voxel selection of data
%    .voxType = type of mask used (string), e.g. 'Cortex'
% 
% ML 2011.12.21 based mostly on code from DS and SN


% Inputs
dparams.addmean = true;
dparams.chunkSz = 1000000;
dparams.saveFullPred = false;
dparams.Verbose = true;
% Fill in defaults
if ~exist('params','var')||isempty(params)
    params = struct();
end
params = defaultOpt(params,dparams);

Flag.Verbose = params.Verbose;
x = model.trn;
if params.addmean
    % conditionally add dc term (<column> of ones)
    % (only add if it's not already there)
    if sum(x(:,1)) ~= size(x,1)
        x = [ones(size(x,1),1),x];
    end
end
% [nMeasure, nDim] = size(x);
nVoxels = size(data.trn,2);
[nSamples,nParams] = size(x);

if ~isfield(params,'weights')
	W = eye(nSamples);
else 
    warning('untested code following!')
    keyboard
	if numel(params.weights) == (nMeasure - 1)
		params.weights = [1;params.weights]; % ADD BIAS TERM
	end
	W = diag(1./params.weights.^2);
end
% compute pseudo-inverse of (weighted) squared design matrix
xc = pinv(x'*W*x); 

if isfield(model,'val') && isfield(data,'val') %|| ~isfield(data,'val')
    % Validation data / model supplied 
    xv = model.val;
    % Conditionally add dc term
    if sum(xv(:,1)) ~= size(xv,1)
        xv = [ones(size(xv,1),1),xv];
    end
    Result.valPred = zeros(size(data.val),'single'); 
    Result.cc = zeros(1,nVoxels,'single');
    Result.ccCI = zeros(2,nVoxels,'single');
    if params.saveFullPred
        Result.valPredFull = zeros(size(xv,1),nVoxels);
    end
    DoCorr = true;
else
    DoCorr = false;
end

% Pre-allocate variables
Result.weights = zeros(nParams,nVoxels,'single');
% Divide data into chunks if necessary for memory saving:
nChunks = ceil(nVoxels/params.chunkSz);
for iChunk = 1:nChunks
    if Flag.Verbose; fprintf('Running chunk %d of %d...\n',iChunk,nChunks); end
    ChIdx = (1:params.chunkSz) + params.chunkSz*(iChunk-1);
    ChIdx(ChIdx>nVoxels) = []; % clip extra voxels in last chunk.
    Ychunk =data.trn(:,ChIdx);
    
    % Run OLS for this chunk of training data
    Result.weights(:,ChIdx) = xc*(x'*(W*Ychunk));  % 
    
    if Flag.Verbose; fprintf('Obtaining model predictions...\n'); end
    if DoCorr
        % Compute correlations btw validation data and model prediction
        tmpPred = single(xv*Result.weights(:,ChIdx));
        if isfield(params,'collapseVal')
            % Collapse full validation set down to size of stored validation
            % data by applying averaging over repeated blocks.
            nShufChunk = length(unique(params.collapseVal.seq));
            ShufChunkSz = params.collapseVal.blockSz;

            ii = reshape(1:nShufChunk*ShufChunkSz,ShufChunkSz,nShufChunk);
            nidx = ii(:,params.collapseVal.seq);
            nidx = nidx(:);
            tmpPredN = zeros(size(data.val,1),length(ChIdx));
            for iG = 1:nShufChunk*ShufChunkSz;
                tmpPredN(iG,:) = mean(tmpPred(nidx==iG,:));
            end
            Result.valPred(:,ChIdx) = tmpPredN;
            if params.saveFullPred
                Result.valPredFull(:,ChIdx) = tmpPred;
            end
            clear tmpPredN
        else
            Result.valPred(:,ChIdx) = tmpPred;
        end
        [Result.cc(ChIdx),Result.ccCI(:,ChIdx)]=ccMatrix(Result.valPred(:,ChIdx),data.val(:,ChIdx),1);
    end    
end

% Split up bias (DC) term and rest of weights
if params.addmean
    Result.dc = Result.weights(1,:);
    Result.weights = Result.weights(2:end,:);
end
% Keep voxel selection info from data set
if isfield(data,'mask')
    Result.mask = data.mask;
end
if isfield(data,'voxType')
    Result.voxType = data.voxType;
end