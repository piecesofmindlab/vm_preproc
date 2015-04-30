function varargout = compute_HoG(im,pp)
% Usage: [HoG,params] = compute_HoG(im,params)
% 
% Computes histograms of gradients for *SINGLE* image "im" given parameters
% "params" Computes HoG at one scale only - for a pyramid HoG, call this
% function multiple times.
% 
% Note that HoG channels are not simple counts of edges - each "histogram"
% is a weighted sum of the energy at different orientations
% 
% Inputs: 
% im = RGB (or otherwise) image
% 
% params = struct, with fields (default properties listed)
%     % For gradients
%     params.gradParams.ChannelCollapseMethod = 'max'; % no other method working yet (2012.04.03)
%     params.gradParams.IsSqrt = true;
%     params.gradParams.IsLAB = false; % convert to LAB color space before computing gradients
%       (seems like a good idea, but is somehow creating complex numbers,
%       which screws up subsequent computations)
%     % For orientation bins
%     params.nOriBins = 8; % number of orientation bins
%     params.oMax = 360; % or 360, for full-circle orientations
%     % For spatial bins
%     params.nSpatBins = 9; % number of spatial bins across image (square grid)
%     params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
%     params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
%     params.Use_Gaussian_Bins = true; % (vs. flat coding of space)
%     % For normalization
%     params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (MODIFY??)
%     params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
%       number of HoG channels. nan value skips this normalization! 
%     params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
%       second (post-crop) normalization of HoG channels (See below) nan value skips this normalization! 
%       thoroughly as of 2012.04.03 
%     % Placeholder for descriptors of HoG channels
%     params.HoGparams = []; 
% 
% TO DO: Compute 3D HoG (x,y,time)
% 
% ML 2012.04.02

% Inputs
% For gradients
params.gradParams.ChannelCollapseMethod = 'max';
params.gradParams.IsSqrt = true;
params.gradParams.IsLAB = false;
% For orientation bins
params.nOriBins = 4; % number of orientation bins
params.oMax = 180; % or 360, for full-circle orientations
params.wtByGradMag = true; % 
% For spatial bins
params.nSpatBins = 9; % number of spatial bins across image (square grid)
params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
params.Use_Gaussian_Bins = true; % (vs. flat coding of space)
% For normalization
params.HoG_Norm_Area = []; %{'CenterSurround',9}; % Normalization neighborhood (see getSurroundIndices.m)
params.HOG_NORM_MAXVAL = 0.2; % max value at which to clip HoG energy (MODIFY??)
params.HOG_NORM_EPS = 1.0; % regularization factor 1; multiplier for
  %number of HoG channels. Not explored thoroughly as of 2012.04.03
params.HOG_NORM_EPS2 = 0.01; % regularization factor 2: added to
  %second normalization of HoG channels (See below) Not explored
  %thoroughly as of 2012.04.03 
% Placeholder for descriptors of HoG channels % Temporarily disabled to
% compute in outer loop (preprocHoG.m)
%params.HoGparams.Xc = []; % placeholder for descriptors of HoG channels
%params.HoGparams.Yc = [];
%params.HoGparams.Ori = [];
%params.HoGparams.Sz = []; % This is (sort of) spatial frequency... but not really, because the orientation computation is simpler than that
% Computed below:
% .oBinWidth
% .oBinCenters

if ~nargin
    % Give back "params" struct
    varargout{1} = params;
    return 
end

% Fill in defaults, compute other params
if exist('pp','var') && ~isempty(pp)
    params = defaultOpt(pp,params);
end
params.oBinWidth=params.oMax/params.nOriBins;
if ~isfield(params,'oBinCenters')
    % Can be specified independently, or can be computed from simpler params:
    params.oBinCenters = 0:params.oBinWidth:(params.oMax-params.oBinWidth);
else
    % ?do something?
end

% Preproc stuff
[H,W,nCh] = size(im);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Step 1: Compute gradients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[gm,go] = compute_gradients(im,params.gradParams);
if params.oMax==180
    % Collapse 360 deg ori down to 180
    go(go>180) = go(go>180)-180;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Step 2: Bin orientations and spatial positions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if params.nOriBins == 1
    HoG = gm;
else
    % Circular distance function
    cDist = @(a,b,mx) min(abs(a-b), mx - abs(a-b));
    % The following is a "soft" histogramming of orientations. This means that
    % if there are two bins centers at, e.g., 0 and 45 degrees, then an angle
    % of 22.5 will be assigned to both bins with a value of .5 
    % ori_hist(:,x,y) is non-negative and sums to 1 and
    % ori_hist(A,x,y) is the fraction of the gradient angle at pixel (x,y) that falls in bin A
    angles = repmat(reshape(params.oBinCenters,[1,1,params.nOriBins]),[H,W,1]);
    bin_dist = bsxfun(@(x,BinCent) cDist(x,BinCent,params.oMax),go,angles);
    ori_hist = max(0,params.oBinWidth-bin_dist)/params.oBinWidth;
    % Weight orientation proportions by magnitude of gradients
    if params.wtByGradMag
        HoG = ori_hist .* repmat(gm,[1,1,params.nOriBins]);
    end
end
% Spatial bins
[HoG,Xc,Yc,Sz] = assign_bins(HoG,params);
% Temporarily disabled for computation in outer loop (preprocHoG.m)
%params.HoGparams.Xc = [params.HoGparams.Xc;Xc];
%params.HoGparams.Yc = [params.HoGparams.Yc;Yc];
%Ori = repmat(params.oBinCenters,[params.nSpatBins^2*params.nSubBins,1]);
%params.HoGparams.Ori = [params.HoGparams.Ori; Ori(:)];
%params.HoGparams.Sz = [params.HoGparams.Sz;Sz];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% STEP 3: Normalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_cells = [params.nSpatBins,params.nSpatBins];

if ~isempty(params.HoG_Norm_Area)
    normBin = getSurroundIndices(num_cells(1),num_cells(2),params.HoG_Norm_Area{1},params.HoG_Norm_Area{2});
else
    normBin = logical(eye(num_cells(1)^2)); % each cell will only be normalized by itself
end

num_hog_dims = params.nOriBins * params.nSubBins; % Get rid of params.nSubBins?? size(normBin,3); % old line follows: Useless (?) : params.nSubBins; % (?)
hog = reshape(HoG,[prod(num_cells),num_hog_dims]);
%HoGnormd = zeros(hog,[1,1,size(normBin,3)]); % Add channels for normalization bins
%hog = repmat(hog,[1,1,size(normBin,3)]); % Add channels for normalization bins
% Normalize (per Dalal & Triggs)
if ~isnan(params.HOG_NORM_EPS)
    % Compute L2 norm (across orientations and part-bins [overlapping bins])
    % Eta is a regularization factor, based on params.HOG_NORM_EPS multiplied by the number of channels
    % preallocate Eta
    %Eta = ones(size(HoGnormd,1),1,size(HoGnormd,3));
    Eta = ones(size(hog,1),1,size(normBin,3));
    for iE = 1:size(normBin,3)
        % Eta is the sum of squares of all the bins specified by "normBin"
        % OLD: Eta = sqrt(sum(hog.^2,2))+params.HOG_NORM_EPS*num_hog_dims;
        Eta(:,1,iE) = sqrt(normBin(:,:,iE)*sum(hog.^2,2))+params.HOG_NORM_EPS*num_hog_dims;
    end
    % Normalize
    hog = bsxfun(@rdivide,hog,Eta);
    % reshape hog
    hog = reshape(hog,[size(hog,1),size(hog,2)*size(hog,3)]);
end
if ~isnan(params.HOG_NORM_MAXVAL)
    % Clip high values (Change this to some squashing function? sqrt? log?)
    hog = min(hog,params.HOG_NORM_MAXVAL);
end
if ~isnan(params.HOG_NORM_EPS2)
    % Normalize again:
    Eta = sqrt(sum(hog.^2,2))+params.HOG_NORM_EPS2;
    hog = bsxfun(@rdivide,hog,Eta);
end
% Re-format
hog = hog(:);
% Output 
varargout{1} = hog;
if nargout > 1
    varargout{2} = params;
end
end
% Now HoG will be nested: position (nSp x nSp), ori (x 4), surround (x 4?),
% scale (for diff scales, this function is called recursively)