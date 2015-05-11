function params = preprocProjected3DCurvature_GetMetaParams(Arg)
% Usage: params = preprocProjected3DCurvature_GetMetaParams(Arg)
% 
% Function to get parameter pre-sets for projected curvature preprocessing.
% Input "Arg" is a SCALAR numerical value, specifying a numerical
% option for ONE steps of preprocessing. (as of 2012.11, time preprocessing
% is all being moved to a separate function).
% 
%
% To save an intermediate file requires extra information that will be
% experiment-specific (e.g., whether the file is for training or validation
% runs, what type of image is being processed, what size the images were).
% This info can be appended to the params struct in a sub-struct
% ("params.fInfo"), outside of this function. (This function is meant to be
% general enough to use for any experiment / stimulus set). 
% 
% ML 2012.11.27

params = preprocProjected3DCurvature;
%params = rmfield(params,'PCparams');
params.metaparams.preset = Arg;
params.class = 'preprocProjected3DCurvature';
switch Arg(1)
    case 1
        % Default parameters:
        params.metaparams.Descr = 'No ori, abs curv, comb dir, no bins';
        params.metaparams.AxLabel = '1 ori, abs curv, 1 dir, no bins';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 1; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % HoG default = .01 regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 2
        % Default parameters:
        params.metaparams.Descr = 'base + rectify';
        params.metaparams.AxLabel = '1d x 1h x 1v x 9norms';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = true; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = false;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 1; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 3
        % Default parameters:
        params.metaparams.Descr = 'Base + bins';
        params.metaparams.AxLabel = 'base + 2 abs bins';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = true;
        params.binCenters = [.5,1]; % For now: Gaussian bins. 
        params.binStds = [.2,.2]; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 1; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 4
        % Default parameters:
        params.metaparams.Descr = 'base + 4 pos neg bins';
        params.metaparams.AxLabel = '1d x 1h x 1v x 9norms';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = false;
        params.binCurvature = true;
        params.binCenters = [-1,-.5,.5,1]; % For now: Gaussian bins. 
        params.binStds = [.2,.2,.2,.2]; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 1; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters

    case 5
        % Default parameters:
        params.metaparams.Descr = 'Base + 4 ori';
        params.metaparams.AxLabel = 'base + 4 ori';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 6
        % Default parameters:
        params.metaparams.Descr = 'Base + pos/neg rect + 4 ori';
        params.metaparams.AxLabel = 'base, +/- rect, 4 ori';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = true; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 7
        error('piss off! not done yet!')
    case 8
        error('piss off! not done yet!')
    case 9
        % Default parameters:
        params.metaparams.Descr = 'Base + 8 ori';
        params.metaparams.AxLabel = 'base + 8 ori';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 13
        % Default parameters:
        params.metaparams.Descr = 'Base + 17 sp bins';
        params.metaparams.AxLabel = 'base + 17 sp bins';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 1; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 17
        % Default parameters:
        params.metaparams.Descr = 'Base + 4 ori + 17 sp bins';
        params.metaparams.AxLabel = 'base + 4 ori + 17 sp bins';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 21
        % Default parameters:
        params.metaparams.Descr = 'Base + 8 ori + 17 sp bins';
        params.metaparams.AxLabel = 'base + 8 ori + 17 sp bins';
        params.separateCurvDir = false;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 8; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
        
    case 25
        % Default parameters:
        params.metaparams.Descr = 'Base + 2 curv dirs';
        params.metaparams.AxLabel = 'base + 2 curv dirs';
        params.separateCurvDir = true;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 1; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters
    case 29
        % Default parameters:
        params.metaparams.Descr = 'Base + 2 curv dirs + 4 ori';
        params.metaparams.AxLabel = 'base + 2 curv dirs + 4 ori';
        params.separateCurvDir = true;
        params.combineCurvDirMethod1 = 'absMax'; % At start
        params.combineCurvDirMethod2 = 'none';  % At end
        params.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
        params.useAbsCurvature = true;
        params.binCurvature = false;
        params.binCenters = []; % For now: Gaussian bins. 
        params.binStds = []; % 
        % Curvature squashing (only one option)
        params.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
        params.curvSquashFn = 'squashNcdf'; % This is the only option: squash with normal cumulative distribution function (gaussian sigmoid)
        % For orientation bins
        params.nOriBins = 4; % number of orientation bins
        params.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
        % For spatial bins
        params.nSpatBins = 13; % number of spatial bins across image (square grid)
        params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
        params.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
        params.histWtScale = nan; % computed to be neutral (no effect) (?)
        params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
        params.resizeZim = false; % Whether or not to resize
        % For normalization
        params.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
        params.PC_NORM_MAXVAL = nan; % max value at which to clip PC energy (MODIFY??)
        params.PC_NORM_EPS = nan; % regularization factor 1; multiplier for
        %# of PC channels. (multiplier for # of norm bins?)
        params.PC_NORM_EPS2 = nan; % regularization factor 2 (Eta). D&L say this doesn't
        %matter much - results hold for a range of values of this Eta value
        % Computed below:
        % .oBinWidth
        % .oBinCenters

end

% Fill out struct array with the rest of the (computed) params:
params = computeProjected3DCurvatureParams(params);
