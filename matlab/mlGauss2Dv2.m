function Z = mlGauss2Dv2(Sz,sigma,theta,R,A)

% Usage: Z = mlGauss2D(Xgr,Ygr,,muY,sigma [,theta] [,A])
% 
% Generate an image of a 2-d Gaussian function. For ver 2: this will always
% be centered at zero. Boundaries will be 
% 
% Example calls: 
% 
% [Xgr,Ygr] = meshgrid(linspace(-4,4,100),linspace(-4,4,100));
% Gg = mlGauss2D(Xgr,Ygr,-1,2,1.5);
% imagesc(Gg)
% (or better still: )
% surf(Xgr,Ygr,Gg)
% shading interp;
% view(-36,36);
% axis equal;
% 
%
% Ygr = 1/pi/sigma^2*exp(-((Xgr-muX).^2+(Ygr-muY).^2)/sigma^2);

% Inputs
if ~exist('sigma','var')
    sigma = 1;
end
muX = 0;
muY = 0;
if length(Sz)==2
    Sz_X = Sz(1);
    Sz_Y = Sz(2);
elseif length(Sz)==1
    Sz_X = Sz;
    Sz_Y = Sz;
else
    error('You done fucked up your Sz input to mlGauss2Dv2.')
end
if length(sigma)==2
    sigma_x = sigma(1);
    sigma_y = sigma(2);
elseif length(sigma)==1
    sigma_x = sigma;
    sigma_y = sigma;
else
    error('You done fucked up your sigma input to mlGauss2Dv2.')
end
if ~exist('R','var')||isempty(R)
    R = 0;
end
if ~exist('A','var')
    % Set the total area under the curve to 1
    A = 1/(2*pi*sigma_x*sigma_y*sqrt(1-R^2));
end
sigma = max(sigma);
xp = linspace(-3*sigma,3*sigma,Sz_X);
yp = linspace(-3*sigma,3*sigma,Sz_Y);
[Xgr,Ygr] = meshgrid(xp,yp);

% Poached from wikipedia: put in terms of the ANGLE of the gaussian:
% NOTE! the correlation between x and y directly determines this angle: 
% theta = acos(corr(x,y));
if ~exist('theta','var')
    theta = 45;
end
a = cos(theta)^2/2/sigma_x^2 + sin(theta)^2/2/sigma_y^2;
b = -sin(2*theta)/4/sigma_x^2 + sin(2*theta)/4/sigma_y^2;
c = sin(theta)^2/2/sigma_x^2 + cos(theta)^2/2/sigma_y^2;
Z = A*exp( - (a*(Xgr-muX).^2 + 2*b*(Xgr-muX).*(Ygr-muY) + c*(Ygr-muY).^2)) ;

% C = -1 / (2*(1-R^2));
% Z = A * exp( C * (...
%     (Xgr-muX).^2 / sigma_x^2 + ...
%     (Ygr-muY).^2 / sigma_y^2 - ...
%     2*R*(Xgr-muX).*(Ygr-muY) / (sigma_x*sigma_y)...
%     ));

%Ygr = A.*exp(-( a*Xgr.^2 + 2*b*Xgr.*Ygr +c*Ygr.^2 ))

%Ygr = A * exp(-((x-muX).^2+(y-muY).^2)/sigma^2);