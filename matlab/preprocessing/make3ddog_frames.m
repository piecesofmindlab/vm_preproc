function [gabor, gabor90, scweights] = make3ddog_frames(xytsize, params)

%function [gabor, gabor90] = make3dgabor(xytsize, params)
% 
%   returns a gabor functions of size X-by-Y-by-T, specified by a vector PARAMS.
%
% INPUT:
%     [xytsize] = vector of x, y, and t size, i.e. [64 64 5]
% [params(1:2)] = center_x, center_y
%                 The spatial center of the Gabor function. The axes are normalized
%                 to 0 (lower left corner) to 1(upper right corner).
%                 e.g., [0.5 0.5] put the Gabor at the center of the matrix.
%   [params(3)] = The direction of the Gabor function in degree (0-360).
% [params(4:5)] = Spatial frequency and temporal frequency
%                 They determine how many cycles in XYTSIZE pixels for each dimension.
% [params(6:7)] = Spatial and Temporal envelope size in standard deviation
%   [params(8)] = Phase of the Gabor function (optional, default is 0)
%
% OUTPUT:
%       [gabor] = a gabor function of size X-by-Y-by-T, specified by a vector PARAMS.
%     [gabor90] = the quadrature pair Gabor function
%

cx = params(1);
cy = params(2);
dir = params(3);
sf = params(4);
tf = params(5);
senv = params(6);
tenv = params(7);
if length(params)>7
	phase = params(8)*pi/180;
else
	phase = 0;
end

if dir<0
  tf = -tf;
end

dir = 0; % this is a DOG so dir is invalid.

dx = 0:(1/(xytsize(1)-1)):1;
dy = 0:(1/(xytsize(2)-1)):1;

if length(xytsize) >= 3 && xytsize(3)>1
	dt = 0:(1/(xytsize(3))):1;
    dt = dt(1:end-1);
else  % only 1 time slice
	xytsize(3) = 1;
	dt = 0.5;
end

dx = single(dx);
dy = single(dy);
dt = single(dt);

% [iy ix it] = ndgrid(dx, dy, dt);
% 
% gauss = exp( - ((ix-cx).^2+(iy-cy).^2)/(2*senv^2) - (it-0.5).^2/(2*tenv^2)  );

fx = -sf*cos(dir/180*pi)*2*pi;
fy = sf*sin(dir/180*pi)*2*pi;
ft = real(tf)*2*pi;

% grat = sin( (ix-cx)*fx + (iy-cy)*fy + (it-0.5)*ft + phase);
% grat90 = cos( (ix-cx)*fx + (iy-cy)*fy + (it-0.5)*ft + phase);

% calc a frame and parameters
[iys ixs its] = ndgrid(dx,dy,1);

g_slice = exp( - ((ixs-cx).^2+(iys-cy).^2)/(2*senv^2) );


grat_s = sin( sqrt((ixs-cx).^2 + (iys-cy).^2)*fx + phase);
grat90_s = cos( sqrt((ixs-cx).^2 + (iys-cy).^2)*fx + phase);

%grat_s = sin( (ixs-cx)*fx + (iys-cy)*fy + phase);
%grat90_s = cos( (ixs-cx)*fx + (iys-cy)*fy + phase);

gs_slice = g_slice.*grat_s;
gc_slice = g_slice.*grat90_s;

env_t = exp(-(dt-0.5).^2/(2*tenv^2));
if imag(tf)
  gs_t = sin( (dt-0.5)*ft ) + sin( (dt-0.5)*(-ft) );
  gc_t = cos( (dt-0.5)*ft ) + cos( (dt-0.5)*(-ft) );
else
  gs_t = sin( (dt-0.5)*ft );
  gc_t = cos( (dt-0.5)*ft );
end
scweights = [env_t.*gs_t; env_t.*gc_t];


gabor = gs_slice;
gabor90 = gc_slice;

% gabor = gauss.*grat;
% gabor90 = gauss.*grat90;
% 
% gabor = single(gabor);
% gabor90 = single(gabor90);

