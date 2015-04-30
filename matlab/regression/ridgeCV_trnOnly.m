function Result = ridgeCV_trnOnly(data,model,params)
% Usage: Result = ridgeCV_trnOnly(data,model,params)
% 
% Computes ridge regression on a single dataset by cross-validation splits
% (intended for use in the training data only, to avoid over-fitting to a
% withheld validation data set). A wrapper for ridgeCV.m
% 
% Inputs: 
% 
% "data", "model" are the same as inputs ridgeCV (only data.trn and
% model.trn will be used; data.val and model.val will be ignored, if
% present). 
% "params" is a struct, w/ fields:
%   .nPartitions = # of partitions over which to compute 
%   .nResamps = # of resamplings to
%   .
%   .PP = "params" input to ridgeCV
% NOTE: If params.keepWeights is set to true, this can be demanding on
% memory! You better be doing voxel selection & not running whole brains...
% ML 2012.05.04

DefaultParams.nResamps = 10; % number of times to run cross-validation for lambdas
DefaultParams.nPartitions = 10; % determines size of train/validate chunks for Cross-validation. 10 = 90% train / 10% val
DefaultParams.keepWeights = false;
if exist('params','var')
    params = defaultOpt(params,DefaultParams);
else
    params = DefaultParams;
end

% Split data into "nPartitions" splits
% last argument is a dimension index (which dimension of matrix to partition)
%[partDat partIdx] = randPartition(data.trn,params.nPartitions,1); 
%[partDat partIdx] = contigPartition(data.trn,params.nPartitions,1); 
[TrnIdx,ValIdx] = contigPartition_Buffer(data.trn,params.nPartitions,5,1); 

% NOTE! it is critical that for movie experiments, the partitions be
% contiguous, and not randomly interleaved - the data are not independent
% from time point to time point!
% Preallocate for later concatenation of results:
if params.keepWeights
    WtAll = zeros(size(data.trn,2),size(model.trn,2),params.nResamps);
end
ccAll = zeros(size(data.trn,2),params.nResamps);
lambdaAll = [];
nSigVox_byLambda_All = [];
% Loop over splits (Parallelize??)
tic;
for iRS = 1:params.nResamps
    fprintf('Running resample split %d of %d...\n',iRS,params.nResamps);
    toc;
    % Split indices
    %trIdx = ~ismember(1:params.nPartitions,iRS);
    %trainIdx = [partIdx{trIdx}]';
    %valIdx = partIdx{iRS}';
    trainIdx = TrnIdx{iRS}';
    valIdx = ValIdx{iRS}';
    % Split Model
    modelIn.trn = model.trn(trainIdx,:);
    modelIn.val = model.trn(valIdx,:);
    % Split Data
    %dataIn.trn = cat(1,partDat{trIdx});
    dataIn.trn = data.trn(trainIdx,:);
    %dataIn.val = partDat{iRS};
    dataIn.val = data.trn(valIdx,:);
    dataIn.mask = data.mask;
    dataIn.voxType = data.voxType;
    if isfield(params,'PP')
        Result = ridgeCV(dataIn,modelIn,params.PP);
    else
        Result = ridgeCV(dataIn,modelIn);
    end
    % Save data for next split
    if params.keepWeights
        WtAll(:,:,iRS) = Result.weights;
    end
    ccAll(:,iRS) = Result.cc;
    lambdaAll = [lambdaAll;Result.lambda];
    nSigVox_byLambda_All = [nSigVox_byLambda_All;Result.nSigVox_byLambda];
end
% Store data
Result.nResamps = params.nResamps;
Result.cc = mean(ccAll,2);
Result.nSigVox_byLambda = nSigVox_byLambda_All;
Result.lambda = lambdaAll;
if params.keepWeights
    Result.weights = mean(WtAll,3);
end
% All done! 