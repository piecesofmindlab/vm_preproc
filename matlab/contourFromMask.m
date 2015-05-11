function varargout = contourFromMask(S,paramsIn)
% Usage: [CurveStruct,params] = contourFromMask(S,params)
%
% Computes contours within/around objects given a set of stacked masks.
%
% Inputs:
%   S = a 3-D (4-D??) array of mask images, with the nearest mask
%       coming LAST in th 3rd dimension
%   params = struct array with fields:
%       .Is_CutOccludedContours = true; % whether to remove occluded
%           contours from lines
%       ?.SizeXY = size of image?
%       ?.GridSize = x,y grid size?? (resolution of
%
% Outputs:
%   CurveStruct = [nObjects (x nFrames??)] (cell?) struct array, with
%       fields:
%       .

% Relevant parameters for first-stage processing
params.ImSmoothSTD = [5,3,3]; % Leave empty for no smoothing
params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
params.CollapseBinBy = 'Max'; % How to summarize over bins of curvature
params.MaskThresh = 5; %for uint8 images
params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
params.ImBinSzPx = 16; % Curvaure will be computed at ImBinSzPx * Scale size,
                       % and averaged to get a single curvature value 
params.Is_FillHoles = false;
params.Is_ClipOccluded = true;
params.FlattenInfCurvFn = {'crop',-1,1}; % {'mlSquash',-1,1}; % 


% FIX ME!
params.nScales = length(params.Scales);

if ~nargin
    % Return params struct
    varargout{1} = params;
    return
elseif nargin == 1
    paramsIn = struct();
end
params = mlFillStruct(paramsIn,params,true);

nMasks = size(S,3);
% Preallocate values for this scale
%CurvParamTmp = nan(params.Scales(iScale)*params.Scales(iScale),nMasks);
iFr = 1; % for now...
C = struct('X',{cell(nMasks,params.nScales)},'Y',{cell(nMasks,params.nScales)},'K',{cell(nMasks,params.nScales)});
for iScale = 1:params.nScales
    for iM = 1:nMasks
        %{
        Options for curvature at different scales:
        (1) resize whole image. Not ideal; potentially loses skinny projections of
        images (particularly at finest scale).
        (2) compute full-size image curvature, then bin (via max / whatever)
        SO: we want some degree of granularity per bin - say, 20x20 points
        of curvature actually calculated within each bin (which we will
        then combine in some way - either mean or something else)
        So: resize image to some factor of params.Scales. Start with 16x
        (16*, for powers of 2?) that value.
        %}
        % Bins will be of SLIGHTLY uneven size (depending on choice for
        % params.Scales); this shouldn't matter.
                
        SizeTo = params.Scales(iScale)*params.ImBinSzPx;
        imR = imresize(S(:,:,iM,iFr),[SizeTo,SizeTo]);
        Mask = imresize(S(:,:,:,iFr),[SizeTo,SizeTo])>params.MaskThresh;
        imR = double(imR);
        % Create binary image:
        imBW = imR > params.MaskThresh;
        if ~any(imBW(:));
            % Empty mask. continue.
            continue
        end
        % Smooth image or not
        if any(params.ImSmoothSTD)
            gSz = params.ImSmoothSTD(iScale);
            ss = linspace(-gSz,gSz,gSz);
            [x y] = meshgrid(ss,ss);
            sigma = gSz/2;
            G = 1/pi/sigma^2*exp(-(x.^2+y.^2)/sigma^2);
            imR = conv2(imR,G,'same');
            clear gSz ss x y G
        end
        % Get contour surrounding image
        % NOTE: see HowDoesContourcSampleImageLocations.m (in
        % BVP_ShapeDims/ folder)
        % for a discussion of how contourc.m samples points along a
        % contour in an image (and a partial solution to the
        % problem). The sampling is NOT on a regular grid, and
        % there seems to be a bias to over-sample points near
        % regions of high curvature (i.e., the contour will contain
        % points that are more densely-spaced at points of
        % curvature). This will only be problematic if we are using
        % things besides max curvature for binning...
        Ctmp = contourcs(imR,1);
        % Keep more contours for holes, etc??
        ToKill = [];
        for iC = 2:length(Ctmp);
            if Ctmp(iC).Length < 10;
                ToKill = [ToKill,iC];
            end
        end
        Ctmp(ToKill) = [];
        % Holes will need to have points in opposite rotation order as outlines
        % (CW for outlines, CCW for holes)
        xx = [];
        yy = [];
        for iC = 1:length(Ctmp)
            % Cell array for x? 
            x = Ctmp(iC).X;
            y = Ctmp(iC).Y;
            if any(params.CurvSmoothSTD)
                % Smooth the x,y points along the curve itself
                Sz = 3*params.CurvSmoothSTD(iScale);
                g = normpdf(-Sz:1:Sz,0,params.CurvSmoothSTD(iScale));
                % Add caps to beginning and end of curve, to prevent conv. artifacts
                xCap = repmat(x(1),1,Sz);
                xTail = repmat(x(end),1,Sz);
                yCap = repmat(y(1),1,Sz);
                yTail = repmat(y(end),1,Sz);
                xToConv = [xCap,x,xTail];
                yToConv = [yCap,y,yTail];
                xSm = conv(xToConv,g); %'same'); %?
                ySm = conv(yToConv,g);
                % getting rid of shitty artifact at ends:
                % This IS necessary; conv(... ,'same') doesn't work!
                x = xSm(Sz*2+1:end-Sz*2)';
                y = ySm(Sz*2+1:end-Sz*2)';
                clear Sz xSm ySm xTail yTail xCap yCap
            else
                x = x';
                y = y';
            end
            %keyboard;
            % Assure that contour points rotate clockwise around object
            IsCW = CWcheck([x,y]);
            if iC==1 
                if ~IsCW
                    % Flip to CW if arrangement is CCW
                    x = flipud(x);
                    y = flipud(y);
                end
            else
                disp('Need to figure out how to handle holes!');
                keyboard;
                % minimum length of contour? 
                % 
                if IsCW
                    % These are holes; thus flip to CCW if arrangement is CW
                    x = flipud(x);
                    y = flipud(y);
                end
            end
            xx = [xx;x]; %insert nans?
            yy = [yy;y]; 
            if params.Is_FillHoles
                break
            end
            % Close polygons (?)
            %x = [x,x(1)];
            %y = [y,y(1)];
        end %iC
        
        % (local) Curvature formula, from Wikipedia
        % (http://en.wikipedia.org/wiki/Curvature)
        % K = abs(dx * ddy - ddx * dy) / (dx^2 + dy^2)^(3/2)
        % Find first derivative (for all points)
        dX = diff([x;x(1)]);
        dY = diff([y;y(1)]);
        % Find second derivative (for all points)
        ddX = diff([dX;dX(1)]);
        ddY = diff([dY;dY(1)]);
        k = (dX .* ddY - ddX .* dY) ./ (dX.^2 + dY.^2).^(3/2);
        % This may be dumb too... why are any k values nans?
        k(isnan(k)) = 0;
        % Squashing function for extrema of curvature:
        if ~isempty(params.FlattenInfCurvFn)
            k = feval(params.FlattenInfCurvFn{1},k,params.FlattenInfCurvFn{2:end});
        end
                
        % Make sure there are no wacky values at ends of curve:
        kz = zscore(k);
        if length(kz)>4
            if any(kz(1:3)>2.5)
                k(1:3) = k(4);
            end
            if any(kz(end-2:end)>2.5)
                k(end-2:end) = k(end-3);
            end
        end
        
        if params.Is_ClipOccluded
            % Clip out parts of curves that are occluded by other
            % objects. TODO: Make this optional!
            if iM < nMasks
                % For all masks up to front mask...
                for iX = iM+1:nMasks
                    % ... remove all points in masks in front of this mask
                    [yf,xf] = find(Mask(:,:,iX));
                    CutIdx = ismember(round([x,y]),[xf,yf],'rows');
                    if any(CutIdx)
                        x(CutIdx) = [];
                        y(CutIdx) = [];
                        %k(CutIdx) = [];
                    end
                    clear xf yf
                end
            end
        end
        C.X{iM,iScale} = x;
        C.Y{iM,iScale} = y;
        C.K{iM,iScale} = k;
    end
end
varargout{1} = C;
if nargout > 1
    varargout{2} = params;
end
