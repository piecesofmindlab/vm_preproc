function varargout = hdr2zDepth(z,params)
% Usage: [z,params] = hdr2zDepth(z,params)
% 
% Takes HDR image as input (either string or image read in with "hdrread")
% and outputs a single precision image at size [ImSz(1) x ImSz(2) x 1]
% 
% NOTE! this function should be replaced by exr2zDepth as of 2012.09.06 - 
% .hdr files are not as precise at quantifying values over 1!! depth values
% are ALIASED AND SHITTY!
% 
% All options return INCREASING values with increasing distance (meaning,
% 0 = close, 1 = far)
%
% Inputs:
%   Z = HDR image or file string (Make 
%
% Outputs: 
%   z = z depth image
%   params = parameters used for conversion of hdr image to z depth image
%       (optional). If no inputs are given to the function, "params" is
%       returned as the only output. "params" is a struct array with
%       fields:
%       .type = 'MedianNorm_1-1/z'; % type of normalization. options:
%           'Untouched' (no filtering, no nothing - just output of hdrread)
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
% 
% ML 2012.01.10
% Updated 2012.04.13

warning('DO NOT USE THIS FUNCTION! Use exr2zDepth instead!')

% Parameters
pp.type = 'exp_med_0-1';% 'mediannorm_1-1/z'; % '0-1max'; '1-0'; % 'medianNorm'; % 0-1medianNorm; %  
pp.ImSz = nan;
pp.maxDepth = 1000;
if exist('params','var')
    params = mlFillStruct(params,pp,true);
else
    params = pp;
end
if ~nargin
    % Return params
    varargout{1} = params;
    return
end

% Inputs
if ischar(z)
    z = hdrread(z);
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
    disp('I didn''t do it, I swear!')
    return
    disp('See?!?');
end

% Preprocess to get rid of near-infinite points
z(z>params.maxDepth) = max(z(z<params.maxDepth));
% And smooth with median filter to get rid of local outliers
iz = z.^-1;
izf = medfilt2(iz,[3,3],'symmetric');
iiz = izf.^-1;
iiz(iiz>1000) = max(iiz(iiz<1000));

switch lower(params.type)
    case 'realdepth'
        % Return real depth
        Z = iiz;
    case '0-1';
        % Normalize by maximum value
        Z = mlNormalize(z,'wholematrix');
    case 'mediannorm'
        % Normalize by median value
        iiz = iiz-min(iiz(:));
        Z = iiz/median(iiz(:));
    case 'mediannorm0cap3'
        % z distance w/ min subtracted off, divided by median Z dist, w/ 
        % values > 3x median, cropped to 3
        iiz = iiz-min(iiz(:));
        Z = iiz/median(iiz(:));
        Z(Z>3) = 3;
    case '1-1/z'
        iiz = iiz-min(iiz(:))+1;
        Z = 1-iiz.^-1;
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
    case 'exp_med'
        % Normalize w/ sigmoid function around median
        Z = iiz-median(iiz(:));
        Z = Z/median(iiz(:));
        Z = (1+exp(-Z)).^-1;  %/median(iiz(:))
    case 'exp_med_0-1'
        % Normalize w/ sigmoid function around median
        Z = iiz-median(iiz(:));
        Z = Z/median(iiz(:));
        Z = (1+exp(-Z)).^-1;  %/median(iiz(:))
        % ... and stretch result to range of 0-1
        Z = mlNormalize(Z,'wholematrix');
end

Z = single(imresize(Z,params.ImSz));
varargout{1} = Z;
if nargout ==2
    varargout{2} = params;
end