function showProjectedCurvature(X,Y,Ang,Value,params,ax)
% Usage: showProjectedCurvature(X,Y,Ang,Value,params,ax)
%
% Display of PC (Projected Curvature) feature vectors
% Usage: ShowHoG(PC,params,ax=None,overlay=False,sName=None,MaxVal=None,plotDots=False)
%
% Display a Histogram of Gradients.
%
% Order of orintations in input "ori" determines which order of plotting of the
% orientations. Make sure this matches with whatever PC you input...
%
% Will save figure if "sName" is provided, or will display otherwise.
%
% ML 2012.02.02


% Defaults
pDefault.MaxVal = nan;
pDefault.b = nan; % 1/2 length of each individual "edge"
pDefault.lw = 2; % linewidth
pDefault.cMap = mlColorMapCreator([0 0 .8;1 1 1;.8,.05,.05],[128,128]);
if ~exist('params','var')||isempty(params)
    params = struct;
end
if ~exist('ax','var')
    ax = gca;
end
Ang = Ang(:);
Value = Value(:);
% Fill in default values
params = defaultOpt(params,pDefault);

if isnan(params.MaxVal)
    params.MaxVal = max(abs(Value));
end
if isnan(params.b)
    params.b = range(X(:)) / size(X,1)/2;
end
X = X(:);
Y = Y(:);

dX = cosd(Ang(:))*params.b;
dY = sind(Ang(:))*params.b; 
% Set up colormap for "Value" values
AbsVal = abs(Value);
AbsVal256 = round(AbsVal/params.MaxVal * 127);
AbsVal256 = AbsVal256.*sign(Value)+128;
col = params.cMap(AbsVal256,:);

% Set up axis
axes(ax)
set(ax,'colororder',col);
hold on; 
plot([X+dX,X-dX]',[Y+dY,Y-dY]','-','linewidth',params.lw); 
hold off;
axis square equal;
