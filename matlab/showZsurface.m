function showZsurface(X,Y,Z,value,cMap,ax,sName)
% Usage: showZsurface(X,Y,Z,cMap,sName)
% 
% Shows a z-depth buffer as a surface 
%
% ML 2012.11.26

% Inputs
if ~exist('ax','var')||isempty(ax)
    fH = mlFigure([],[3,3]);
    ax = gca;
else
    if length(ax)==2
        fH = ax(1);
        ax = ax(2);
    end
    axes(ax)
end
if ~exist('cMap','var')||isempty(cMap)
    cMap = flipud(gray(512));
end
if ~exist('value','var')||isempty(value)
    value = double(Z);
end

sz = size(Z);
XYZ = [X(:),Y(:),double(Z(:))];
rMat = angle2dcm(-pi/2,0,0,'XYZ');
XYZr = XYZ*rMat;
X = reshape(XYZr(:,1),sz);
Y = reshape(XYZr(:,2),sz);
Z = reshape(XYZr(:,3),sz);
sp = {'edgealpha',0};
surf(X,Y,Z,value,sp{:})
view(0,0); % dead-on view
colormap(cMap); % 
axis off

if exist('sName','var')
    print(sprintf('-f%d',fH),'-dpng','-r300');
end