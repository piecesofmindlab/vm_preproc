addpath(genpath('/auto/k2/share/strflabGOLD'))
global globDat

%% load a 20x20x20000 natural movie
load /auto/k2/share/strflabGOLD/fakedata/mov.mat

%% let's only take a part of it so it's directly comparable to above
rawStim = single(mov(1:10,1:10,1:15000));

gparams = [.5 .5 0 5.5 0 .0909 .3 0]';
[gabor, gabor90] = make3dgabor([10 10 5], gparams);
gabor = reshape(gabor, [10*10 5]);
gabor90 = reshape(gabor90, [10*10 5]);
rawStim = reshape(rawStim, [10*10 15000]);
resp = dotdelay(gabor, rawStim);
resp90 = dotdelay(gabor90, rawStim);
resp = sqrt(resp.^2 + resp90.^2);
resp = [zeros([4 1]); resp(1:end-4)];

%% Since it is possible to have more than one spike per frame, let's try
%% a little more information preserving threshhold, with a high threshhold 
%% for 2 spikes and a little bit lower threshhold for 1 spike
resp(resp<150) = 0;
resp(resp>=300) = 2;
resp(resp>=150) = 1;

%% To model a complex cell we turn on RTC in addition to RTA
params = preprocRTAC;
params.RTAC = [0 1];
params.locality = 2;
params.covtime = 0;

%% Make sure rawStim is the proper size before sending to preprocessing
rawStim = reshape(rawStim, [10 10 15000]);
[stim,params] = preprocRTAC(rawStim, params);
strfData(stim,resp)

%% Create new strf
strf = linInit(size(stim,2), [0:8]);
strf.b1 = mean(resp);
strf.params = params;

%% set the options to defaults for trnGradDesc
options = trnSCG;

%% turn on early stopping
options.earlyStop = 1;
options.maxIter=200;
options.threshold =.4;
%% graphically display every iteration
options.display = -1;

%% don't truncate first steps
options.nDispTruncate = 0;

%% In practice the step size for trnGradDesc may need to be tuned for 
%% each case. To do so just set a step size to something small enough 
%% error doesn't occilate on the training set with each step and doesn't
%% occilate too much on the early stopping set
options.stepSize = 2e-03;

%% Use 80% of the data for the training set
trainingIdx = [1:floor(.8*globDat.nSample)];

%% Use the remaining 20% for the stopping set
stoppingIdx = [floor(.8*globDat.nSample)+1:globDat.nSample];

%% Train and viusalize the STRF
strfTrained2=strfOpt(strf,trainingIdx,options,stoppingIdx);
preprocRTAC_vis(strfTrained2);
