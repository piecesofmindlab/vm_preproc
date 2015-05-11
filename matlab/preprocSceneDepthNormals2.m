function varargout = preprocSceneDepthNormals(S,params)
% Usage: [[Spreproc,] params] = preprocSceneDepthNormals(S,params)
% 
% Preprocesses normals and depth in a scene in (real, 3D) coordinates.
% 
% Inputs: 
% S = struct array with fields 
%   .Zdepth
%   .Normals
%   .CamVector
%  * Each filed can be a large matrix of many concatenated frames of
%    stimuli, or a string specifying a file to be loaded
%  * The 3rd (zdepth),4th (normals),and 2nd (camVector) dimension of
%    matrices in / specified by each file (or set of files) should be equal
% 
% params = parameter struct array, with fields:
%   .HorizDiv : an array of values horizontal (x) bin edges into which to
%       divide the visual field horizontally (0-1)
%   .DepthDiv : an array of values that specify the bin edges of depth bins
%       (FAR boundaries of divisions)
%   .normBinCenters : matrix of basis normals
%   % Options for how to modify normals
%   .normParams : struct for whether/how to modify normals based on camera
%       position, w/ fields:
%       .removeComponent = [1,0,0]; % remove x rotation ("nod" of camera) - this makes them abs. w.r.t. gravity
%       .Is_Normalize = true; % doesn't really matter, but assure that normals are re-set to 1
%  
% ML 2012.11.11
% Updated 2013.06.07

%%% --- Parameters --- %%%
pDefault.class = 'preprocSceneDepthNormals2';
pDefault.depthNormalize = false; % true may be better; false to not break legacy code
nHorizDivs = 1;
pDefault.HorizDiv = linspace(0,1,nHorizDivs+1);
pDefault.HorizDiv(end) = inf;
nVertDivs = 1;
pDefault.VertDiv = linspace(0,1,nVertDivs+1);
pDefault.VertDiv(end) = inf;
pDefault.ori_norm = 2; % for legacy code; 1 is actually preferred
% check on histograms of depth across scenes to verify that 
% (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
nDepthDivs = 5;
d = logspace(log10(1),log10(100),nDepthDivs);
pDefault.DepthDiv = [0,d(1:end-1),inf]; 
% multiple options for how to do this? scale by max depth? or fix for all
% scenes?
pDefault.normBinCenters = [-1 0 0;  0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
                     -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
                      0,0,1]; % straight-ahead
% Options for how to modify normals
pDefault.normParams.removeComponent = [1,0,0]; % remove x rotation ("nod" of camera) - this makes them abs. w.r.t. gravity
pDefault.normParams.Is_Normalize = true; % doesn't really matter, but assure that normals are re-set to 1
%pDefault.normalize = true;
if ~exist('params','var')
    params = struct();
end

if exist('params','var') && ~isnumeric(params)
    params = defaultOpt(params,pDefault);
elseif exist('params','var') && isnumeric(params)
    params = preprocSceneDepthNormals_GetMetaParams(params);
end

%%% Computed parameters
params.nNormBins = size(params.normBinCenters,1);
% Normalize bin vectors 
L = sqrt(sum(params.normBinCenters.^2,2));
params.normBinCenters = bsxfun(@rdivide,params.normBinCenters,L);
params.nNormBins = size(params.normBinCenters,1);
% Note, that the bin width for these bins will not be well-defined (or,
% will not be uniform). For now, take the average min angle between bins 
if params.nNormBins==1
    % d = 90;%Normals can't deviate by more than 90 deg (unless they're un-
    % rotated) BUT: We don't actually want to soft bin if there is only one 
    % normal, we want to assign ALL pixels EQUALLY to the ONE BIN... 
    % Thus d = inf?
    d = inf;
else
    d = acosd(params.normBinCenters * params.normBinCenters');
    d(abs(d)<.00001) = nan;
end
params.normBinWidth = mean(nanmin(d)); % Add an extra buffer to this? We 
  % don't want "stray" pixels with normals that don't fall into any bin
  % (but we also don't want to double-count pixels) 

if ~nargin
    varargout{1} = params;
    return
end
% Read in stimuli
Sf = fieldnames(S);
for iS = 1:length(Sf)
    if strcmpi(Sf{iS}(1),'z')
        zVar = Sf{iS};
    end
    % This needs three kinds of files: depth, normals, and camera angle
    % Depth and normals are stored in concatenated image matrices;
    % camera angle is stored in a [frames x 3] matrix
    % All should be stored as a variable named "S" in their respective
    % files if file names are provided.
    ss = Sf{iS};
    if ischar(S.(ss)); 
        tmp = load(S.(ss));
        S.(ss) = tmp.S;
    end
end
disp('Done with stim file set-up: check!')
% Optionaly remove any camera rotations 
if any(params.normParams.removeComponent)
    % Does nothing if params.normParams.removeComponent == [0,0,0]
    S.Normals = preprocRmRotNormals(S.Normals,-S.CameraAngles,params.normParams);
end
% Get number of images
[x,y,nIms] = size(S.(zVar));
nDims = (length(params.HorizDiv)-1)*(length(params.VertDiv)-1)*(length(params.DepthDiv)-1)*size(params.normBinCenters,1);
Spreproc = nan(nIms,nDims);
for iS = 1:nIms
    if nIms>200
        progressdot(iS,200,2000,nIms)
    elseif nIms < 200 && nIms > 1
        disp('computing Scene Depth Normals...')
    end
    % Pull single image for preprocessing
    %%% --- Grab (nth) of each input type --- %%%
    z = S.(zVar)(:,:,iS);
    n = S.Normals(:,:,:,iS);
    [H,W,nd] = size(n);
    nr = reshape(n,H*W,nd);
    [xx,yy] = meshgrid(linspace(0,1,W),linspace(0,1,H));
    idx = 1:params.nNormBins;
    for iD = 1:length(params.DepthDiv)-1
        dIdx = z>=params.DepthDiv(iD) & z<params.DepthDiv(iD+1);
        for iH = 1:length(params.HorizDiv)-1
            hIdx = xx>=params.HorizDiv(iH) & xx<params.HorizDiv(iH+1);
            for iV = 1:length(params.VertDiv)-1
                vIdx = yy>=params.VertDiv(iV) & yy<params.VertDiv(iV+1);
                tileDepthCount = mean(dIdx(:) & hIdx(:) & vIdx(:));
                if params.nNormBins>1
                    nn = nr(dIdx(:) & hIdx(:) & vIdx(:),:);
                    % Compute orientation of pixelwise surface normals relative
                    % to all normal bins
                    o = nn * params.normBinCenters';
                    Lb = sqrt(sum(nn.^2,2));
                    o = bsxfun(@rdivide,o,Lb); % Norm of params.normBinCenters should be 1
                    angles = acosd(o);
                    % The following is a "soft" histogramming of normals. I.e., if a given
                    % normal falls partway between two normal bins, it is partially
                    % assigned to each of the nearest bins (not exclusively to one).
                    SppTmp = max(0,params.normBinWidth-angles)/params.normBinWidth;
                    % Sum over all pixels w/ depth in this range
                    SppTmp = sum(SppTmp,1);
                    % Normalize across different normalorientation bins
                    SppTmp = SppTmp/norm(SppTmp,params.ori_norm); % ori_norm=1 = L1 (max), 2 = L2 (Euclidean)
                else
                    % Special case: one single normal bin
                    % compute the fraction of screen pixels in this screen 
                    % tile at this depth
                    SppTmp = tileDepthCount;
                end
                % Illegal for more than two bins of normals within the same
                % depth / horiz/vert tile to be == 1
                if sum(SppTmp==1)>1
                    error('Found two separate normal bins equal to 1 - that should be impossible!');
                end
                if params.depthNormalize && ~(params.nNormBins==1)
                    % normalize normals by n pixels at this depth/screen tile
                    SppTmp = SppTmp*tileDepthCount;
                end
                Spreproc(iS,idx) = SppTmp;
                idx = idx+params.nNormBins;
            end
        end
    end

end
Spreproc(isnan(Spreproc)) = 0;
clear S;
% All done!
% (Return Spreproc, save elsewhere)
varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end