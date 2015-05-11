function varargout = compute_HoN(n,pp)
% Usage: [HoN,params] = compute_HoN(im,params)
% 
% Computes histograms of normals for a *SINGLE* normal image "n" given
% parameters "params" 
% 
% Note that HoN channels are not simple counts of edges - each "histogram"
% is a weighted sum of orientation energy at different 
% 
% Inputs: 
% n = normal image (X,Y,Z normals for each pixel, e.g. output of BVP normal
%   render + hdr2normals.m)
% params = struct, with fields (default properties listed)
%     % %%% Normal bins
%     % Centers of normal bins:
%     % NOTE! It is not a terribly easy problem to place equi-distant points
%     % around a sphere or half-sphere. See:
%     % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
%     % ...for potential improvements in selecting normal bin centers
%     params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
%         -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
%         0,0,1]; % straight-ahead
%     params.Is_2D = false; % Whether to flatten all normals into the image plane
%     %%% Spatial bins
%     params.nSpatBins = 9; % number of spatial bins across image (square grid)
%     params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
%     params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
%     params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
%     %%% Normalization parameters
%     params.HON_NORM_MAXVAL = 0.2; % max value at which to clip HoN energy (Taken from HoG code - update??)
%     params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
%       %number of HoG channels. Not explored thoroughly as of 2012.04.11
%     params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to
%       %second normalization of HoN channels. Basically, prevents dividing by 0
%     % Placeholders for descriptors of HoN channels
%     params.HoNparams.Xc = []; % placeholder for descriptors of HoG channels
%     params.HoNparams.Yc = [];
%     params.HoNparams.Norm = [];
%     params.HoNparams.Sz = []; % This is (sort of) spatial frequency... but not really, because the orientation computation is simpler than that
% 
% ML 2012.04.20

% Inputs: Default parameters
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
params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to
  %second normalization of HoN channels. Basically, prevents dividing by 0
% Placeholders for descriptors of HoN channels
params.HoNparams.Xc = []; % placeholder for descriptors of HoG channels
params.HoNparams.Yc = [];
params.HoNparams.Norm = [];
params.HoNparams.Sz = []; % This is (sort of) spatial frequency... but not really, because the orientation computation is simpler than that

%%% Computed parameters
params.nNormBins = size(params.normBinCenters,1);
% Normalize bin vectors 
L = sqrt(sum(params.normBinCenters.^2,2));
params.normBinCenters = bsxfun(@rdivide,params.normBinCenters,L);
params.nNormBins = size(params.normBinCenters,1);
% Note, that the bin width for these bins will not be well-defined (or,
% will not be uniform). For now, take the average min angle between bins 
d = acosd(params.normBinCenters * params.normBinCenters');
d(abs(d)<.00001) = nan;
params.normBinWidth = mean(nanmin(d)); % Add an extra buffer to this? We 
  % don't want "stray" pixels with normals that don't fall into any bin
  % (but we also don't want to double-count pixels) 

if ~nargin
    varargout{1} = params;
    return;
end
if exist('pp','var')
    params = mlFillStruct(pp,params,true);
end
if ischar(n)
    n = hdr2normals(n);
end

[H,W,nDim] = size(n);

% Assure that params.normBinCenters are normalized to length 1:
params.normBinCenters = bsxfun(@rdivide,params.normBinCenters,sum(params.normBinCenters.^2,2).^.5);
% Pre-allocate HoN
HoN = nan(params.nSpatBins^2*params.nSubBins*params.nNormBins,1);

nScales = length(params.nSpatBins);
for iSc = 1:nScales
    % Loop over scales??
    % Re-size image? Re-size bins? 
    
    % To compute angle between vectors (i.e., btw bin center and pixel
    % normal):  Angle = acos((a'*b)/(norm(a)*norm(b)))
    nr = reshape(n,H*W,nDim);

    o = nr * params.normBinCenters';
    Lb = sqrt(sum(nr.^2,2));
    o = bsxfun(@rdivide,o,Lb); % Norm of params.normBinCenters should be 1
    angles = acosd(o);
    % The following is a "soft" histogramming of normals. I.e., if a given
    % normal falls partway between two normal bins, it is partially
    % assigned to each of the nearest bins (not exclusively to one).
    HoNtmp = max(0,params.normBinWidth-angles)/params.normBinWidth;
    % Normalize all histograms to sum to 1?
    HoNtmp = reshape(HoNtmp,[H,W,params.nNormBins]);
    % Weight normal bins? In HoNs, this is done by multiplying the
    % (proportion of energy at a given orientation) by the magnitude of
    % gradients. Is there a useful analogy here? We're not measuring
    % differences / discontinuities...
    
    % Spatial bins
    [HoNtmp2,Xc,Yc,Sz] = assign_bins(HoNtmp,params);
    % HoN description parameters:
    params.SpatBinSz_Pix = round(unique(Sz)*size(n,1)); % TO COME: Deal w/ multiple sizes!
    params.HoNparams.Xc = [params.HoNparams.Xc;Xc];
    params.HoNparams.Yc = [params.HoNparams.Yc;Yc];
    
    Norm = repmat(reshape(params.normBinCenters,[1,size(params.normBinCenters)]),[params.nSpatBins^2*params.nSubBins,1]);
    Norm = reshape(Norm,[params.nSpatBins^2*params.nSubBins*params.nNormBins,3]);
    params.HoNparams.Norm = [params.HoNparams.Norm; Norm];
    params.HoNparams.Sz = [params.HoNparams.Sz;Sz];

    % Normalize!
    num_cells = [params.nSpatBins,params.nSpatBins];
    num_HoN_dims = params.nNormBins * params.nSubBins;
    HoNtmp2 = reshape(HoNtmp2,[prod(num_cells),num_HoN_dims]);
    % Normalize (per Dalal & Triggs)
    % Compute L2 norm (across orientations and part-bins [overlapping bins])
    % Eta is a regularization factor, based on params.HOG_NORM_EPS multiplied by the number of channels
    Eta = sqrt(sum(HoNtmp2.^2,2))+params.HON_NORM_EPS*num_HoN_dims;
    % Normalize
    HoNtmp2 = bsxfun(@rdivide,HoNtmp2,Eta);
    % Clip high values (Change this to some squashing function? sqrt? log?)
    HoNtmp2 = min(HoNtmp2,params.HON_NORM_MAXVAL);
    % Normalize again:
    Eta = sqrt(sum(HoNtmp2.^2,2))+params.HON_NORM_EPS2;
    HoNtmp2 = bsxfun(@rdivide,HoNtmp2,Eta);
    % Re-format
    %hog=single(reshape(hog,[num_cells(2:-1:1),num_hog_dims]));
    HoN = HoNtmp2(:);
end
% Output 
varargout{1} = HoN;
if nargout > 1
    varargout{2} = params;
end
