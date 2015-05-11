function params = computeProjected3DCurvatureParams(params)
% Usage: params = computeProjected3DCurvatureParams(params)
% 
% Computes the following PC parameters from other parameters provided: 
% params.PCparams.Xc % x coordinates of bin centers (normalized 0-1)
% params.PCparams.Yc % y coordinates of bin centers (normalized 0-1)
% params.PCparams.Sz % size of each individual bin (in proportion of screen)
% params.PCparams.Ori % orientation of each PC channel (in degrees)
% 
% params.oBinWidth
% params.oBinCenters
% 
% params.nPCdims
%
% If any of these fields exist, they are over-written by a call to this
% function! WARNING: this can cause irritating bugs if you're not careful.
% 
% ML 2012.07.27

params.oBinWidth=params.oMax/params.nOriBins;
% Can be specified independently, or can be computed from simpler params:
% NOTE: We may want to specify non-uniformly spaced bins in the future,
% but for now this is too big a pain in my ass. So we're leaving it
% this way, enforcing evenly-spaced bins. ML 2012.08.02
params.oBinCenters = 0:params.oBinWidth:(params.oMax-params.oBinWidth);
% Centers of spatial bins/channels
params.PCparams = struct('Xc',[],'Yc',[],'Sz',[],'Ori',[]);

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
    if isempty(params.PC_Norm_Area);
        nSurr = 1;
    else
        switch lower(params.PC_Norm_Area{1})
            case 'centersurround'
                nSurr = 1;
            case 'corners'
                nSurr = 4;
            otherwise
                error('unknown surround specification in PC params!')
        end
    end
    PCp = {'Xc','Yc','Sz','Ori'};
    for iPCp = 1:4;
        X = PCp{iPCp};
        eval([X ' = repmat(' X '(:),nSurr,1);']);
        params.PCparams.(X) = [params.PCparams.(X);eval(X)];
    end
end

nRect = params.rectify + 1;
nCurvDirs = params.separateCurvDir + 1;
if params.binCurvature
    nCurvBin = length(params.binCenters);
else
    nCurvBin = 1;
end
if ~isempty(params.PC_Norm_Area) && strcmpi(params.PC_Norm_Area{1},'corners')
    nSurr = 4;
else
    nSurr = 1;
end

params.nChannels = sum((params.nSpatBins.^2) * params.nSubBins * params.nOriBins * nRect * nCurvBin * nSurr * nCurvDirs);
params.nPCdims = params.nSubBins * params.nOriBins * nRect * nCurvBin * nSurr * nCurvDirs; 
