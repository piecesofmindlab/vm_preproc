function mlIndImWrite(im,cMap,fNm,cax,alph)
% Usage: mlIndImWrite(im,cMap,fNm [,cax,alph])
% 
% Write indexed image to a file. This is essentially the equivalent of
% calling: imagesc(im); colormap(cMap),caxis(cax); (and printing the
% resultant figure)
% 
% Inputs: 
%   im = 2-D matrix to write to file
%   cMap = colormap used for image
%   fNm = output file name
%   cax = limits for color axis (defaults to min/max of matrix)
%   alph = separate alpha layer (optional)
% 
% ML 2012.04

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