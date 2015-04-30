function [strfArray, optionArray, cvResult]=resampEarlyStops(strf,stim,resp,options)
%function [strfArray,optionArray, cvResult]=resampEarlyStops(strf,stim,resp,options)
%
% Resample the data with replacement and compute model STRF parameters for
% each set of resampled data.
%
% INPUT:
%     [strf] = model structure obtained via upper level *Init functions
%     [stim] = NxD matrix, N=sample size, D=dimensions.
%     [resp] = Nx1 vector, N=sample size.
%  [options] = option structure containing fields:
%  .funcName = char array, name of this function.
%     .nFold = # of even splits of the data into smaller subsets. Each time
%              1 of the subset is used as test data and trained on the rest.
%              The prediction is generated from these test data.
% .randomize = boolean, Default=1=randomize the order of the samples first
%              before splitting it n-fold. 0=Keep the original data order.
%  .randSeed = random seed used to initialize the state of rand.
%  .optimAlg = name of low level optimization algorithm to use for fitting
%              the data.
%  .optimOpt = options required by the specified optimization algorithm.
%  .groupIdx = Nx1 vector of integer, specify which group the [stim] samples
%              belongs. If it is empty, each sample is its own group.
%
% OUTPUT:
% [strfArray] = structure array of structure containing [options.nBoot] 
%               fitted models.
%  [cvResult] = structure array of CV results containing fields:
%       .pred = model predicted response from each set of test data.
%       .true = true measure response in the test data.
%    .testIdx = index of test data samples.
%
% SEE ALSO: resampJackknife, resampBootstrap
%
% By Michael Wu  --  waftingpetal@yahoo.com (Jul 2007)
%
% ====================


% Set default option values
% --------------------
optDeflt.funcName='resampEarlyStops';
optRange.funcName={'resampEarlyStops'};
optDeflt.nFold=5;
optRange.nFold=[1,1e4];
optDeflt.randomize=1;
optRange.randomize=[0,1];
optDeflt.randSeed=123456;
optRange.randSeed=[0,1e16];

optDeflt.nResampIter=5;
optRange.nResampIter=[1,1e4];

optDeflt.groupIdx=[];
%optRange.groupIdx=[1,1e4];


optDeflt.optimAlg='trnGradDesc';
optRange.optimAlg={'trnGradDesc','trnSCG','trnDirectFit', ...
  'trnBoosting','trnSimAnneal','trnQuadProg'};
optDeflt.optimOpt=feval(optDeflt.optimAlg);

if nargin<4
  options=optDeflt;
else
  options=defaultOpt(options,optDeflt,optRange);
end

if nargin<1
  strfArray=optDeflt;
  return;
end


% Get sample size & parameter vector
% --------------------
stimSiz=size(stim);
respSiz=length(resp);
sampSiz=intersect(stimSiz,respSiz);


% Initial resampling computation & get model parameters
% --------------------
sampIdx=1:sampSiz;
if ~isempty(options.groupIdx)
  gIdx=unique(options.groupIdx);
  nGroup=length(gIdx);
else
  gIdx=sampIdx;
  nGroup=sampSiz;
end

gTrainLen=repmat(floor(nGroup/options.nFold),options.nFold,1);
gRemSamp=nGroup-gTrainLen(1)*options.nFold;
gTrainLen(1:gRemSamp,:)=gTrainLen(1:gRemSamp,:)+1;
cumLen=cumsum(gTrainLen);
gInterv=[cumLen-gTrainLen+1,cumLen];

if options.randomize
  rand('state',options.randSeed);
  rsIdx=randperm(nGroup);
else
  rsIdx=gIdx;
end


% Compute models & prediction over nFold split of data
% --------------------
for ii=1:options.nResampIter
  disp(sprintf('----- Cross Validation %d/%d (%d Fold)',ii, options.nResampIter, options.nFold));
  gTrainIdx=rsIdx;
  testIdx=findIdx(rsIdx(gInterv(ii,1):gInterv(ii,2)),gIdx);
  gTrainIdx(gInterv(ii,1):gInterv(ii,2))=[];
  trainIdx=findIdx(gTrainIdx,gIdx);

  [strfArray(ii) optionArray(ii)] =feval(options.optimAlg,strf,stim(trainIdx,:),resp(trainIdx,:), ...
    options.optimOpt,stim(testIdx,:),resp(testIdx,:));

  % Store results: true & predicted response, and samples index of test data
  cvResult(ii).pred=feval([strf.type,'Fwd'],strfArray(ii),stim(testIdx,:));
  cvResult(ii).true=resp(testIdx,:);
  cvResult(ii).testIdx=testIdx;
end


