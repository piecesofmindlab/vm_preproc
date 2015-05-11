function params = preprocHoN_GetMetaParams(Arg)
% Usage: params = preprocHoN_GetMetaParams(Arg)
% 
% Function to get parameter pre-sets for HoN preprocessing. Input "Arg" is
% a two-element numerical vector, specifying a numerical option for 
% two steps of preprocessing. 
% 
% Step 1 is everything to do with Histogram of Gradient (HoN) processing
% (size of bins in image and angle space, normalization, etc)
% 
% Step 2 is everything after (having to do with collapsing values over
% time). These are specified separately because step 1 takes 
% considerably longer than step2. An intermediate file is stored after 
% completion of step 1 to save computational time for step2 variants. 
% 
% ML 2012.01.04

params = preprocHoN;
params.metaparams.preset = Arg;
params.metaparams.descr = cell(2,1);
% First-stage processing presets
switch Arg(1)
    case 1
        % Default parameters:
        params.metaparams.Descr = '9x9 grid: 9 basis normals, no pyramid';
        params.metaparams.AxLabel = '9x9pos, 9 bases';
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
            -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
            0,0,1]; % straight-ahead
        params.Is_2D = false; % Whether to flatten all normals into the image plane
        %%% Spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        %%% Normalization parameters
        params.HON_NORM_MAXVAL = 0.2; % max value at which to clip HoN energy (Taken from HoG code - update??)
        params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
        %number of HoG channels. Not explored thoroughly as of 2012.04.11
        params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to prevent division by 0?
    case 2
        params.metaparams.descr1 = '17x17 grid: 9 basis normals, no pyramid';
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
            -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
            0,0,1]; % straight-ahead
        params.Is_2D = false; % Whether to flatten all normals into the image plane
        %%% Spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        %%% Normalization parameters
        params.HON_NORM_MAXVAL = 0.2; % max value at which to clip HoN energy (Taken from HoG code - update??)
        params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
        %number of HoG channels. Not explored thoroughly as of 2012.04.11
        params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to prevent division by 0?
    case 3
        params.metaparams.descr1 = '17x17 grid: 5 basis normals, no pyramid';
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
            0,0,1]; % straight-ahead
        params.Is_2D = false; % Whether to flatten all normals into the image plane
        %%% Spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        %%% Normalization parameters
        params.HON_NORM_MAXVAL = 0.2; % max value at which to clip HoN energy (Taken from HoG code - update??)
        params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
        %number of HoG channels. Not explored thoroughly as of 2012.04.11
        params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to prevent division by 0?

    case 4
        params.metaparams.descr1 = '9x9 grid: 9 basis normals, no pyramid + no cap on normal bins';
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
            -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
            0,0,1]; % straight-ahead
        params.Is_2D = false; % Whether to flatten all normals into the image plane
        %%% Spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        %%% Normalization parameters
        params.HON_NORM_MAXVAL = Inf; % max value at which to clip HoN energy (Taken from HoG code - update??)
        params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
        %number of HoG channels. Not explored thoroughly as of 2012.04.11
        params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to prevent division by 0?
    case 5
        params.metaparams.descr1 = '3x3 grid: 9 basis normals, no pyramid + no cap on normal bins';
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
            -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
            0,0,1]; % straight-ahead
        params.Is_2D = false; % Whether to flatten all normals into the image plane
        %%% Spatial bins
        params.nSpatBins = 3; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        %%% Normalization parameters
        params.HON_NORM_MAXVAL = Inf; % max value at which to clip HoN energy (Taken from HoG code - update??)
        params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
        %number of HoG channels. Not explored thoroughly as of 2012.04.11
        params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to prevent division by 0?
    %%% --- Starting here - absolute normals! --- %%%
    case 11
        error('Lame!')
        
end

% Second-stage preprocessing
switch Arg(2)
    case 1
        % No temporal dimensions!
        params.metaparams.descr2 = 'No temporal freq; no collapsing over TRs; 1tf (0)';
        % Temporal frequency channels
        params.tsize = 1; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 0; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 1; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
        params.nFramesPerTR = 1;
    case 2
        % No temporal dimensions, 
        params.metaparams.descr2 = 'No temporal freq; DO collapse over TRs; 1tf (0)';
        % Temporal frequency channels
        params.tsize = 1; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 0; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 1; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
        params.nFramesPerTR = 30;
    case 3
        params.metaparams.descr2 = 'Standard: 10-frame (~600 ms) temporal window w/3 tf chans incl 0'; 
        % Temporal frequency channels
        params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 2.6666667; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 1.3333333; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
        params.nFramesPerTR = 30;
    case 4
        params.metaparams.descr2 = 'Standard: 10-frame (~600 ms) temporal window w/2 tf chans incl 0'; 
        % Temporal frequency channels
        params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 2.6666667; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 2; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
        params.nFramesPerTR = 30;
    otherwise
        error('Unknown parameter configuration!');
end