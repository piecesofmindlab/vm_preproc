function params = preprocHoG_GetMetaParams(Arg)
% Usage: params = preprocHoG_GetMetaParams(Arg)
% 
% Function to get parameter pre-sets for HoG preprocessing. Input "Arg" is
% a numerical index to a particular set of HoG parameters (size of bins in
% image and angle space, normalization, etc) 
% 
% To save an intermediate file requires extra information that will be
% experiment-specific (e.g., whether the file is for training or validation
% runs, what type of image is being processed, what size the images were).
% This info can be appended to the params struct in a sub-struct
% ("params.fInfo"), outside of this function. (This function is meant to be
% general enough to use for any experiment / stimulus set). 
% 
% ML 2012.01.04
% Updated 2013.03.19

params = preprocHoG;
params = rmfield(params,'HoGparams');
params.metaparams.preset = Arg;
% First-stage processing presets
switch Arg
    case 1
        params.metaparams.AxLabel = '9x9pos, 4ang, 180max';
        params.metaparams.Descr = 'Standard: 9x9 grid, 4 angles, 180, no pyramid';
        params.metaparams.descr1 = 'Standard: 9x9 grid, 4 angles, 180, no pyramid';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
        
    case 2
        params.metaparams.descr1 = 'More spatial bins: 17x17 grid, 4 angles, 180 max, no pyramid';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 3
        params.metaparams.descr1 = 'Standard + more ori: 9x9 grid, 6 angles, 180 max, no pyramid';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        %  keyboard;
    case 4
        params.metaparams.descr1 = '9x9 grid, 8 angles, 360 max, no pyramid';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = [9]; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
    case 5
        params.metaparams.descr1 = 'Standard pyramid: 17x17,9x9,5x5 grid, 4 angles, 180 max';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = [17,9,5]; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
    case 6
        params.metaparams.descr1 = 'Standard: 9x9 grid, 4 angles, 180, no pyramid, HOG_NORM_MAXVAL = .3';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.3; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 7
        params.metaparams.descr1 = 'Standard: 9x9 grid, 4 angles, 180, no pyramid, HOG_NORM_MAXVAL = .5';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.5; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 8
        params.metaparams.descr1 = 'Standard: 9x9 grid, 4 angles, 180, no pyramid, HOG_NORM_MAXVAL = 1';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 1; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 9
        params.metaparams.descr1 = 'Standard: 9x9 grid, 4 angles, 180, no pyramid, no normalization';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = nan; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = nan; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = nan; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 10
        params.metaparams.descr1 = '13x13 grid, 4 angles, 180, no pyramid';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 11
        params.metaparams.descr1 = '9x9 grid, 8 angles, 180 max, no pyramid';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
    case 12
        params.metaparams.descr1 = '17x17 grid, 4ang, 180deg, EPS2 = .1';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = .2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = .1; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 13
        params.metaparams.Descr = '17x17 grid, 4ang, 180deg, CenterSurround';
        params.metaparams.AxLabel = '17x17pos, 4ang 180deg, C-S norm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = .2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = .01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 14
        params.metaparams.Descr = '17x17 grid, 4ang, 180deg, Corner Norm';
        params.metaparams.AxLabel = '17x17pos, 4ang 180deg, Asym norm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'Corners',9};
        params.HOG_NORM_MAXVAL = .2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = .01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 15
        params.metaparams.Descr = '9x9 grid, 4ang, 180deg, CenterSurround';
        params.metaparams.AxLabel = '9x9pos, 4ang 180deg, C-S norm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = .2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = .01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
    case 16
        params.metaparams.Descr = '9x9 grid, 4ang, 180deg, Corner Norm';
        params.metaparams.AxLabel = '9x9pos, 4ang 180deg, Asym norm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'Corners',9};
        params.HOG_NORM_MAXVAL = .2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = .01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 

    case 17
        params.metaparams.Descr = ': 17x17,9x9,5x5 grid, 4 angles, 180 max';
        params.metaparams.AxLabel = '17,9,5pyr 4ang 180deg C-Snorm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = [17,9,5]; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
    case 18
        params.metaparams.Descr = ': 15x15,9x9 grid, 4 angles, 180 max';
        params.metaparams.AxLabel = '15,9pyr 4ang, 180deg, CSnorm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = [15,9]; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
    case 19
        params.metaparams.Descr = ': 15x15 grid, 4 angles, 180 max, CS norm';
        params.metaparams.AxLabel = '15x15pos, 4ang, 180deg, CSnorm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = [15]; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
    case 20
        params.metaparams.Descr = ': 15x15,9x9 grid, 8 angles, 180 max';
        params.metaparams.AxLabel = '15,9pyr 8ang, 180deg, CSnorm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = [15,9]; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4

    case 21
        params.metaparams.Descr = ': 15x15 grid, 8 angles, 180 max';
        params.metaparams.AxLabel = '15x15pos, 8ang, 180deg, CSnorm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = [15]; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4

    case 22
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 7; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 23
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 11; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 24
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 15; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 25
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 19; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 26
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 21; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 27
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 25; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 28
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 7; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 29
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 11; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 30
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 31
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 15; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 32
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 33
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 19; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 34
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 21; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 35
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 25; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 36
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 7; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 37
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 11; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 38
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 39
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 15; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 40
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 41
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 19; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 42
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 21; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 43
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 25; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 44
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 7; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 45
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 46
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 11; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 47
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 48
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 15; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 49
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 50
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 19; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 51
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 21; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 52
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 6; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 25; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 53
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 7; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 54
                % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 11; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 55
                % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 56
                % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 15; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 57
                % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 58 
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 19; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 59
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 21; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 60
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 360; % 180 or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 25; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HoG_Norm_Area = []; % {'CenterSurround',9};
        params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03     case 4
        params.metaparams.Descr = sprintf(': %dx%d grid, %d angles, %d max',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
        params.metaparams.AxLabel = sprintf('%dx%dpos, %dang, %ddeg, %dmax',...
            params.nSpatBins,params.nSpatBins,params.nOriBins,params.oMax);
    case 61
        params.metaparams.descr1 = 'More spatial bins: 17x17 grid, 4 angles, 180 max, no pyramid, no norm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = nan; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = nan; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = nan; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 

    case 62
        params.metaparams.descr1 = 'More spatial bins: 17x17 grid, 1 angles, 180 max, no pyramid, no norm';
        % For gradients
        params.gradParams.ChannelCollapseMethod = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
        % For orientation bins
        params.nOriBins = 1; % number of orientation bins
        params.oMax = 180; % or 360, for full-circle orientations
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
        params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        % For normalization
        params.HOG_NORM_MAXVAL = nan; % max value at which to clip HoG energy (Taken straight from Dalal & Triggs, 2005)
        params.HOG_NORM_EPS = nan; % regularization factor 1; multiplier for
          %number of HoG channels. Not explored thoroughly as of 2012.04.03
        params.HOG_NORM_EPS2 = nan; % regularization factor 2: added to
          %second normalization of HoG channels (See below) Not explored
          %thoroughly as of 2012.04.03 
                
        
    otherwise
        error('Unknown parameter configuration!');        
end

% % Second-stage preprocessing
% switch Arg(2)
%     case 1
%         if isfield(params.metaparams,'Descr')
%             params.metaparams.Descr = [params.metaparams.Descr, '\n No temporal preprocesssing (0TF, twindow = 1, no downsampling)'];
%         end
%         % No temporal dimensions!
%         params.metaparams.descr2 = 'No temporal freq; no collapsing over TRs; 1tf (0)';
%         % Temporal frequency channels
%         params.tsize = 1; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
%         params.tfmax = 0; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
%         params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
%         params.tfdivisions = 1; % number of tf channels, logarithmically spaced between min and max
%         params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
%         % etc
%         params.Is_Normalize = false;
%         params.nFramesPerTR = 1;
%         params.crop = [];
%     case 2
%         % No temporal dimensions, 
%         params.metaparams.descr2 = 'No temporal freq; DO collapse over TRs; 1tf (0)';
%         % Temporal frequency channels
%         params.tsize = 1; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
%         params.tfmax = 0; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
%         params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
%         params.tfdivisions = 1; % number of tf channels, logarithmically spaced between min and max
%         params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
%         params.nFramesPerTR = 30;
%         params.crop = [];
%     case 3
%         %keyboard;
%         if isfield(params.metaparams,'Descr')
%             params.metaparams.Descr = [params.metaparams.Descr, '\n Standard: 10-frame (~666 ms) temporal window w/3 tf chans incl 0']; 
%         end
%         if isfield(params.metaparams,'AxLabel')
%             params.metaparams.AxLabel = [params.metaparams.AxLabel, '\n3tf']; 
%         end
%         %params.metaparams.descr2 = 'Standard: 10-frame (~600 ms) temporal window w/3 tf chans incl 0'; 
%         % Temporal frequency channels
%         params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
%         params.tfmax = 2.6666667; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
%         params.tfmin = 1.3333333; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
%         params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
%         params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
%         params.nFramesPerTR = 30;
%         params.crop = [];
%     case 4
%         %keyboard;
%         if isfield(params.metaparams,'Descr')
%             params.metaparams.Descr = [params.metaparams.Descr, '\n 10-frame (~666 ms) temporal window w/3 tf chans @0,1,2hz']; 
%         end
%         if isfield(params.metaparams,'AxLabel')
%             params.metaparams.AxLabel = [params.metaparams.AxLabel, '\n3tf 0-1-2hz']; 
%         end
%         %params.metaparams.descr2 = 'Standard: 10-frame (~600 ms) temporal window w/3 tf chans incl 0'; 
%         % Temporal frequency channels
%         params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
%         params.tfmax = 1.3333333; % maximum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
%         params.tfmin = .6666666; % minimum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
%         params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
%         params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
%         params.nFramesPerTR = 30;
%         params.crop = [];
%     case 5
%         %keyboard;
%         if isfield(params.metaparams,'Descr')
%             params.metaparams.Descr = [params.metaparams.Descr, '\n 10-frame (~666 ms) temporal window w/2 tf chans @0,2hz']; 
%         end
%         if isfield(params.metaparams,'AxLabel')
%             params.metaparams.AxLabel = [params.metaparams.AxLabel, '\n2tf 0-2hz']; 
%         end
%         %params.metaparams.descr2 = 'Standard: 10-frame (~600 ms) temporal window w/3 tf chans incl 0'; 
%         % Temporal frequency channels
%         params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
%         params.tfmax = 1.3333333; % maximum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
%         params.tfmin = 1.3333333; % minimum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
%         params.tfdivisions = 2; % number of tf channels, logarithmically spaced between min and max
%         params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
%         params.nFramesPerTR = 30;
%         params.crop = [];
%     case 6
%         if isfield(params.metaparams,'Descr')
%             params.metaparams.Descr = [params.metaparams.Descr, '\n 10-frame (~666 ms) temporal window w/2 tf chans @0,4hz']; 
%         end
%         if isfield(params.metaparams,'AxLabel')
%             params.metaparams.AxLabel = [params.metaparams.AxLabel, '\n2tf 0-4hz']; 
%         end
%         %params.metaparams.descr2 = 'Standard: 10-frame (~600 ms) temporal window w/3 tf chans incl 0'; 
%         % Temporal frequency channels
%         params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
%         params.tfmax = 2.666667; % maximum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
%         params.tfmin = 2.666667; % minimum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
%         params.tfdivisions = 2; % number of tf channels, logarithmically spaced between min and max
%         params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
%         params.nFramesPerTR = 30;
%         params.crop = [];
%         
%     otherwise
%         error('Unknown parameter configuration!');
% end
% Last: fill in descriptive info for each HoG channel:
params = computeHoGparams(params);
end

