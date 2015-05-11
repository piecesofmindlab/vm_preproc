function varargout = exr2zDepth(z,params)
% Usage: [z,params] = exr2zDepth(z,params)
% 
% Takes EXR image as input (either string or image read in with "exrread")
% and outputs a single precision image at size [ImSz(1) x ImSz(2) x 1]
% 
% NOTE! this function replaces hdr2zDepth as of 2012.09.06 - .hdr files are
% not as precise at quantifying values outside the range of [0 1]!!
% 
% All options return INCREASING values with increasing distance (meaning,
% 0 = close, 1 = far)
%
% Inputs:
%   Z = HDR image or file string (Make 
%
% Outputs: 
%   z = z depth image
%   params = parameters used for conversion of exr image to z depth image
%       (optional). If no inputs are given to the function, "params" is
%       returned as the only output. "params" is a struct array with
%       fields:
%       .type = 'MedianNorm_1-1/z'; % type of normalization. options:
%           'Untouched' (no filtering, no nothing - just output of exrread)
%           'RealDepth' 
%           '0-1' 
%           'MedianNorm' 
%           'MedianNorm0cap3' 
%           'MedianNorm_1-1/z' 
%           'exp_med_0-1' <default>
%       .ImSz = nan; % size to which to resize the image. nan input keeps
%           images the same size (no re-sizing)
%       .maxDepth = 1000; % Crop all dist. values above this to this value.
%           Necessary b/c some images may have pixels with spurious
%           near-infinity depths due to rendering errors.
%       .SkyMask = mask that includes all sky; used to set all sky pixels
%           to <the max depth in the scene> * 1.1 if params.type =
%           'realdepthnoskies'
% ML 2012.01.10
% Updated 2012.04.13

% Convention:
skyDepth = 1000; % sky is rendered at this depth in BVP
% Parameters
pDefault.type = 'exp_med_0-1';% 'mediannorm_1-1/z'; % '0-1max'; '1-0'; % 'medianNorm'; % 0-1medianNorm; %  
pDefault.ImSz = nan;
pDefault.maxDepth = skyDepth; % set at 1000 as convention for sky depth in BVP
if ~exist('params','var')
    params = struct;
end
% Fill defaults
params = defaultOpt(params,pDefault);
if ~nargin
    % Return params
    varargout{1} = params;
    return
end

% Inputs
if ischar(z)
    zf = z;
    z = exrread(z);
end
if ndims(z)==3
    z = z(:,:,1);
end
if isnan(params.ImSz)
    Sz = size(z);
    params.ImSz = Sz(1:2);
end
if numel(params.ImSz)==1
    params.ImSz = [params.ImSz,params.ImSz];
end

if strcmpi(params.type,'untouched')
    Z = z;
    varargout{1} = Z;
    if nargout ==2
        varargout{2} = params;
    end
    return
end
origZ = z;
% Preprocess to get rid of near-infinite points
z(z>=params.maxDepth) = params.maxDepth; %max(z(z<params.maxDepth))*1.1;
% Invert depth and smooth with median filter to get rid of local outliers
iz = z.^-1;
izf = medfilt2(iz,[3,3],'symmetric');
iiz = izf.^-1;

switch lower(params.type)
    case 'realdepth'
        % Return real depth
        Z = iiz;
        Z(mlRound(Z,.001)==params.maxDepth) = params.maxDepth;
        % Smart downsampling: respect sky/infinite points!
        % Find (sky) voxels
        Idx = double(Z(:,:,1)==min(params.maxDepth,skyDepth)); 
        IdxR = imresize(Idx,params.ImSz,'bilinear');
        % mark pixels to keep nearest-neighbor interpolation (at edge of sky)
        nnPix = IdxR>0 & IdxR<1;
        zbl = imresize(Z(:,:,1),params.ImSz,'bilinear');
        znn = imresize(Z(:,:,1),params.ImSz,'nearest');
        Z = zbl;
        Z(nnPix) = znn(nnPix);
    case '0-1';
        % Normalize by maximum value
        Z = mlNormalize(z,'wholematrix');
        Z = single(imresize(Z,params.ImSz,'bilinear'));
    case 'mediannorm'
        % Normalize by median value
        iiz = iiz-min(iiz(:));
        Z = iiz/median(iiz(:));
        Z = single(imresize(Z,params.ImSz,'bilinear'));
    case 'mediannorm0cap3'
        % z distance w/ min subtracted off, divided by median Z dist, w/ 
        % values > 3x median, cropped to 3
        iiz = iiz-min(iiz(:));
        Z = iiz/median(iiz(:));
        Z(Z>3) = 3;
        Z = single(imresize(Z,params.ImSz,'bilinear'));
    case '1-1/z'
        iiz = iiz-min(iiz(:))+1;
        Z = 1-iiz.^-1;
        Z = single(imresize(Z,params.ImSz,'bilinear'));
    case 'mediannorm_1-1/z'
        % 1/z transform, with distance computed (+ and -) from MEDIAN
        % distance in the image
        med = median(iiz(:));
        Z = (iiz-med)/med;
        Z(Z>=0) = Z(Z>=0)+1;
        Z(Z<0) = Z(Z<0) -1;
        Z = Z.^-1;
        Z(Z>=0) = 1-Z(Z>=0);
        Z(Z<0) = -1-Z(Z<0);
        Z = single(imresize(Z,params.ImSz,'bilinear'));
    case 'exp_med'
        % Normalize w/ sigmoid function around median
        Z = iiz-median(iiz(:));
        Z = Z/median(iiz(:));
        Z = (1+exp(-Z)).^-1;  %/median(iiz(:))
        Z = single(imresize(Z,params.ImSz,'bilinear'));
    case 'exp_med_0-1'
        % Normalize w/ sigmoid function around median
        Z = iiz-median(iiz(:));
        Z = Z/median(iiz(:));
        Z = (1+exp(-Z)).^-1;  %/median(iiz(:))
        % ... and stretch result to range of 0-1
        Z = mlNormalize(Z,'wholematrix');
        % Need bilinear downsampling, because cubic (default) does weird shit
        Z = single(imresize(Z,params.ImSz,'bilinear'));
end

varargout{1} = Z;
if nargout ==2
    varargout{2} = params;
end