function showCurvature(Curv,Params,WhichPlot,Scale,FigH)
% Usage: showCurvature(Curv,Params,WhichPlot,Scale,FigH)
%
% Curv, Params are struct outputs from mlBoundaryCurvatureFromMask.m
% 
% WhichPlot is either 'Dots' or 'Image'
% 
% 'Image' still needs updating.
% 
% Scale = flag to show only one scale
% ML 2011.07.07
% Updated 2012.05
% 
%help PlotMaskCurvature;
%keyboard;

if ~exist('WhichPlot','var')||isempty(WhichPlot)
    WhichPlot = 'Dots'; % Image
end
if ~exist('Scale','var')||isempty(Scale)
    Scale = [];
    FigSz = [6,2.5];
else
    FigSz = [2,2];
end

% % Full image file
% FullImF = fullfile(fDirIm,sprintf('Sc%04d_01.png',Scn));
% if exist(FullImF,'file')
%     [ImFull map alph] = imread(FullImF);
% else
%     ImFull = 255*ones(size(ImMask),'uint8');
% end
if exist('FigH','var')
    FigH = figure(FigH);
else
    FigH = mlFigure([],FigSz);
end
Flag.ShowIm = false;
Flag.ShowMask = false;
% Plotting options
Col = load('MLColors');
% FigSz = [3.5,3.5];
% Color map of 201 values:
% Simple Red to Blue:
%cMap = mlColorMapCreator([0 0 1; .2 .2 .2; 1 0 0],[101 100]);
% Red to Blue w/ intermediate colors:
%cMap = mlColorMapCreator([Col.BlueBright;Col.BlueGreen;50,50,50;Col.RedOrange;Col.RedSat]/255,[50,51,50,50]);
cMap = mlColorMapCreator([Col.CyanSat;Col.BlueBright;50,50,50;Col.RedSat;Col.Pink]/255,[50,51,50,50]);
MaxDotSz = 24;
MinDotSz = 6;

if Flag.ShowIm
    image([1 size(ImFull,2)],[1 size(ImFull,1)],ImFull);
else
    %axis ij
end
if Flag.ShowMask
    image([1 size(imR,2)],[1 size(imR,1)],ImMask);%ImFull);
else
    %axis([1,size(imR,2),1,size(imR,1)]);
    %axis ij
end
K = Curv.K;
X = Curv.X;
Y = Curv.Y;
ImSz = 500; % set as an input!
if Scale
    Pos = [0 0 1 1]; % .8
    ScaleTick = Scale;
else
    Pos = mlTileAxes(1,size(K,2),[0 0 1 .8],1,.05);
    ScaleTick = 1:size(K,2);
end
for iScale = ScaleTick
    Ct = 1;
    switch lower(WhichPlot)
        case 'dots'
            f = ImSz/(Params.ImBinSzPx*Params.Scales(iScale));
            axes('position',Pos(Ct,:));
            axis ij;
            axis([1,500,1,500])
            axis square
            set(gca,'xtick',[],'ytick',[],'box','on')
            for iM = 1:size(K,1)
                K_cIdx = ceil(K{iM,iScale}*100); %% Index K to 100 values for colors for plotting
                cMap_K = cMap(K_cIdx+101,:);
                S = abs(K{iM,iScale})*(MaxDotSz-MinDotSz) + MinDotSz; % normalize K?
                x = X{iM,iScale};
                y = Y{iM,iScale};
                hold on;
                nSzDivs = 8;
                SzDiv = ceil(linspace(MinDotSz,MaxDotSz+1,nSzDivs+1));
                for jj = 1:nSzDivs
                    SzIdx = S>=SzDiv(jj) & S<SzDiv(jj+1);
                    scatter(x(SzIdx)'*f,y(SzIdx)'*f,S(SzIdx),cMap_K(SzIdx,:),'filled');
                end
                hold off
                % Separate color map figure:
                % figure; image(reshape(cMap,[201,1,3]));
                % axis off;
            end
            Ct = Ct+1;
        case 'image'
            axes('position',Pos(Ct,:));
            im = nansum(cat(3,Params.BinIm{:,iScale}),3);
            im = 101+round(im*100);
            im(isnan(im)) = -1.01;
            imagesc([0.5,Params.Scales(iScale)-.5],[0.5,Params.Scales(iScale)-.5],im);
            colormap(cMap);
            caxis([1,201])
            axis image
            hold on;
            for iM = 1:size(K,1)
                x = Curv.X{iM,iScale}/Params.ImBinSzPx;
                y = Curv.Y{iM,iScale}/Params.ImBinSzPx;
                plot(x,y,'w.');
            end;
            axis off;
            hold off;
            if iScale == size(K,2)
                colorbar('ytick',linspace(1,201,5),'yticklabel',linspace(-1,1,5))
            end
            %set(gca,'position',Pos(Ct,:));
            Ct = Ct+1;
    end
end

