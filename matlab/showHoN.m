function showHoN(HoN,params)
% SUPPLANTED by python function. Py plots are just prettier.
%
% Usage: showHoN(HoN,params)
%
% Code to display a histogram of normals
%
% ML 2012.04.11
b = params.normBinCenters;

%[row,col] = mlFindSquareishDimensions(params.nNormBins);
%axPos = mlTileAxes(row,col,[0,0,1,1],1,.05);
% Legend position: top left, 20% of axis
%legPos = mlTileAxes(row*5,col*5,[0,0,1,1],1,0);
%legPos = legPos(1:5:end,:);
% THIS WILL NEED AN UPDATE to reflect diff. spatial scales (pHoN?)
for iSB = 1:length(params.nSpatBins)
    
rHoN = reshape(HoN(params.HoNparams.Sz==params.,[params.nSpatBins(iSB),params.nSpatBins(iSB)
for ii = 1:params.nNormBins
    % First: display HoN
    axes('position',axPos(ii,:));
    imagesc(rHoN(:,:,ii)
    quiver3(zz,zz,zz,b(:,1),b(:,2),b(:,3),'linewidth',2);
    view(-1,87.5)
end