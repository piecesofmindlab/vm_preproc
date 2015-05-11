function [grad_mag,grad_ori] = compute_normalGradients(Normals,params)
% Usage: [grad_mag,grad_ori] = compute_normalGradients(Normals,params)
% 
% Computes distances between normals in a pixelwise normal image.
% Differences between normal vectors are expressed as the average of the
% cosines of the angles between normals of adjacent pixels. X and Y
% directional gradients are computed, in a way analogous to the HoG
% (histogram of gradients) algorithm, but this function subtracts the full
% 3D-vectors instead of 1-D pixel values. 
% 
% ML 2012.11.30, updated 2013.04.08

dparams.method = 'max';
dparams.nonLinExp = 1; % raise whole image to this power (to adjust contrast)
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dparams);
% X derivative first. [-1,0,1]. so: subtract LEFT-shifted image, add RIGHT
% shifted image
nL = Normals(:,1:end-2,:); % normals, LEFT 
nC = Normals(:,2:end-1,:); % normals, CENTER
nR = Normals(:,3:end-0,:); % normals, RIGHT
dx1 = acos(sum(nL.*nC,3));
dx2 = acos(sum(nR.*nC,3));
% Y derivative. 
nT = Normals(1:end-2,:,:); % n, TOP
nM = Normals(2:end-1,:,:); % n, MIDDLE
nB = Normals(3:end-0,:,:); % n, BOTTOM
dy1 = acos(sum(nT.*nM,3));
dy2 = acos(sum(nB.*nM,3));
% Take average of two gradients (e.g. center-left/center-right)
switch params.method
    case 'add'
        % average.
        x_grad = real([zeros(size(dx1,1),1),(dx1+dx2)/2,zeros(size(dx1,1),1)]);
        y_grad = real([zeros(1,size(dy1,2));(dy1+dy2)/2;zeros(1,size(dy1,2))]);
    case 'max'
        % This ends up being the same... left here for backward
        % compatibility of code
        x_gradP = real([zeros(size(dx1,1),1),(dx1+dx2)/2,zeros(size(dx1,1),1)]);
        x_gradN = real([zeros(size(dx1,1),1),(dx1-dx2)/2,zeros(size(dx1,1),1)]);
        y_gradP = real([zeros(1,size(dy1,2));(dy1+dy2)/2;zeros(1,size(dy1,2))]);
        y_gradN = real([zeros(1,size(dy1,2));(dy1-dy2)/2;zeros(1,size(dy1,2))]);
        x_grad = max(abs(x_gradP),abs(x_gradN));
        y_grad = max(abs(y_gradP),abs(y_gradN));
end
% Double up edges (no edge artifacts)
x_grad(:,1) = x_grad(:,2);
x_grad(:,end) = x_grad(:,end-1);
y_grad(1,:) = y_grad(2,:);
y_grad(end,:) = y_grad(end-1,:);

grad_mag = x_grad.^2+y_grad.^2;
grad_ori = atan2(y_grad,x_grad);
