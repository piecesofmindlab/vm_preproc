function show_optical_flow(of_im,ij,imcol,qcol)
% Usage: show_optical_flow(of_im,ij,imcol,qcol)
% 
% Show optical flow as a vector field (quiver plot)
% 
%  ij : a 1- or 2-long vector of the number of arrows to display per side
%       of the image (e.g. [10,10] = 10 x 10 quiver arrows
% qcol : color of quiver lines
% 
% 
% ML 2014.03 

% load image
if ischar(of_im)
    of_im = exrread(of_im);
end
if ~exist('ij','var')
    ij = 20;
end
if ~exist('qcol','var')
    qcol = [1,0,0];
end
if length(ij)==1
    ij = [ij,ij];
end
% Get X,Y components of optical flow (??)
x = of_im(:,:,1);
y = of_im(:,:,2); 
sz = size(x);
% 
[ii,jj] = meshgrid(1:floor(sz(1)/ij(1)):sz(1),1:floor(sz(2)/ij(2)):sz(2));

idx = sub2ind(sz,ii(:),jj(:));

x = x(:);
y = y(:);
xx = x(idx);
yy = y(idx);
if exist('imcol','var') && ~isempty(imcol)
    image(imcol);
    axis image off;
end

hold on; 
quiver(jj(:),ii(:),xx,yy,1,'color',qcol); 
hold off;

sz = size(cIm);
xlim([1,sz(2)]);
ylim([1,sz(1)]);

axis off;

%{
f1dir = '/tmp/';
f1x = 'Ses';
f1 = dir([f1dir f1x '*png']);
f1 = fullfile(f1dir,{f1.name}');
f2dir = '/auto/k1/mark/Desktop/BlenderTemp/Motion/';
f2x = 'Ses';
f2 = dir([f2dir f2x '*exr']);
f2 = fullfile(f2dir,{f2.name}');
for ii = 1:50; 
    imshow(f1{ii}); 
    show_optical_flow(f2{ii},24); % 30 is more reasonable; object effect is
                                  % more visible w/ 48
    set(gca,'position',[0,0,1,1]); 
    drawnow; 
end
%}
