function showXYZNormals(N,fName,n,ax)
% Usage: showXYZNormals(N [,fName][,n][,ax])
% 
% Displays normals as three separate (x,y,z normal) images w/ pos/neg
% colormap.
% 
% Inputs:
%   fName = save name for file (if you want to save image)
%   N = normal image (3D = x,y,z), w/ normals from -1 to 1
%   n = number of frame if N is 4D (x,y,z,frame)
%   ax = 

% Ax should be a scalar (figure handle), or a 3-long vector (axis handles),
% if supplied. 
%

if ischar(N)
    % Load w/ usual preprocessing from hdr
    N = hdr2normals(N);
end
if ~exist('n','var')||isempty(n);
    n = 1;
end

if exist('ax','var')
    if length(ax)==1
        h = mlFigure(ax,[8,2]);
        [Pos ax] = mlTileAxes(1,3);
    end
else
    h = mlFigure([],[8,2]);
    [Pos ax] = mlTileAxes(1,3);
end
XYZ = 'XYZ';
XYZtit = {'-1 = left, +1 = right','-1 = down, +1 = up','-1 = away from cam, +1 = toward cam'};
load MLColors_cMapPosNeg % Loads "cMap" color map
for iN = 1:3
    axes(ax(iN));
    Nx = N(:,:,iN,n);
    imagesc(Nx)
    caxis([-1,1]);
    axis square off;
    title({[XYZ(iN) ' normal'],XYZtit{iN}})
    colormap(cMap);
    h = colorbar;
    set(h,'ytick',-1:.5:1,'fontsize',8)
end

% Optional save
if exist('fName','var') && ~isempty(fName)
    print(sprintf('-f%d',h),'-dpng','-r300',fName);
end