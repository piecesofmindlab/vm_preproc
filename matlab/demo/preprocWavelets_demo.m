% preprocWavelets_grid demo

imdir = '/Users/mark/Pictures/Stimulus_Images/BVP/BVP_Ses1_Val/Scenes/'; %'/path/to/images/';
fmt = 'png';
% Images just have to be at least 2x (preferably 3x) the maximum spatial
% frequncy of Gabor wavelet that is specified in the parameter struct
% (due to the Nyquist limit). Any bigger is needless, and will produce the
% same answer but will be much more expensive in memory used. Also, it's
% easiest if images are square.
sz = [128,128]; 


%% Get images to process

imlist = dir(fullfile(imdir,['*' fmt]));
imlist = fullfile(imdir,{imlist.name}');
imlist = imlist(2:101); % Delete me
im = zeros([sz,3,length(imlist)]);
disp('Loading images...')
for iIm = length(imlist)
    [imtmp,~,~] = imread(imlist{iIm});
    im(:,:,:,iIm) = imresize(imtmp,sz);
end

%% Color space preprocessing
% For all preprocessing functions, enumerated pre-set parameter sets are
% stored in <preprocFunctionName>_getMetaParams.m The meanings of each
% parameter in the params struct are given in the help for the
% preprocessing function. 
% Pre-set 1 for preprocColorSpace changes images from RGB to luminance.
cparams = preprocColorSpace_GetMetaParams(1);
[Spp,cparams] = preprocColorSpace(im,cparams);

%% Gabor wavelet preprocessing
% Shinji's main set of parameters for
gparams = preprocWavelets_grid_GetMetaParams(2);
[Spp,gparams] = preprocWavelets_grid(Spp,gparams);

%% Compressive nonlinearity (log)
nlparams = preprocNonLinearOut_GetMetaParams(1);
[Spp,nlparams] = preprocNonLinearOut(Spp,nlparams);

%% Downsample to TR 
dsparams = preprocDownsample_GetMetaParams(1);
[Spp,dsparams] = preprocDownsample(Spp,dsparams);

%% Normalize (Zscore by channel)
zparams = preprocNormalize_GetMetaParams(3);
[Spp,zparams] = preprocNormalize(Spp,zparams);
% Spp now should be [n_TRs x n_GaborChannels] n_GaborChannels is 6,555 for
% this parameter set, but that will vary as you tweak the Gabor wavelet
% model. This is the feature space you will use to model fMRI data. 

%% The short way
% (This may not work without the full functionality of my database system
% (which requires some other code). I have been meaning to clean this up a
% little; haven't yet. 
%S = Stimulus(im); % These can also be loaded from a database
%[Spp,params] = preprocPipeline(S,{'preprocColorSpace',1,'preprocWavelets_grid',2,'preprocNonLinearOut',1,'preprocDownsample',1,'preprocNormalize',3});

% Context for Gabor model:
%% make a single Gabor
channel = 122; % Pick a random channel out of all 6,555 possible channels
[g1,g2] = make3dgabor([128,128,10],gparams.gaborparams(channel,:));
% The two wavelets returned will be in quadrature phase (they will have a 90º phase offset)
%% Make ALL the Gabor filters used for a given model:
gparams.show_or_preprocess = 0;
[gabors,~] = preprocWavelets_grid(ones(128,128,10),gparams);
% Result will be X x Y x Time x gabor channel