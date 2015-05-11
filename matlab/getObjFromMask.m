function obj = getObjFromMask(img,objSz,marginSz,WindowMode)
% Usage; obj = getObjFromMask(img,objSz,marginSz,WindowMode)
% 
% Gets a re-sized image of an object out of an image, given an object mask.
%
% Inputs: 
%   img = a string file name, cell array of string file names, mask matrix,
%       or cell array of mask/image matrices
%   objSz = size of maximum dimension of the re-sized image (default = 72).
%       If set to nan, will not resize the object image at all 
%   marginSz = amount of buffer around image; whole numbers will be
%       interpreted as pixels (in original image space), decimals (<1) will
%       be interpreted as fractions of the object in each dimension
%   WindowMode = string determining how to compute the window bounding each
%       object. 
%       'bbCenter' -> do nothing to cutout image; return cutout rectangle
%           at its original aspect ratio
%       'bbCenterSquare' -> add pads to sides / top/bottom of image to
%           maintain original object aspect ratio w/ square output 
%       'bbCenterStretch' -> stretch object (vert. or horiz.) to return
%           square output image
% 

if ~exist('objSz','var')||isempty(objSz)
    objSz = 72;
end
if ~exist('marginSz','var')||isempty(marginSz)
    marginSz = .05;
end
if ~exist('WindowMode','var')
    WindowMode = 'keepsquare';
end

mThresh = .02;

if ~iscell(img)
    img = {img};
end
% First - mask
if ischar(img{1})
    maskIm = imread(img{1});
else
    maskIm = img{1};
end
maskIm = double(maskIm(:,:,1))/255; % 
% Second (optionally) - mask 2nd input with first
if length(img)>1
    if ischar(img{2})
        toMask = imread(img{2});
    else
        toMask = img{2};
    end
    im = bsxfun(@times,maskIm,toMask);
else
    im = maskIm;
end

maskBin = maskIm>mThresh; % binary mask
[y,x] = find(maskBin);
yB = [min(y),max(y)];
xB = [min(x),max(x)];
h = range(yB);
w = range(xB);
if marginSz<1
    % if marginSz is given as a %
    marginSz = max(round([h*marginSz,w*marginSz]));
end
yB = [max(min(y)-marginSz,1),min(max(y)+marginSz,size(maskIm,1))];
xB = [max(min(x)-marginSz,1),min(max(x)+marginSz,size(maskIm,2))];
% Window around object
imW = im(yB(1):yB(2),xB(1):xB(2),:);
wSz = size(imW);

switch WindowMode
    case 'bbCenter'
        [~,mnIdx] = min(wSz);
        ImSz = [objSz,objSz];
        ImSz(mnIdx) = nan;
    case 'bbCenterSquare'
        if wSz(1)>wSz(2)
            add = [floor((wSz(1)-wSz(2))/2),ceil((wSz(1)-wSz(2))/2)];
            imW = [zeros(wSz(1),add(1)),imW,zeros(wSz(1),add(2))];
        elseif wSz(2)>wSz(1)
            add = [floor((wSz(2)-wSz(1))/2),ceil((wSz(2)-wSz(1))/2)];
            imW = [zeros(add(1),wSz(2));imW;zeros(add(2),wSz(2))];
        end
        ImSz = [objSz,objSz];
    case 'bbStretchSquare'
        ImSz = [objSz,objSz];
        
end

if ~isnan(objSz)
    obj = imresize(imW,ImSz);
else
    obj = imW;
end