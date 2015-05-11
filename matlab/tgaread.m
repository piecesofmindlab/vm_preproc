function im = tgaread(fname)

fid = fopen(fname,'rb');

tmp = fread(fid);

tmp = tmp(19:end);

RGB = reshape(tmp,[ 3 length(tmp)/3]);

Sx = round( sqrt(size(tmp)/3) );

im(:,:,3) = reshape(RGB(1,:),[Sx Sx]); im(:,:,3) = im(:,:,3)';
im(:,:,2) = reshape(RGB(2,:),[Sx Sx]); im(:,:,2) = im(:,:,2)';
im(:,:,1) = reshape(RGB(3,:),[Sx Sx]); im(:,:,1) = im(:,:,1)';

im = flipdim(im,1);
%im = uint8(im);

return