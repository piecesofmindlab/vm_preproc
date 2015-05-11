function [grad_mag,grad_ori] = compute_gradients(img,pp)

% Usage: [grad_mag,grad_ori] = compute_gradients(img,params)
% 
% Computes oriented gradients across image. 
% 
% For multi-channel images, method for handling multiple channels is set by
% params.ChannelCollapseMethod. Options are: 
%   'max' - max of gradient for all channels
%   % NOT YET 'mean' - mean of gradient for all channels
%   ... More?
% Other param options:
%   .IsSqrt = preprocess image by taking sqrt of each pixel intensity (as
%       Dalal & Triggs did in original HoG paper)
%   .IsLAB = convert image to LAB space before computing gradients
% 
% Returns FULL CIRCLE (360 degrees, in degrees) gradients, with 0 deg 
% meaning Light->Dark from Left->Right
% 
% ML 2012.03.30

% Defaults
params.ChannelCollapseMethod = 'max';
params.IsSqrt = true;
params.IsLAB = false;

if exist('pp','var')
    % Apply inputs
    params = defaultOpt(pp,params);
end
[H W num_channels] = size(img);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 1: Compute oriented gradients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Optional conversion to LAB color space
if params.IsLAB
    warning('LAB seems to mess up image values - it creates complex numbers!! wtf!!')
    keyboard
    img = colorspace('LAB<-RGB',img);
end
% Take sqrt (following Dalal & Triggs)
if params.IsSqrt
    % Sqrt w/ maintained sign, no complex numbers
    im1 = sqrt(abs(single(img))) .* sign(single(img));
else
    im1 = single(img);
end
% Gradients
x_grad = conv2(im1(:,:,1),[ 1 0 -1],'same');
y_grad = conv2(im1(:,:,1),[ 1;0;-1],'same');
% Double up edges (no edge artifacts)
x_grad(:,1) = x_grad(:,2);
x_grad(:,end) = x_grad(:,end-1);
y_grad(1,:) = y_grad(2,:);
y_grad(end,:) = y_grad(end-1,:);

grad_mag = x_grad.^2+y_grad.^2;
grad_ori = atan2(y_grad,x_grad);
switch lower(params.ChannelCollapseMethod)
    case 'max'
        % if image is multichannel, choose the magnitude and orientation of the
        % gradient from the highest grad magnitude channel (following D&T)
        for c=2:num_channels
            x_grad = conv2(im1(:,:,c),[-1 0 1],'same');
            y_grad = conv2(im1(:,:,c),[-1;0;1],'same');
            x_grad(:,1) = x_grad(:,2);
            x_grad(:,end) = x_grad(:,end-1);
            y_grad(1,:) = y_grad(2,:);
            y_grad(end,:) = y_grad(end-1,:);

            gm = x_grad.^2+y_grad.^2;
            ga = atan2(y_grad,x_grad);
            grad_ori(gm>grad_mag) = ga(gm>grad_mag);
            grad_mag = max(grad_mag,gm);     
        end
end
clear ga gm img x_grad y_grad;
grad_mag = sqrt(grad_mag);
%grad_ori = grad_ori*180/pi + 180;
%grad_ori(grad_ori>180) = grad_ori(grad_ori>180)-360;
grad_ori = -(grad_ori-pi)/pi * 180;