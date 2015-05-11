function showNormalIm(N,n,h,fName)
% Usage: showNormalIm(N,n,h,fName)
% 
% Displays normals as three separate (x,y,z normal) images w/ pos/neg
% colormap.
% 
% Inputs:
%   N = normal image (3D = x,y,z), w/ normals from -1 to 1
%   n = number of frame if N is 4D (x,y,z,frame)
%   fName = save name for file (if you want to save image)
% 
% Created by ML 2012.04.14

if ischar(N)
    % Load w/ usual preprocessing from hdr
    N = exr2normals(N);
end
if ~exist('n','var')||isempty(n);
    n = 1;
end
%load MLColors_cMapPosNeg % Loads cMap
load MLColors_cMapBlueWhiteRed
cMap = flipud(cMap);
if ~exist('h','var')
    h = mlFigure([],[8,3]);
    [Pos Ax] = mlTileAxes(1,3,[0,0,.9,.8],1,.1,'position');
else
    if iscell(h)
        [h,Pos,Ax] = h{:};
    else
        figure(h);
        [Pos Ax] = mlTileAxes(1,3,[0,0,.9,.8],1,.1,'position');
    end
end

XYZ = 'XYZ';
XYZtit = {'-1 = left, +1 = right','-1 = away from cam, +1 = toward cam','-1 = down, +1 = up'};
for iN = 1:3
    axes(Ax(iN));
    cla;
    Nx = N(:,:,iN,n);
    imagesc(Nx)
    caxis([-1,1]);
    axis image off;
    title({[XYZ(iN) ' normal'],XYZtit{iN}})
    colormap(cMap);
    if iN == 3
        hh = colorbar;
        set(hh,'ytick',-1:.5:1,'fontsize',8)
    end
    set(Ax(iN),'position',Pos(iN,:));
end

% Optional save
if exist('fName','var')
    print(sprintf('-f%d',h),'-dpng','-r300',fName);
end