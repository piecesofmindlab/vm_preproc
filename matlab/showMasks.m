function showMasks(MaskStack,n,ax)
% Usage: showMasks(MaskStack,n,ax)
% 
% Quickie to show (4 for now) masks
% 
% ML 2012.03.22

if ~exist('ax','var')
    [pos,ax] = mlTileAxes(2,2);
end

for iAx = 1:size(MaskStack,3)
    axes(ax(iAx));
    imagesc(MaskStack(:,:,iAx,n));
    colormap(gray(256))
    axis image off
end
    