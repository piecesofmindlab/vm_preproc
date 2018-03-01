function varargout = preprocHoG(S,pp)
% Usage: [Spreproc,params] = preprocHoG(S,params)
% 
% Preprocess stimulus with Histogram of Gradients model
% 
% S can be a string for a single file name, or a string with wildcard (*)
%   elements in it to specify multiple file names. 
% 
% pp is a struct array of parameters (see code / see
%   preprocHoG_GetMetaParams.m)
% 
% ML 2012.04.12

% For gradients
params.class = mfilename;
params.gradParams.ChannelCollapseMethod = 'max';
params.gradParams.IsSqrt = true;
params.gradParams.IsLAB = false;
% For orientation bins
params.nOriBins = 4; % number of orientation bins
params.oMax = 180; % or 360, for full-circle orientations
% For spatial bins
params.nSpatBins = 9; % number of spatial bins across image (square grid)
params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
params.pxPerBin = 5; % number of pixels per HoG bin (images are resized for computation as of 2012.05.03)
params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
params.Use_Gaussian_Bins = true; % (vs. flat coding of space)
% For spatial normalization
params.HoG_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize 
                           % HoG channels (arguments fed to getSurroundIndices.m)
params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (MODIFY??)
params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for # of 
                           % HoG channels. (multiplier for # of norm bins?)
params.HOG_NORM_EPS2 = 0.01; % regularization factor 2 (Eta): added to
  % second normalization of HoG channels (See below) D&T say this doesn't
  % matter much - results hold for a range of values of this Eta value
% Computed below:
% .oBinWidth
% .oBinCenters

% Get params, if input is a numeric code for pre-set parameters
if exist('pp','var') && isnumeric(pp)
    % if params are given in the form: [1,3]; 
    pp = preprocHoG_GetMetaParams(pp);
elseif ~exist('pp','var')
    pp = struct;
end
% Fill input / meta param struct with defaults
params = defaultOpt(pp,params);

% Computed parameters:
params.oBinWidth=params.oMax/params.nOriBins;
% Currently oBinCenters CAN'T be specified independently of oBinWidth & 
% oMax (This caused problems w/ _GetMetaParams) - maybe re-implement??
params.oBinCenters = 0:params.oBinWidth:(params.oMax-params.oBinWidth);
% Compute the rest of the parameters from params provided:
params = computeHoGparams(params);
% Return parameters if no input arguments
if ~nargin
    varargout{1} = params;
    return
end

% Prep for pyramid HoG computation:
SpBins = params.nSpatBins;
% Get number of images
if ismatrix(S)
    nIms = 1;
else
    sz = size(S);
    nIms = sz(end);
end
% Preallocate Spreproc
if ~isempty(params.HoG_Norm_Area) && strcmpi(params.HoG_Norm_Area{1},'corners')
    nSurr = 4;
else
    nSurr = 1;
end
Spreproc = nan(nIms,params.nHoGdims);
for iS = 1:nIms
    if nIms>200
        progressdot(iS,200,2000,nIms)
    elseif nIms < 200 && nIms > 1
        disp('computing HoG')
    end
    % Pull single image for preprocessing
    if ndims(S)==4
        im = S(:,:,:,iS);
    elseif ismember(ndims(S),[2,3])
        im = S(:,:,iS);
    else
        error([mfilename ':BadStimSize'],'WTF kind of image sequence doesn''t have 3 or 4 dimensions??')
    end
    % Loop for pyramid HoG
    Spp = zeros(sum(SpBins.^2 * params.nSubBins * params.nOriBins),1);
    for iSz = 1:length(SpBins)
        % Resize image to match desired spatial scale
        % (+2 to add 1 pixel to outside the bins closest to the image edge)
        imR = imresize(im,[SpBins(iSz)*params.pxPerBin+2,SpBins(iSz)*params.pxPerBin+2]);
        params.nSpatBins = SpBins(iSz);
        if iSz == 1
            idx = 1:SpBins(iSz)^2*params.nOriBins * nSurr;
        else
            idx = (1:SpBins(iSz)^2*params.nOriBins * nSurr) + sum(SpBins(1:(iSz-1)).^2)*params.nOriBins * nSurr;
        end
        if iS==1 && iSz == 1
            [Spp(idx),params] = compute_HoG(imR,params);
        else
            Spp(idx) = compute_HoG(imR,params);
        end
    end
    Spreproc(iS,:) = Spp';
end
% Re-set spatial bin count after pyramid completes
params.nSpatBins = SpBins;

varargout{1} = Spreproc;
if nargout>1
    varargout{2} = params;
end
% All done!
