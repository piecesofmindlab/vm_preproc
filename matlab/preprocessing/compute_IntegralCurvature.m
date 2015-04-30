function varargout = compute_IntegralCurvature(S,params)
% Usage: [Spp,params] = compute_IntegralCurvature(S,params)
% 
% Compute integral curvature at each point along the boundary of an object
% Return that curvature AT the locations of curvature in the image.
% 
% ML 2013.08.22

% Inputs
if ~exist('params','var')
    params = struct;
end

DebugLevel = isfield(params,'saveViz');
% For visualization
if DebugLevel>0
    h = mlFigure([],[8,4]);
    pos = [mlTileAxes(1,1,[0,0,.5,1]);
           mlTileAxes(2,2,[0.5,0,.5,1])];
    fr = 1;
end
% Default params
dParams.scale = 7;
dParams.curvMethod = 'forloop'; % 'forloop'; % [Change 'forLoop' it sucks] 'conv'
dParams.mergeObjects = 'last'; % 'first'; 'last'; 'none';
dParams.Is_FillHoles = true;
% Fill default params
params = defaultOpt(params,dParams);
if ~nargin
    varargout{1} = params;
    return
end
[ySz,xSz,nObjs] = size(S);
nScales = length(params.scale);
% Optionally merge objects first (to compute between-object curvature)
switch params.mergeObjects
    case 'first'
        S = max(S,[],3);
        [ySz,xSz,nObjs] = size(S);
        Spp = nan(ySz,xSz,nScales);
    otherwise
        Spp = nan(ySz,xSz,nObjs,nScales);
end
    
for iObj = 1:nObjs
    % Test for presence of object
    if sum(sum(S(:,:,iObj)))==0
        continue
    end
    s = S(:,:,iObj);
    % Preprocessing: fill holes (?)
    if params.Is_FillHoles
        s = imfill(s,'holes');
    end
    % Find object boundary. Better only be one object - or, does this
    % matter? Two separate parts for one object mask in close proximity
    % will screw up the curvature computation of the region between them.
    % But that will be comparatively rare. 
    eroded = bwmorph(s,'erode');
    boundary = s-double(eroded);
    % For potential for loop later:
    if ismember(lower(params.curvMethod),{'forloop','optimizedforloop'}); 
        [yx] = bwboundaries(s,8); 
        yx = cat(1,yx{:});
    end
    
    for iScale = 1:nScales
        
        sc = params.scale(iScale); 
        cc = mlCircleRadiusImage(1,sc*2+1)<=1;
        
        switch params.curvMethod
            case 'conv'
                % Quick and dirty
                %tic
                % Method 1: convolution / sum of binary convolution kernel. Gives
                % fraction of circular convolution kernel filled at each boundary
                % point. Fast, but naive: will give spuriously low values if the
                % region "inside" the object is less than params.scale wide
                s = double(s); % for convolution
                cc = double(cc);
                imC = conv2(s,cc,'same')/sum(cc(:)); 
                spp = imC.*boundary;
                spp(boundary==0) = nan;
                % Normalize so straight = 0, convex > 0, concave < 0, [-1 1] range
                sppN = (.5-spp)*2;
                Spp(:,:,iObj,iScale) = sppN;
                %toc
            case 'forloop'
                % Slower, more accurate
                %tic
                %keyboard
                %for iPt = 1:length(yx)
                %x = yx{iPt}(:,2);
                x = yx(:,2);
                %y = yx{iPt}(:,1);
                y = yx(:,1);
                for iXY = 1:length(x)
                    if x(iXY)<=sc+1 || y(iXY)<=sc+1 ||...
                           (size(s,2)-x(iXY))<=sc+1 || (size(s,1)-y(iXY))<=sc+1
                       % SKIP bits too close to the image border for
                       % now...
                       continue;
                    end
                    % Assure that bounding box is within image borders
                    %btw = @(x,a,b) min(max(x,a),b);
                    %xmn = btw(x(iXY)-sc,1,size(s,2));
                    %xmx = btw(x(iXY)+sc,1,size(s,2));
                    %ymn = btw(y(iXY)-sc,1,size(s,1));
                    %ymx = btw(y(iXY)+sc,1,size(s,1));
                    % Cut out image at boundary point
                    %sCut = s(ymn:ymx,xmn:xmx);
                    sCut = s(y(iXY)-sc:y(iXY)+sc,x(iXY)-sc:x(iXY)+sc);
                    sCutOrig = sCut;
                    ccTmp = cc;
                    % Adjust the cut-out part of the image to assure
                    % that there are no gaps behind the boundary /
                    % multiple parts of the image within the circle.
                    % (the following is a faster alterative to bwboundaries
                    sCutX = sCut;
                    % Objects
                    [yf,xf] = find(sCutX);
                    ii = sub2ind([sc*2+1,sc*2+1],yf,xf);
                    NOb = 1;
                    LabOb = zeros(sc*2+1,sc*2+1);
                    while ~isempty(yf) 
                        % Optimized version of imfill - does not check
                        % inputs
                        sCutF = imfill_fast(sCutX<1,ii(1));
                        LabOb(sCutF&sCutX) = NOb;
                        NOb = NOb+1;
                        [yf,xf] = find(sCutX & ~sCutF);
                        ii = sub2ind([sc*2+1,sc*2+1],yf,xf);
                        sCutX = ~sCutF;
                    end
                    centerY = sc+1;
                    centerX = sc+1;
                    % Crop extra object parts within the cutout
                    % window that are  not attached to boundary
                    % being processed
                    if NOb>2
                        centerPx = LabOb(centerY,centerX);
                        uCenterPx = unique(centerPx(centerPx>0));
                        sCut = ismember(LabOb,uCenterPx);
                    else
                        sCutX = sCut;
                    end
                    % Backgrounds
                    [yf,xf] = find(~sCutX);
                    ii = sub2ind([sc*2+1,sc*2+1],yf,xf);
                    NBG = 1;
                    LabBG = zeros(sc*2+1,sc*2+1);
                    while ~isempty(yf) 
                        % Optimized version of imfill - does not check
                        % inputs
                        sCutF = imfill_fast(sCutX>0,ii(1));
                        LabBG(sCutF&~sCutX) = NBG;
                        NBG = NBG+1;
                        [yf,xf] = find(~sCutX & ~sCutF);
                        ii = sub2ind([sc*2+1,sc*2+1],yf,xf);
                        sCutX = sCutF;
                    end
                    if NBG>2
                        % Fill in BG in gaps beyond object boundary
                        % being processed
                        centerPx = LabBG(centerY-1:centerY+1,centerX-1:centerX+1);
                        uCenterPx = unique(centerPx(centerPx>0));
                        sCut(~ismember(LabBG,uCenterPx)) = true;
                    end
                    spp = sum(sCut(:)&ccTmp(:))/sum(ccTmp(:));
                    sppN = (.5-spp)*2;
                    Spp(y(iXY),x(iXY),iObj,iScale) = sppN;

                    % Visualization of algorithm
                    if DebugLevel > 0
                        figure(h); clf; 
                        axes('outerposition',pos(1,:));
                        imagesc(s); axis image off;
                        colormap(gray); 
                        hold on;
                        plot(x(iXY),y(iXY),'r.');
                        r = rectangle('position',[x(iXY)-sc-1,y(iXY)-sc-1,sc*2+1,sc*2+1]);
                        circ = rectangle('position',[x(iXY)-sc-1,y(iXY)-sc-1,sc*2+1,sc*2+1],'curvature',[1,1]);
                        hold off;
                        set([r,circ],'edgecolor','r','linewidth',1);
                        fProps = {'fontname','arial'};
                        axes('outerposition',pos(2,:)); imagesc(sCutOrig); title('Original Cutout',fProps{:}); 
                        axis image; set(gca,'xcolor','r','ycolor','r','linewidth',2,'xtick',[],'ytick',[]);
                        hold on; plot(sc+1,sc+1,'ro','markerfacecolor','r'); hold off;
                        axes('outerposition',pos(3,:)); imagesc(.5*ccTmp+.5*(sCutOrig)); title('Overlap',fProps{:}); 
                        axis image; set(gca,'xcolor','r','ycolor','r','linewidth',2,'xtick',[],'ytick',[]);
                        hold on; plot(sc+1,sc+1,'ro','markerfacecolor','r'); hold off;
                        circ2 = rectangle('position',[1,1,sc*2,sc*2],'curvature',[1,1]);
                        axes('outerposition',pos(4,:)); imagesc(sCut); title('Modified Cutout',fProps{:}); 
                        axis image; set(gca,'xcolor','r','ycolor','r','linewidth',2,'xtick',[],'ytick',[]);
                        hold on; plot(sc+1,sc+1,'ro','markerfacecolor','r'); hold off;
                        axes('outerposition',pos(5,:)); imagesc(.5*ccTmp+.5*(sCut)); title('Modified Overlap',fProps{:}); 
                        axis image; set(gca,'xcolor','r','ycolor','r','linewidth',2,'xtick',[],'ytick',[]);
                        hold on; plot(sc+1,sc+1,'ro','markerfacecolor','r'); hold off;
                        circ3 = rectangle('position',[1,1,sc*2,sc*2],'curvature',[1,1]);
                        set([circ2,circ3],'edgecolor','r','linewidth',2);

                        colormap(gray);
                        drawnow;
                        if isfield(params,'saveViz')
                            set(h,'inverthardcopy','off','color','w');
                            print(sprintf('-f%d',h),'-dpng','-r150',sprintf(params.saveViz,fr));
                            fr = fr+1;
                        end
                    end
                    if sppN > 1
                        error('Value > 1 found in curvature!');
                    end
                end
                %end
                %toc
            case 'optimizedforloop'
                % mex-ified (optimized) version of for-loop curvature computation
                % Turns out this sucks, slower than forloop. Do not use.
                Spp(:,:,iObj,iScale) = curvAtPoints_opt_mex(s,yx,sc,cc);
        end
    end
end
% Optionally collapse objects down to one layer
mx = double(max(S(:)));
if strcmp(params.mergeObjects,'last')
    oIdx = 1:nObjs;
    for iObj = oIdx
        if iObj<nObjs
            msk = double(max(S(:,:,iObj+1:nObjs),[],3))/mx;
            msk = 1-msk;
            msk(msk==0) = nan;
            Spp(:,:,iObj,:) = bsxfun(@times,Spp(:,:,iObj,:),msk);
        end
    end
    Spp = nanmax(Spp,[],3);
end

% Output
Spp = squeeze(Spp);
varargout{1} = Spp;
if nargout>1
    varargout{2} = params;
end