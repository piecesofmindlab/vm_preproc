function params = computeHoGparams(params)
% Computes the following HoG parameters from other parameters provided: 
% params.HoGparams.Xc % x coordinates of bin centers (normalized 0-1)
% params.HoGparams.Yc % y coordinates of bin centers (normalized 0-1)
% params.HoGparams.Sz % size of each individual bin (in proportion of screen)
% params.HoGparams.Ori % orientation of each HoG channel (in degrees)
% 
% params.oBinWidth
% params.oBinCenters
% 
% params.nHoGdims
% 
% ML 2012.07.27


params.oBinWidth=params.oMax/params.nOriBins;
%if ~isfield(params,'oBinCenters')
    % Can be specified independently, or can be computed from simpler params:
    % NOTE: We may want to specify non-uniformly spaced bins in the future,
    % but for now this is too big a pain in my ass. So we're leaving it
    % this way, enforcing evenly-spaced bins. ML 2012.08.02
    params.oBinCenters = 0:params.oBinWidth:(params.oMax-params.oBinWidth);
%else
    % ?do something?
%end
params.HoGparams = struct('Xc',[],'Yc',[],'Sz',[],'Ori',[]);

for iScale = 1:length(params.nSpatBins)
    
    H = params.pxPerBin * params.nSpatBins(iScale)+2;
    W = H; % Assumes square images!
    binSz = H / params.nSpatBins(iScale);
    if binSz == floor(binSz)
        %always allow room at edges
        binSz = binSz-1; 
    end
    nSubBins = [params.nSubBins,params.nSubBins];
    binSz = floor(binSz);    
    binDims = [binSz,binSz];
    bandwidth = binDims ./ nSubBins; % width of each spatial cell
    num_cells = [params.nSpatBins,params.nSpatBins]; %floor(([W H]-2)./bandwidth(1:2)) - nSubBins(1:2)+1;
    samples_x = (0:(num_cells(1)-1))*bandwidth(1);
    samples_y = (0:(num_cells(2)-1))*bandwidth(2);
    % Add offset to prevent bins from being exactly at image edges:
    offset = floor(([W H] - [samples_x(end) samples_y(end)] - binDims(1:2))/2);
    samples_x=samples_x+offset(1);
    samples_y=samples_y+offset(2);
    % store bin locations, as % of space across image:
    
    [Xc,Yc] = meshgrid(samples_x+binSz/2,samples_y+binSz/2);
    Xc = repmat(Xc(:),params.nOriBins,1) / W;
    Yc = repmat(Yc(:),params.nOriBins,1) / H;
    Ori = repmat(params.oBinCenters,params.nSpatBins(iScale)^2,1);
    Sz = repmat(1/params.nSpatBins(iScale),length(Xc),1);
    if isempty(params.HoG_Norm_Area);
        nSurr = 1;
    else
        switch lower(params.HoG_Norm_Area{1})
            case 'centersurround'
                nSurr = 1;
            case 'corners'
                nSurr = 4;
            otherwise
                error('unknown surround specification in HoG params!')
        end
    end
    HoGp = {'Xc','Yc','Sz','Ori'};
    for iHoGp = 1:4;
        X = HoGp{iHoGp};
        eval([X ' = repmat(' X '(:),nSurr,1);']);
        params.HoGparams.(X) = [params.HoGparams.(X);eval(X)];
    end
end
params.nHoGdims = sum((params.nSpatBins.^2)*params.nSubBins*params.nOriBins*nSurr);



%%% ---  Old: --- %%%
% 
% params.oBinWidth=params.oMax/params.nOriBins;
% if ~isfield(params,'oBinCenters')
%     % Can be specified independently, or can be computed from simpler params:
%     params.oBinCenters = 0:params.oBinWidth:(params.oMax-params.oBinWidth);
% else
%     % ?do something?
% end
% params.HoGparams = struct('Xc',[],'Yc',[],'Sz',[],'Ori',[]);
% for iScale = 1:length(params.nSpatBins)
%     pos = ((1:params.nSpatBins(iScale))-.5)/params.nSpatBins(iScale);
%     [Xc,Yc] = meshgrid(pos,pos);
%     Xc = repmat(Xc(:),params.nOriBins,1);
%     Yc = repmat(Yc(:),params.nOriBins,1);
%     Ori = repmat(params.oBinCenters,params.nSpatBins(iScale)^2,1);
%     Sz = repmat(1/params.nSpatBins(iScale),length(Xc),1);
%     if isempty(params.HoG_Norm_Area);
%         nSurr = 1;
%     else
%         switch lower(params.HoG_Norm_Area{1})
%             case 'centersurround'
%                 nSurr = 1;
%             case 'corners'
%                 nSurr = 4;
%             otherwise
%                 error('unknown surround specification in HoG params!')
%         end
%     end
%     HoGp = {'Xc','Yc','Sz','Ori'};
%     for iHoGp = 1:4;
%         X = HoGp{iHoGp};
%         eval([X ' = repmat(' X '(:),nSurr,1);']);
%         params.HoGparams.(X) = [params.HoGparams.(X);eval(X)];
%     end
% end
% params.nHoGdims = sum((params.nSpatBins.^2)*params.nSubBins*params.nOriBins*nSurr);
% end