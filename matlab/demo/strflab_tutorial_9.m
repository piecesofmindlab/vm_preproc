%% Auditory example
addpath(genpath('/auto/k2/share/strflabGOLD'))
global globDat
%% specify where wav files and spike files are
base_dir = '/auto/k2/share/strflabGOLD/fakedata/auditory/';

%% use default parameters for the short-time Fourier transform preprocessing
params = preprocSTFT;

%% concatinate the preprocessed stimuli and responses from each stimulus into matrices and
%% keep track of indicies of each stimulus using the assign vector
allstim = [];
allspike = [];
assign = [];
for ii = 1:20
    ii
    [rawStim, fs] = wavread([base_dir, 'stim', num2str(ii), '.wav']);
    params.fs = fs;
    [stim, params] = preprocSTFT(rawStim, params);
    allstim = [allstim; stim];
    
     [spike_time, num_trials] = preprocSpikeTime([base_dir, 'spike', num2str(ii)],size(stim,1));
     allspike = [allspike spike_time];
     assign = [assign ii*ones([1 size(stim,1)])];
end

%% take mean spike rate across all trials
allspike = mean(allspike,1);

global globDat;  % Must declare the global variable globDat in all functions that will access stim and resp.

%% Put stimulus and response and group assignments into globDat
strfData(allstim,allspike,assign);

%% Exclude data from the 12th stimulus from training
datIdx =find(assign ~=12);

%% Set options for gradient descent
options=trnGradDesc;
options.display=-1;
options.coorDesc=0;
options.earlyStop=1;
options.stepSize = .00005;
options.nDispTruncate = 0;

%% Initialize strf with up to 40 delays because we are using very small time bins
strf=linInit(size(allstim,2),[0:40]);

%% set the bias term to the mean firing rate
strf.b1 = mean(globDat.resp(datIdx));

%% Use 80% of the data for training
trainingIdx = [1:floor(.8*size(datIdx,2))];

%% Use the remaining 20% for the stopping set
stoppingIdx = [floor(.8*size(datIdx,2))+1:size(datIdx,2)];

%% train the strf
[strfTrained,options]=strfOpt(strf,datIdx(trainingIdx),options, datIdx(stoppingIdx));

%% try prediction using the held out 12th stimulus
datIdxPred =find(assign ==12);
[strfTrained,predResp]=strfFwd(strfTrained,datIdxPred);
sp = allspike(datIdxPred);
corr(sp',predResp)
figure;
plot(sp'); hold on; plot(predResp, 'r')

%% the weights are basically a spectrogram so lets look at them
figure; imagesc(squeeze(strfTrained.w1))


%% Let's trying fitting this STRF with a new (and somewhat experimental) fitting routine
%% trnPF is a algorith that lets you choose an arbitrary Tikhonov regularization matrix, and 
%% decreases the strength of the prior until the STRF's ability to generalize to a stopping
%% set gets worse
options = trnPF;
options.display=-1;
options.maxIter = 1000;
options.lamdaInit = 20000000;

%% We're going to specify a smooth prior the size of our weights so that weights change
%% smoothly in time and space
options.A = full(getSmoothnessPrior([size(squeeze(strf.w1)) 1], [1 1 0]));

%% the last term in the matrix would be for the bias term, but the bias should not be smooth
%% with respect to the other parameters so we set this to 0
options.A(end+1,end+1) = 0;

%% Train and viusalize the STRF
strfTrained=strfOpt(strf,trainingIdx,options,stoppingIdx);


%% try prediction using the held out 12th stimulus
datIdxPred =find(assign ==12);
[strfTrained,predResp]=strfFwd(strfTrained,datIdxPred);
sp = allspike(datIdxPred);
corr(sp',predResp)
figure;
plot(sp'); hold on; plot(predResp, 'r')

%% the weights are basically a spectrogram so lets look at them
figure; imagesc(squeeze(strfTrained.w1))
