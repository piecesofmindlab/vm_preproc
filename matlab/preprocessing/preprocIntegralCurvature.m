function varargout = preprocIntegralCurvature(S,params)
% Usage: [Spp,params] = preprocIntegralCurvature(S,params)
% 
% Computes curvature at each point along the boundary of each object mask
% for each frame in S, based on the integral curvature techiniques outlined
% in Kumar et al 2012 (ECCV). [other refs...]
% 
% Inputs: 
%   S : An array of masks for each object in each frame of a stimulus,
%       [Y,X,object,frame]; objects should be stacked in depth from BACK
%       (1) to front (end) in the 3rd dimension of the array.
%   params : struct array of parameters, with fields: 
%       .
% 
% 2013.08.30 ML

% Inputs
if nargin>0 && ~islogical(S)
    warning('Converting to logical w/ S>0')
    S = S>0;
end
if ~exist('params','var')
    params = struct;
end
% Default params
dParams.scale = [8,16]; % gives 15x15, 7x7 grid of locations
dParams.curvMethod = 'optimizedforloop'; % [Change 'forLoop' it sucks] 'conv'
dParams.mergeObjects = 'last'; % 'first'; 'last'; 'none';
dParams.Is_FillHoles = true;
dParams.blur = 'gaussian';
dParams.dsMethod = 'nearest'; % 'bilinear'
dParams.nansub = 0; % 1i; 
dParams.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
dParams.normalizeByContour = true;
dParams.signOpt = 'none';
% dParams.bins = []; % only necessary if you want channels to be bins of curvature
dParams.tmpPath = []; %'/auto/k8/tempcache/'; % only necessary if you want to 
dParams.Is_Recache = false;
% Other: 
% Rectification of curvature
% BINS / histogramming of curvature? 
% Total curvature energy? Absolute curvature? 

% Fill default params
params = defaultOpt(params,dParams);
if ~nargin
    varargout{1} = params;
    return
end
% Computed parameters
[y,x,nObjs,nIms] = size(S);
nScales = length(params.scale);
for iSc = 1:nScales
    if length(params.dsFactor)==1
        dsF = params.dsFactor;
    elseif length(params.dsFactor)==length(params.scale)
        dsF = params.dsFactor(iSc);
    else
        error('Downsample factor does not match scale!');
    end
    ImSz = floor(x/((params.scale(iSc)*2+1)* dsF));
    params.ImSz(iSc) = ImSz^2;
end
switch params.signOpt
    case 'rectify'
        rMult = 2;
    otherwise
        rMult = 1;
end
Spp = zeros(nIms,sum(params.ImSz)*rMult);
% Allow for cache of pre-computed curvature images (expensive to compute!)
if ~isempty(params.tmpPath)
    for iScale = 1:nScales
        DatChk.scale = params.scale(iScale);
        fields = {'mergeObjects','Is_FillHoles'};
        for iF = 1:length(fields)
            DatChk.(fields{iF}) = params.(fields{iF});
        end
        % DataHash can't handle full stimulus matrix, so ASSUME that first
        % 30 frames of stim are unique for a given stim set...
        %DatChk.Stim = S(:,:,:,1:min(nIms,30));
        DatChk.Stim = S(:,:,:,[1:min(nIms,30),max(1,nIms-29):nIms]);
        HashFile = fullfile(params.tmpPath,[DataHash(DatChk),'.mat']);
        if params.Is_Recache
            CacheExists(iScale) = false;
        else
            CacheExists(iScale) = exist(HashFile,'file');
        end
        % TEMP! Re-do caching to take in the last 30 frames, too
        %if CacheExists(iScale)
        %    DatChk.Stim = S(:,:,:,[1:min(nIms,30),max(1,nIms-29):nIms]);          
        %    HashFileOld = HashFile;
        %    HashFile = fullfile(params.tmpPath,[DataHash(DatChk),'.mat']);
        %    movefile(HashFileOld,HashFile);
        %end
        %disp(HashFile)
        Cached{iScale} = matfile(HashFile,'writable',~CacheExists(iScale));
        %params.cacheFile{iScale} = HashFile;
        if ~CacheExists(iScale)
            Cached{iScale}.K = zeros(y,x,nIms);
        end
    end
end

for iIm = 1:nIms
    progressdot(iIm,50,1000,nIms);
    % Compute curvature
    if ~isempty(params.tmpPath)
        CurvIm = zeros(size(S,1),size(S,2),nScales);
        for iScale = 1:nScales
            if ~CacheExists(iScale)
                ppSc = params;
                ppSc.scale = params.scale(iScale);
                CurvIm(:,:,iScale) = compute_IntegralCurvature(S(:,:,:,iIm),ppSc);
                Cached{iScale}.K(:,:,iIm) = CurvIm(:,:,iScale);
            else
                CurvIm(:,:,iScale) = Cached{iScale}.K(:,:,iIm);
            end
            
        end
    else
        CurvIm = compute_IntegralCurvature(S(:,:,:,iIm),params);
    end
    if iIm==1
        ppOut = params;
    end
    % Rectify / bin if desired
    switch params.signOpt
        case 'rectify'
            pos = max(CurvIm,0);
            neg = abs(min(CurvIm,0));
            CurvIm = cat(3,pos,neg);
            if iIm==1
                ppOut.scale = [ppOut.scale,ppOut.scale];
            end
        case 'absolute'
            % Take absolute curvature
            CurvIm = abs(CurvIm);
        case 'bin'
            % Not yet!
            error('Not yet!')
        case 'none'
            0; % do nothing!
        otherwise
            error('unknown sign option! (params.signOpt)')
    end
    % Spatial downsampling
    [Spp(iIm,:),ppOut] = downsampleCurvIm(CurvIm,ppOut);
end
% Output 
% Preprocessed stimulus
varargout{1} = Spp;
if nargout>1
    % modified params
    varargout{2} = ppOut;
end
