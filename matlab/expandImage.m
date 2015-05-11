function imOut = expandImage(im,margin,newSz,mode)
% Usage: expandImage(im,margin,newSz)
% 
% Expands an image to fill a larger boundary 
% 
% margin is [L,R,T,B];
% 
% ML 2013.06.08

warning('will be deprecated REAL SOON! See matlab function padarray.m')
if length(margin)==1
    margin = repmat(margin,1,4);
end

top = im(1,:);
bot = im(end,:);
lt = im(:,1);
rt = im(:,end);

q = num2cell(margin);
[L,R,T,B] = q{:};

imOut = [repmat(top(1),T,L),repmat(top,T,1),repmat(top(end),T,R);
         repmat(lt,1,L),     im,             repmat(rt,1,R);
         repmat(bot(1),B,L),repmat(bot,B,1),repmat(bot(end),B,R)];

if exist('newSz','var') && ~isempty(newSz)
    imOut = imresize(imOut,newSz); % Method??
end
    