function [Spp,params] = downsampleCurvIm(S,params)
% Usage: [Spp,params] = downsampleCurvIm(S,params)
% 
% Downsample a curvature image. 
% 
% Inputs: 
%   S : A curvature image, with curvature values for each pixel where a
%       boundary contour exists and nans elsewhere. Size = [Y,X,nScales].   
%   params : a struct array of parameters, with fields:
%       .blur = 'gaussian';
%       .dsMethod = 'nearest'; % 'bilinear'
%       .scale = [8,17]; % vector of scale(s) for curvature radius. Translates to image resizing.
%       .nansub = 0; % 1i; 
%       .dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
%       .normalizeByContour = true;
% 
% ML 2013.08.30


% Inputs
if ~exist('params','var')
    params = struct;
end
% Default parameters
dParams.blur = 'gaussian';
dParams.dsMethod = 'nearest'; % 'bilinear'
dParams.scale = [8,17]; % vector of scale(s) for curvature radius. Translates to image resizing.
dParams.nansub = 0; % 1i; 
dParams.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
dParams.normalizeByContour = true; % normalize curvature value by presence of contour
% Fill default opts
params = defaultOpt(params,dParams);
% Compute more params
if length(params.dsFactor)==1
    params.dsFactor = repmat(params.dsFactor,length(params.scale),1);
end
[y,x,nScales] = size(S);
for iSc = 1:nScales
    dsF = params.dsFactor(iSc);
    ImSz = floor(x/((params.scale(iSc)*2+1)* dsF));
    params.ImSz(iSc) = ImSz^2;
end

% Preallocate
SppTmp = cell(nScales,1);
for iSc = 1:nScales
    s = S(:,:,iSc);
    sc = params.scale(iSc);
    dsF = params.dsFactor(iSc);
    ImSz = sqrt(params.ImSz(iSc));
    % identify / remove nans
    nn = ~isnan(s); % Locations where there actually is a contour - useful??
    s(isnan(s)) = params.nansub;
    % Blur
    if ~strcmp(params.blur,'none')
        % pick scale of gaussian to match scale of computed curvature
        g = fspecial('gaussian',round((sc*2+1)*dsF),sc*dsF);
        s = conv2(s,g,'same');
        nnb = conv2(double(nn),g,'same');
    end 
    % Downsample (switch params.dsMethod ??)
    switch lower(params.dsMethod)
        case {'bilinear','nearest'}
            s = imresize(s,[ImSz,ImSz],params.dsMethod);
            nnb = imresize(nnb,[ImSz,ImSz],'nearest');
        case 'none'
            0; % Do nothing
    end
    if params.normalizeByContour
        % Divide by amount of contour present in each bin
        s = s./nnb;
        s(isnan(s)) = 0;
        % DEBUGGING:
        %sq = s./nnb;
        %sq(isnan(s)) = 0;
    end
    % DEBUGGING:
    %if any(sq(:)>5)
    %    keyboard
    %end
    %s = sq;
    
    SppTmp{iSc} = s(:);
    if params.nansub==1i
        SppTmp{iSc} = real(SppTmp{iSc}); % abs?
    end
end
Spp = cat(1,SppTmp{:});
