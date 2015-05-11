function mlInd2RGB(im,cMap,cax,alph)
% Usage: mlIndImWrite(im,cMap[,cax,alph])
% 
% Convert matrix to RGB image with supplied colormap. This creates 
% the RGB version of what you would get by calling:
% imagesc(im); colormap(cMap),caxis(cax); 
% 
% Inputs: 
%   im = 2-D matrix to write to file
%   cMap = colormap used for image
%   cax = limits for color axis (defaults to min/max of matrix)
%   alph = separate alpha layer (optional)
% 
% See also mlIndImWrite.m (Same thing, with saving image)
% ML 2013.03

if ~exist('cax','var')
    cax = [min(im(:)),max(im(:))];
end
if ~exist('alph','var')
    alph = 255*ones(size(im),'uint8');
end

[hst,idx] = histc(im,linspace(cax(1),cax(2),257));
RGB = ind2rgb(idx,cMap);
RGB = uint8(255*RGB);
imwrite(RGB,fNm,'alpha',alph)