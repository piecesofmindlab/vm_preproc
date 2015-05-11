function varargout = preprocObjectLoc(S,params)
% Usage: varargout = preprocObjectLoc(S,params)
% 
% Dead-simple model of object location. Takes as input a binary mask of
% whether there is (any) object present in a given location (from
% preprocCombineMasks
%
% 
% ML 2012.04.27
% Updated 2013.05.07

% Inputs
dParams.class = 'preprocObjectLoc';
dParams.nSpatBins = 9; % number of spatial bins across image (square grid)
% Placeholder for descriptors of ObjectLoc channels
dParams.ObjParams.Xc = []; % placeholder for centers of bins
dParams.ObjParams.Yc = [];
dParams.ObjParams.Sz = []; % placeholder for size of bins
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);
params.nObjDims = sum(params.nSpatBins.^2);

nSz = length(params.nSpatBins);
for iSz = 1:nSz
    s = params.nSpatBins(iSz);
    binCent = (1:s)/s + (1/s)/2;
    [x,y] = meshgrid(binCent,binCent);
    params.ObjParams.Xc = [params.ObjParams.Xc; x(:)];
    params.ObjParams.Yc = [params.ObjParams.Yc; y(:)];
    params.ObjParams.Sz = [params.ObjParams.Sz; 1/s * ones(size(x(:)))];
end
if ~nargin
    varargout{1} = dParams;
    return
end


params.ObjParams.SzPx = params.ObjParams.Sz * size(S,1);


% Get number of images
if ndims(S)==4
    nIms = size(S,4);
else %if ndims(S)==3
    nIms = size(S,3);
end
% Preallocate Spreproc
Spreproc = nan(nIms,params.nObjDims);
% Do each size separately (for a pyramid represenation of scales)
for iSz = 1:nSz
    if exist('idx','var')
        idx = (1:params.nSpatBins(iSz)^2) + idx(end);
    else
        idx = 1:params.nSpatBins(iSz)^2;
    end
    % All at once - too much for memory? 
    tmp = imresize(S,[params.nSpatBins(iSz),params.nSpatBins(iSz)]);
    tmp = reshape(tmp,params.nSpatBins(iSz)^2,nIms);
    Spreproc(:,idx) = tmp';
end
% Sub-optimal - we'd like to pre-allocate this, but that's too
% annoying for now, and this shouldn't be too slow (2012.04.20 ML)

% All done!
% (Return Spreproc, save elsewhere)
varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end