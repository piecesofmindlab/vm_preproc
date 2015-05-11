function [fitresult, gof] = gauss2DRotFit(im,fitOpts,plotOpt)
%gauss2DRotFit(im,fop,title)
%  Create a fit.
%  Input :
%   
%      im  : input image of 2D gaussian
%      fop : fitoptions - a structure with 3 fields : Lower,StartPoint and
%            Upper. Each of the fields is an array of 7 values : 
%            offset
%             amplitude of the 2D gaussian
%             centroid X of the 2D gaussian
%             centroid Y of the 2D gaussian
%             angle of rotation for the 2D gaussian
%             width X of the 2D gaussian
%             width Y of the 2D gaussian
%   plotOpt : struct array for plotting options
%               (or, simply true for basic options)
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
% Downloaded from matlab central; modified by ML 2013.04

[sx,sy,sz]=size(im);
if sz==3
    im=rgb2gray(im);
end
[X,Y]=meshgrid(1:sy,1:sx);

if ~exist('plotOpt','var')
    plotOpt.Is_Plot = false;
elseif exist('plotOpt','var') && ~isstruct(plotOpt)
    plotOpt.Is_Plot = plotOpt;
end
 
[xData, yData, zData] = prepareSurfaceData( X,Y, im );

% Set up fittype and options.
ft = fittype( 'a + b*exp(-(((x-c1)*cosd(t1)+(y-c2)*sind(t1))/w1)^2-((-(x-c1)*sind(t1)+(y-c2)*cosd(t1))/w2)^2)',...
    'independent', {'x', 'y'}, 'dependent', 'z' );

opts = fitoptions( ft );
if ~exist('fitOpts','var')||isempty(fitOpts)
    % Reasonable guesses for lower and upper bounds for parameters: 
    [~,xGuess] = max(mean(im,1));
    [~,yGuess] = max(mean(im,2));
    ht = [max(zData(:))/3,max(zData(:))];
    ang = [0,2*pi];
    wid = [2,10];
    pkRange = size(im,1)/3; % within 1/3 of the image width from the max intensity point
    %               offset , height,    x pos     ,     y pos   , angle , x width , y width
    fitOpts.Lower = [-ht(2)/2,ht(1),xGuess-pkRange,yGuess-pkRange,ang(1),wid(1),wid(1)];
    fitOpts.Upper = [ ht(2)/2,ht(2),xGuess+pkRange,yGuess+pkRange,ang(2),wid(2),wid(2)];
    fitOpts.StartPoint = [0,mean(ht),mean(xGuess),mean(yGuess),mean(ang),mean(wid),mean(wid)];
end

% Fill in default opts for nlsqoptions (NOT a normal struct!)
FN = {'Lower','StartPoint','Upper'};
for iFN = 1:length(FN)
    if isfield(fitOpts,FN{iFN})
        opts.(FN{iFN}) = fitOpts.(FN{iFN});
    end
end
%opts = defaultOpt(fitOpts,opts);
    
% Fit model to data.
[fitresult, gof,fout] = fit( [xData, yData], zData, ft, opts );

if plotOpt.Is_Plot
    mystr = 'Gaussian Fit';
    dPlotOpt.title = 'Gaussian Fit';
    plotOpt = defaultOpt(plotOpt,dPlotOpt);
    % Create a figure for the plots.
    fig = figure;
    set(gcf,'Name', '2D Gaussian fit 1' );
    set(gcf,'Position',[10,10,900,600]);
    % Plot fit with data.
    h = plot( fitresult, [xData, yData], double(zData));
    legend( h, plotOpt.title, 'im vs. X, Y',  'Location', 'NorthEast' );
    % Label axes
    xlabel( 'X' );
    ylabel( 'Y' );
    zlabel( 'im' );
    grid on
    colormap(jet);
    % Plot residuals.
    fig2 = figure;
    set(gcf,'Name', 'Gaussian fit Residuals');
    set(gcf,'Position',[100,100,900,600]);
    h = plot( fitresult, [xData, yData], zData, 'Style', 'Residual');
    legend( h, [mystr  ' - residuals'], 'Location', 'NorthEast' );
    % Label axes
    xlabel( 'X' );
    ylabel( 'Y' );
    zlabel( 'im' );
    grid on
    figure(fig);
end

