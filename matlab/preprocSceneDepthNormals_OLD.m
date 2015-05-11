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
%  stimuli, or a string specifying 
%  3rd,4th,and 2nd dimension of matrices in / specified by each file (or
%  set of files) should be equal.  
% params = parameter struct array, with fields:
%   .HorizDiv : an array of values horizontal (x) bin edges into which to
%       divide the visual field horizontally (0-1)
%   .DepthDiv : an array of values that specify the bin edges of depth bins
%       (FAR boundaries of divisions)
%   .normalize = zscore or not 
% 
% ML 2012.11.11


%%% --- Parameters --- %%%
pDefault.class = 'preprocSceneDepthNormals';
nHorizDivs = 1;
pDefault.HorizDiv = linspace(0,1,nHorizDivs+1);
pDefault.HorizDiv(end) = inf;
nVertDivs = 1;
pDefault.VertDiv = linspace(0,1,nVertDivs+1);
pDefault.VertDiv(end) = inf;
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
pDefault.normalize = true;
if ~exist('params','var')
    params = struct();
end

if exist('params','var') && ~isnumeric(params)
    params = mlFillStruct(params,pDefault,true);
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
d = acosd(params.normBinCenters * params.normBinCenters');
d(abs(d)<.00001) = nan;
params.normBinWidth = mean(nanmin(d)); % Add an extra buffer to this? We 
  % don't want "stray" pixels with normals that don't fall into any bin
  % (but we also don't want to double-count pixels) 

  
if ~nargin
    varargout{1} = params;
    return
end
% Read in stimuli
Sf = {'Normals','Zdepth','CamAngle'};
for iS = 1:length(Sf)
    ss = Sf{iS};
    if ischar(S.(ss)); 
        fDir = fileparts(S.(ss));
        stimF = dir(S.(ss));
        Ss.(ss) = mlAddToCell({stimF.name}',[fDir filesep],true);
        % This needs three kinds of files: depth, normals, and camera angle
        % Depth and normals are stored in concatenated image matrices;
        % camera angle is stored in a [frames x 3] matrix
        if iS == 1
            nParts = length(Ss.(ss));
        else
            if length(Ss.(ss))~=nParts
                error('unequal number of subdivisions of stimulus matrix! (nParts not equal for all)')
            end
        end
    elseif isnumeric(S.(ss))
        nParts = 1;
    else
        error('WTF did you give me as a stimulus? I was expecting a string or a numeric matrix.')
    end
    
end
disp('Done with stim file set-up: check!')

% Is_SkipPart1 = false;
% if isfield(params,'fInfo')
%     % fInfo is information particular to this parameter preset and this
%     % particular run (Training / Validation, session #, pixels for images)
%     sName = sprintf('%sSceneDepthNormals_%dpx_%s_Ses%d_%s_%02d.mat',params.fInfo.iDir,params.fInfo.nPixels,params.fInfo.ImType,params.fInfo.Ses,params.fInfo.TrnVal,params.metaparams.preset(1));
%     if exist(sName,'file')
%         load(sName,'Spreproc') % Loads Spreproc variable
%         Is_SkipPart1 = true;
%     end
% end
% Prep for scene depth/normal computation:
%SpBins = params.nSpatBins;
%if ~Is_SkipPart1
SppAll = [];
%for iPart = 1:nParts
%     if exist('Ss','var')
%         S.Zdepth = load(Ss.Zdepth{iPart},'S');
%         S.Zdepth = S.Zdepth.S;
%         S.Normals = load(Ss.Normals{iPart},'S');
%         S.Normals = S.Normals.S;
%         S.CamAngle = load(Ss.CamAngle{iPart},'CamAngle');
%         S.CamAngle = S.CamAngle.CamAngle;
%     end
% potentially, remove any camera rotations...
%keyboard;
S.Normals = preprocRmRotNormals(S.Normals,-S.CamAngle,params.normParams);
% Get number of images
[x,y,nIms] = size(S.Zdepth);
nDims = (length(params.HorizDiv)-1)*(length(params.VertDiv)-1)*(length(params.DepthDiv)-1)*length(params.normBinCenters);
Spreproc = nan(nIms,nDims);
for iS = 1:nIms
    if nIms>200
        progressdot(iS,200,2000,nIms)
    elseif nIms < 200 && nIms > 1
        disp('computing Scene Depth Normals...')
    end
    % Pull single image for preprocessing
    %%% --- Grab (nth) of each input type --- %%%
    z = S.Zdepth(:,:,iS);
    n = S.Normals(:,:,:,iS);
    [H,W,nd] = size(n);
    nr = reshape(n,H*W,nd);
    %zr = reshape(z,H*W,1);
    [xx,yy] = meshgrid(linspace(0,1,W),linspace(0,1,H));
    idx = 1:params.nNormBins;
    for iD = 1:length(params.DepthDiv)-1
        dIdx = z>=params.DepthDiv(iD) & z<params.DepthDiv(iD+1);
        for iH = 1:length(params.HorizDiv)-1
            hIdx = xx>=params.HorizDiv(iH) & xx<params.HorizDiv(iH+1);
            for iV = 1:length(params.VertDiv)-1
                vIdx = yy>=params.VertDiv(iV) & yy<params.VertDiv(iV+1);
                nn = nr(dIdx(:) & hIdx(:) & vIdx(:),:);
                % Orientation
                o = nn * params.normBinCenters';
                Lb = sqrt(sum(nn.^2,2));
                o = bsxfun(@rdivide,o,Lb); % Norm of params.normBinCenters should be 1
                angles = acosd(o);
                % The following is a "soft" histogramming of normals. I.e., if a given
                % normal falls partway between two normal bins, it is partially
                % assigned to each of the nearest bins (not exclusively to one).
                SppTmp = max(0,params.normBinWidth-angles)/params.normBinWidth;
                SzSpp = size(SppTmp,1);
                % Normalize all histograms to sum to 1?
                %SppTmp = reshape(SppTmp,[H,W,params.nNormBins]);
                SppTmp = sum(SppTmp,1);
                % This is hacky and stupid! Instead, divide by the
                % total area of the screen??But: we don't want to
                % lose the normalization by depth only...
                %MinArea = 50;
                %if SzSpp<MinArea
                %    SppTmp = SppTmp/MinArea;
                %else
                SppTmp = SppTmp/norm(SppTmp);
                %end
                if sum(SppTmp==1)>1
                    error('Nothing is that strong a signal! why is there a 1 in multiple channels??');
                end
                Spreproc(iS,idx) = SppTmp;
                idx = idx+params.nNormBins;
            end
        end
    end
    
end
Spreproc(isnan(Spreproc)) = 0;
% Sub-optimal - This should be pre-allocated, but that's too
% annoying for now, and this shouldn't be too slow (2012.04.20 ML)
SppAll = [SppAll;Spreproc];
clear S;
%end
Spreproc = SppAll;
% if isfield(params,'fInfo')
%     save(sName,'Spreproc','params','-v7.3');
% end
%end

% % Z-score & save means & stds
% if params.normalize
%     if isfield(params, 'means') % Already preprocessed. Use the means and stds
%         global s; s = Spreproc; clear Spreproc; % a trick to modify Spreproc without copying it
%         [stds, means] = norm_std_mean_global(params.stds, params.means);
%         Spreproc = s; clear s;
%     else
%         global s; s = Spreproc; clear Spreproc; % a trick to modify Spreproc without copying it
%         [stds, means] = norm_std_mean_global();
%         Spreproc = s; clear s;
%         params.means = means;
%         params.stds = stds;
%     end
% end

% All done!
% (Return Spreproc, save elsewhere)
varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end