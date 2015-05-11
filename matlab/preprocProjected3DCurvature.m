function varargout = preprocProjected3DCurvature(S,params)
% Usage: [Spreproc,params] = preprocProjected3DCurvature(S,params)
%
% Preprocess the "Projected Curvature", i.e. the curvature of the depth map
% treated as a surface. This treats the depth map as if it were a sheet
% draped over the objects the camera can see, and computes the curvature of
% that sheet.
%
% Inputs:
%   S = Z depth map per frame (X x Y x nFrames), or string specifying
%       file(s) to load. (see note below on depth of skies)
%   params = a struct array, with fields:
%       .
%       .
%       .
%   ...
% Outputs:
%   Spreproc = preprocessed stimulus
%   params = param struct array (possibly with modifications)
%
% ** NOTE ON SKIES **
%   Skies should be preprocessed (i.e., removed) before calling this
%   function! Meaning, if the skies are of infinite depth, or if they have
%   variable depth (if, for example, you used a sky dome to paint
%   clouds/sky into the scene), the depth of the sky should be set
%   uniformly to ~1.1x the furthest non-sky distance in the scene (this is
%   a hack, but works just fine for the purposes of this function).
%
% NOTE 2: Does NOT support specification of centers / boundaries of
% orientation bins, only number of bins (i.e., 4 bins = [0,45,90,135], 8 =
% 0,22.5,45,...,167.5], etc.
%
% ML 2012.11


% The informative dimensions of curvature ARE its orientation (wrt you), in
% some sense. We could normalize this orientation wrt. other frames of
% reference, e.g.
% - the principal axis of the object
% - gravity (in many cases, we are looking DOWN at the scene)
% -

% TO DO: set up range for all default parameters.
% Inputs
% For computing curvature - how to subdivide curvature "energy"
pDefault.class = 'preprocProjected3DCurvature';
pDefault.separateCurvDir = true;
pDefault.combineCurvDirMethod1 = 'absMax'; % At start
rDefault.combineCurvDirMethod1 = {'absMax'};
pDefault.combineCurvDirMethod2 = 'none';  % At end
rDefault.combineCurvDirMethod2 = {'none'};
pDefault.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
pDefault.useAbsCurvature = false;
pDefault.binCurvature = false;
pDefault.binCenters = []; % For now: Gaussian bins.
pDefault.binStds = []; %
% Curvature squashing (only one option)
pDefault.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
pDefault.curvSquashFn = 'squashNcdf'; % Default is to squash with normal cumulative distribution function (gaussian sigmoid)
rDefault.curvSquashFn = {'squashNcdf'}; % Don't vary this... works fine
% For orientation bins
pDefault.nOriBins = 4; % number of orientation bins
rDefault.nOriBins = [1 9]; % more than 9 is just silly.
pDefault.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
rDefault.oMax = [180,180];
% For spatial bins
pDefault.nSpatBins = 17; % number of spatial bins across image (square grid)
pDefault.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
pDefault.pxPerBin = 15; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
pDefault.histWtScale = nan; % computed to be neutral (no effect) (?)
pDefault.Use_Gaussian_Bins = false; % (vs. flat coding of space)
pDefault.resizeZim = false; % Whether or not to resize
% For normalization
pDefault.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
pDefault.PC_NORM_MAXVAL = nan;% 0.2; % max value at which to clip PC energy (MODIFY??)
pDefault.PC_NORM_EPS = nan; %1.0; % regularization factor 1; multiplier for
%# of PC channels. (multiplier for # of norm bins?)
pDefault.PC_NORM_EPS2 = nan; %0.01; % regularization factor 2 (Eta). D&L say this doesn't
%matter much - results hold for a range of values of this Eta value
% Computed below:
% .oBinWidth
% .oBinCenters

% Get params, if input is a numeric code for pre-set parameters
if exist('params','var') && isnumeric(params)
    % if params are given in the form: [1,3];
    pp = params;
    params = preprocProjected3DCurvature_GetMetaParams(pp);
elseif ~exist('params','var')
    params = struct;
end
% Fill input / meta param struct with defaults
params = defaultOpt(params,pDefault,rDefault);

% Compute the rest of the parameters from params provided:
params = computeProjected3DCurvatureParams(params);
% Return params if no stimulus provided
if ~nargin
    varargout{1} = params;
    return
end
disp('Hey! Clean up the params.PCparams fields from computeGWEOWparams!')

SpBins = params.nSpatBins;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Preprocessing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over different segments of the stimulus matrix (for memory's sake), if necessary:
if ischar(S)
    fDir = fileparts(S);
    stimF = dir(S);
    Ss = mlAddToCell({stimF.name}',[fDir filesep],true);
    nParts = length(Ss);
elseif isnumeric(S)
    nParts = 1;
else
    error('WTF did you give me as a stimulus? I was expecting a string or a numeric matrix.')
end

Is_SkipPart1 = false;
if isfield(params,'fInfo')
    % fInfo is information particular to this parameter preset and this
    % particular run (Training / Validation, session #, pixels for images)
    sName = sprintf('%sProjCurv_%dpx_%s_Ses%d_%s_%02d.mat',params.fInfo.iDir,params.fInfo.nPixels,...
        params.fInfo.ImType,params.fInfo.Ses,params.fInfo.TrnVal,params.metaparams.preset(1));
    if exist(sName,'file')
        load(sName,'Spreproc') % Loads Spreproc variable
        Is_SkipPart1 = true;
    end
end
% Prep for pyramid PC computation:
if ~Is_SkipPart1
    SppAll = [];
    for iPart = 1:nParts
        if exist('Ss','var')
            load(Ss{iPart},'S');
        end
        % Get number of images
        if ndims(S)==4
            nIms = size(S,4);
        else %if ndims(S)==3
            nIms = size(S,3);
        end
        % Preallocate Spreproc
        Spreproc = nan(nIms,params.nChannels);
        for iS = 1:nIms
            if nIms>200
                progressdot(iS,200,2000,nIms)
                %progressdot(iS,10,200,nIms)
            elseif nIms < 200 && nIms > 1
                disp('computing Projected Curvature')
            end
            % Pull single image for preprocessing
            Z = S(:,:,iS);
            % Loop for (potential) spatial pyramid of Projected Curvature
            Spp = zeros(params.nChannels,1);
            for iSz = 1:length(SpBins)
                % Resize image to match desired spatial scale
                % (+2 to add 1 pixel to outside the bins closest to the image edge)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%  DO WE WANT TO RESIZE???  %%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if params.resizeZim
                    % Make resizing method a parameter? (bilinear,
                    % nearest, etc?)
                    Zr = imresize(Z,[SpBins(iSz)*params.pxPerBin+2,SpBins(iSz)*params.pxPerBin+2],'bilinear');
                else
                    % Do we need to do something about this if no
                    % resizing happens?
                    %keyboard;
                    Zr = Z;
                end
                params.nSpatBins = SpBins(iSz);
                if iSz == 1
                    idx = 1:params.nPCdims*SpBins(iSz)^2;
                else
                    disp('NOT SURE IF PYRAMID WORKS CORRECTLY! NEEDS TESTING!')
                    keyboard;
                    idx = (1:params.nPCdims*SpBins(iSz)^2) + sum(SpBins(1:(iSz-1)).^2)*params.nPCdims;
                end
                if iS==1
                    [Spp(idx),params] = compute_PC(Zr,params);
                else
                    Spp(idx) = compute_PC(Zr,params);
                end
            end
            Spreproc(iS,:) = Spp';
        end
        % Sub-optimal - This should be pre-allocated, but that's too
        % annoying for now, and this shouldn't be too slow (2012.04.20 ML)
        SppAll = [SppAll;Spreproc];
        clear S;
    end
    Spreproc = SppAll;
    params.nSpatBins = SpBins;
    if isfield(params,'fInfo')
        save(sName,'Spreproc','params','-v7.3');
    end
end

% All done!
% (Return Spreproc, save elsewhere)
varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end