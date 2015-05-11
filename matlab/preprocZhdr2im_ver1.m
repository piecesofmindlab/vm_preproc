function im = preprocZhdr2im(Z,ImSz)
% Usage: 
% 
% Takes HDR image as input (either string or image read in with "hdrread")
% and outputs a single precision image at size [ImSz(1) x ImSz(2) x 1]
% 
% Normalized z depth from a potentially large range to 0-1. TODO: More
% options!
%
% ML 2012.01.10

% Inputs
if ischar(Z)
    Z = hdrread(Z);
end
if ndims(Z)==3
    Z = Z(:,:,1);
end
if ~exist('ImSz','var')
    ImSz = size(Z);
end
if numel(ImSz)==1
    ImSz = [ImSz,ImSz];
end

% Other options:
MaxDst = 100;

ToFix = Z>MaxDst | Z<0;
if any(ToFix(:));
    % Remove extreme Z values (gaps btw sky/floor that reveal
    % infinite depth)
    Z = medfilt2(Z,[5,5]);
    ToFix2 = Z>MaxDst | Z<=0;
    if any(ToFix2(:));
        % Basic matlab median filter did not completely work;
        % so implement slightly fancier median filter,
        % point-by-point.
        %keyboard
        fixIdx = find(ToFix2(:));
        for iFix = 1:length(fixIdx)
            qj = false;
            qjSz = 5;
            while ~any(qj(:))
                % Assure that qj contains some
                if qjSz>5 && false % for debugging - this works.
                    fprintf('using larger filter for image %d\n',iIm)
                end
                qi = zeros(size(ToFix));
                qi(fixIdx(iFix)) = 1;
                mm = ones(qjSz);
                qj = conv2(qi,mm,'same');
                qi = logical(qi);
                qj = logical(qj);
                qj(ToFix2) = false;
                qjSz = qjSz+2; % increment to bigger median filters if the first doesn't work.
            end
            Z(qi) = median(Z(qj));
        end
        ToFix3 = Z>MaxDst | Z<=0 | isnan(Z);
        if any(ToFix3(:)) && false % this never came up in Validation images... so, go with it.
            keyboard
        end
    end
end
% Normalize?? Is this really going to do anything?
Z = Z/MaxDst; % By a reasonable maximum depth...
im = single(imresize(Z,ImSz));
