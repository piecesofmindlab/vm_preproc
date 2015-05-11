function varargout = compute_PC(S,params)
% Usage: Spreproc,params = compute_PC(S,params)
% 
% Compute projected curvature of 3D depth map.
% 
% ML 2012.11.28 

% Default parameters
% For computing curvature - how to subdivide curvature "energy"
pDefault.separateCurvDir = true;
pDefault.combineCurvDirMethod1 = 'absMax'; % At start
rDefault.combineCurvDirMethod1 = {'absMax'};
pDefault.combineCurvDirMethod2 = 'none';  % At end
rDefault.combineCurvDirMethod2 = {'none'};
pDefault.rectify = false; % separate positive and negative curvature (this is NOT the same as principal directions / max/min curvature!)
pDefault.useAbsCurvature = false;
pDefautl.binCurvature = false;
pDefault.binCenters = []; % For now: Gaussian bins. 
pDefault.binStds = []; % 
% Curvature squashing (only one option)
pDefault.curvSquashArgs = {-inf,inf}; % Curvature will be "squashed" to this range via the function below
pDefault.curvSquashFn = 'squashNcdf'; % Default is to squash with normal cumulative distribution function (gaussian sigmoid)
rDefault.curvSquashFn = {'squashNcdf'}; % Don't vary this... works fine
% For orientation bins
pDefault.nOriBins = 4; % number of orientation bins
rDefault.nOriBins = [1 9]; % more than 9 is just silly.
pDefault.oMax = 180; % DO NOT CHANGE THIS - 360 degree orientation has no meaning for 3D curvature direction
rDefault.oMax = [180,180];
% For spatial bins
pDefault.nSpatBins = 17; % number of spatial bins across image (square grid)
pDefault.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03 % Specify this as a % overlap
pDefault.pxPerBin = 5; % number of pixels per spatial [histogram] bin (allows resizing of images for computation)
pDefault.histWtScale = nan; % computed to be neutral (no effect) (?)
pDefault.Use_Gaussian_Bins = true; % (vs. flat coding of space)
pDefault.resizeZim = false; % Whether or not to resize
% For normalization
pDefault.PC_Norm_Area = []; %{'CenterSurround',9}; % Area over which to normalize PC channels (arguments fed to getSurroundIndices.m)
pDefault.PC_NORM_MAXVAL = nan; %0.2; % max value at which to clip PC energy (MODIFY??)
pDefault.PC_NORM_EPS = nan; %1.0; % regularization factor 1; multiplier for
%# of PC channels. (multiplier for # of norm bins?)
pDefault.PC_NORM_EPS2 = nan; %0.01; % regularization factor 2 (Eta)

% Inputs
if ~exist('params','var')
    params = struct;
end
% Fill in default params
params = defaultOpt(params,pDefault,rDefault);
% Check for incompatible param combos??
% Return params if no input
if ~nargin
    varargout{1} = params;
    return
end

% compute_principalCurvatureFromZ options - always use these? 
% TO DO: Look into what changing f (focal length) does !
ReturnVector = false;
f = 1; % focal length. 1 for conveneince (seems to work correctly)
[kMin,dMin,kMax,dMax] = compute_principalCurvatureFromZ(S,f,ReturnVector);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%     Normalize curvature (squash extreme values down)     %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kMinN = feval(params.curvSquashFn,kMin,params.curvSquashArgs{:});
kMaxN = feval(params.curvSquashFn,kMax,params.curvSquashArgs{:});
% Normalize again to range [-1,1]
kMinN = kMinN / max(abs(kMinN(:)));
kMaxN = kMaxN / max(abs(kMaxN(:)));
% NOTE: This is saying that the differences in absolute curvature between
% scenes do not matter. IS there a way to compute scale-invariant
% curvature?? Is this basically doing that? 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Separate / combine curvature channels (+/-,bins,directions) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do / don't take absolute curvature
if params.useAbsCurvature
    kMinN = abs(kMinN);
    kMaxN = abs(kMaxN);
end
% rectify +/-, concatenate in 3rd dimension
if params.rectify
    kMinNp = max(kMinN,0);
    kMinNn = abs(min(kMinN,0));
    kMinN = cat(3,kMinNn,kMinNp);
    kMaxNp = max(kMaxN,0);
    kMaxNn = abs(min(kMaxN,0));
    kMaxN = cat(3,kMaxNn,kMaxNp);
end
% Bin curvature
if params.binCurvature
    if params.rectify
        % temporarily add a 4th dimension to the matrix
        bIdx = {':',':',':'};
        kMinNtmp = zeros([size(kMinN),2,length(params.binCenters)]);
        kMaxNtmp = zeros([size(kMaxN),2,length(params.binCenters)]);
    else
        bIdx = {':',':'};
        kMinNtmp = zeros([size(kMinN),length(params.binCenters)]);
        kMaxNtmp = zeros([size(kMaxN),length(params.binCenters)]);
    end
    for iB = 1:length(params.binCenters)
       ii = [bIdx,iB];
       kMinNtmp(ii{:}) = normpdf(kMinN,params.binCenters(iB),params.binStds(iB));
       kMaxNtmp(ii{:}) = normpdf(kMaxN,params.binCenters(iB),params.binStds(iB));
    end
    % Reshape to 3 dimensions
    kMinN = reshape(kMinNtmp,size(kMinN,1),size(kMinN,2),[]);
    kMaxN = reshape(kMaxNtmp,size(kMaxN,1),size(kMaxN,2),[]);
end
% Finally, duplicate dmin,dmax to match size of kMinN & kMaxN 
dMin = repmat(dMin,[1,1,size(kMinN,3)]);
dMax = repmat(dMax,[1,1,size(kMinN,3)]);
% Either keep 2 principal direction separate, or combine
if params.separateCurvDir
    combCurv = cat(4,kMinN,kMaxN);
    combAng = cat(4,dMin,dMax);
else
    % Combine 
    switch params.combineCurvDirMethod1
        case 'absMax'
            idx = abs(kMinN)<abs(kMaxN);
            combCurv = kMinN;
            combCurv(idx) = kMaxN(idx);
            combAng = dMin;
            combAng(idx) = dMax(idx);
        otherwise
            error('Not ready yet!')
    end
end
% Size of everything checks out??
[H,W,nCurvCh1,nDir] = size(combCurv);


% Loop over directions of curvature (separate channels); possibly combine
% the separate channels by some means at the end?
Spp = []; % Preallocate. TO DO: set to zeros matrix / do indices below?
for iCurvDir = 1:nDir

    gm = combCurv(:,:,:,iCurvDir);
    go = combAng(:,:,:,iCurvDir);

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%  Bin orientations and spatial positions   %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Circular distance function
    cDist = @(a,b,mx) min(abs(a-b), mx - abs(a-b));
    % The following is a "soft" histogramming of orientations. This means
    % that if there are two bins centers at, e.g., 0 and 45 degrees, then
    % an angle of 22.5 will be assigned to both bins with a value of .5 
    % ori_hist(:,x,y) is non-negative and sums to 1 and ori_hist(A,x,y) is
    % the fraction of the PC angle at pixel (x,y) that falls in bin A
    %
    % QUESTION: Should we be soft-binning curvature magnitude as well? Or
    % gaussian binning orientation??
    angles = repmat(reshape(params.oBinCenters,[1,1,params.nOriBins]),[H,W,1]);
    bin_dist = bsxfun(@(x,BinCent) cDist(x,BinCent,params.oMax),go,angles);
    ori_hist = max(0,params.oBinWidth-bin_dist)/params.oBinWidth;
    % Weight orientation proportions by magnitude of curvature
    if params.nOriBins==1
        PC = gm;
    else
        if (params.rectify && params.nOriBins>1) || (params.binCurvature && params.nOriBins>1)
            error('Re-visit orientation histogramming before trying combined bin/ori models!')
        end
        PC = ori_hist .* repmat(gm,[1,1,params.nOriBins]);
    end
    % Spatial bins
    [PC,Xc,Yc,Sz] = assign_bins(PC,params);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%         Bin Normalization       %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    num_cells = [params.nSpatBins,params.nSpatBins];

    if ~isempty(params.PC_Norm_Area)
        normBin = getSurroundIndices(num_cells(1),num_cells(2),params.PC_Norm_Area{1},params.PC_Norm_Area{2});
    else
        normBin = logical(eye(num_cells(1)^2)); % each cell will only be normalized by itself
    end
    
    % TO DO: MOVE ALL THIS TO COMPUTE_PREPROCPROJCURV_PARAMS
%     if params.rectify
%         nRect = 2;
%     else
%         nRect = 1;
%     end
%     if params.binCurvature
%         nCurvBin = length(params.binCenters);
%     else
%         nCurvBin = 1;
%     end
    %num_PC_dims = params.nOriBins * params.nSubBins * nRect * nCurvBin; 
    num_PC_dims = params.nPCdims/(params.separateCurvDir + 1);
    pc = reshape(PC,[prod(num_cells),num_PC_dims]);
    %PCnormd = zeros(pc,[1,1,size(normBin,3)]); % Add channels for normalization bins
    %pc = repmat(pc,[1,1,size(normBin,3)]); % Add channels for normalization bins
    % Normalize (per Dalal & Triggs)
    if ~isnan(params.PC_NORM_EPS)
        % Compute L2 norm (across orientations and part-bins [overlapping bins])
        % Eta is a regularization factor, based on params.PC_NORM_EPS multiplied by the number of channels
        % preallocate Eta
        %Eta = ones(size(PCnormd,1),1,size(PCnormd,3));
        Eta = ones(size(pc,1),1,size(normBin,3));
        for iE = 1:size(normBin,3)
            % Eta is the sum of squares of all the bins specified by "normBin"
            % OLD: Eta = sqrt(sum(pc.^2,2))+params.PC_NORM_EPS*num_PC_dims;
            Eta(:,1,iE) = sqrt(normBin(:,:,iE)*sum(pc.^2,2))+params.PC_NORM_EPS*num_PC_dims;
        end
        % Normalize
        pc = bsxfun(@rdivide,pc,Eta);
        % reshape pc
        pc = reshape(pc,[size(pc,1),size(pc,2)*size(pc,3)]);
    end
    if ~isnan(params.PC_NORM_MAXVAL)
        % Clip high values (Change this to some squashing function? sqrt? log?)
        pc = min(pc,params.PC_NORM_MAXVAL);
    end
    if ~isnan(params.PC_NORM_EPS2)
        % Normalize again:
        Eta = sqrt(sum(pc.^2,2))+params.PC_NORM_EPS2;
        pc = bsxfun(@rdivide,pc,Eta);
    end
    % Re-format
    pc = pc(:);
    % To Do: Explore other options to combine diff directions back into a
    % single set of channels (rather than doubling the number of channels)
    switch params.combineCurvDirMethod2
        case 'none'
            % Keep as separate channels
            Spp = [Spp;pc];
        otherwise
            error('Fuck me! No other combination options...')
    end
end
% Output 
varargout{1} = Spp;
if nargout > 1
    varargout{2} = params;
end
end
% Now PC will be nested: position (nSp x nSp), ori (x 4), surround (x 4?),
% scale (for diff scales, this function is called recursively)
