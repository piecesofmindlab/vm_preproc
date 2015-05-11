function varargout = preprocHoN(S,pp)
% Usage: [Spreproc,params] = preprocHoN(S,params)
% 
% Computes a histogram of normals for an image, based on the normal output
% render from Blender (BVP)
% 
% Inputs: 
%   n = A stack of normal images created by hdr2normals (also takes string
%       input (single-image file names for quickie runs)
%   params = parameter struct. See code for params.
% 
% Calling the function with no inputs will return the default parameter
% struct.
% 
% Created by ML 2012.04.11

% TO DO: more efficient computation for multiple images?? This seems as if
% it should be able to be sped up considerably.

% Default parameters:
%%% Normal bins
% Centers of normal bins:
% NOTE! It is not a terribly easy problem to place equi-distant points
% around a sphere or half-sphere. See:
% http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
% ...for potential improvements in selecting normal bin centers
params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
    -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
    0,0,1]; % straight-ahead
params.Is_2D = false; % Whether to flatten all normals into the image plane
%%% Spatial bins
params.nSpatBins = 9; % number of spatial bins across image (square grid)
params.nSubBins = 1; % number of overlapping bins (NOT WORKING well (or at least not verified) as of 2012.04.03
params.histWtScale = nan; % computed to be neutral (no effect) unless it is 
params.Use_Gaussian_Bins = false; % (vs. flat coding of space)
%%% Normalization parameters
params.HON_NORM_MAXVAL = 0.2; % max value at which to clip HoN energy (Taken from HoG code - update??)
params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
  %number of HoN channels. Not explored thoroughly as of 2012.04.11
params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to
  %second normalization of HoN channels. Basically, prevents dividing by 0
% Placeholders for descriptors of HoN channels
params.HoNparams.Xc = []; % placeholder for descriptors of HoN channels
params.HoNparams.Yc = [];
params.HoNparams.Norm = [];
params.HoNparams.Sz = []; % This is (sort of) spatial frequency... but not really, because the orientation computation is simpler than that
% Second-stage preprocessing
params.Is_Normalize = true; % Z-score [Not done! OR squash to (reasonable) range. Needs work / more options. LB's code performs some normalization by default.]
params.nonLinearOut = 'none'; % Does nothing - not implemented yet! 
params.nFramesPerTR = 30;
% Temporal frequency channels
params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
params.tfmax = 2.6666667; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
params.tfmin = 1.3333333; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
params.crop = []; % crop allowable values to some restricted range. This is done AFTER (optional) z-scoring; thus it's possible to put some reasonable range of z scores here

if exist('pp','var') && ~isnumeric(pp)
    params = mlFillStruct(pp,params,true);
elseif exist('pp','var') && isnumeric(pp)
    params = preprocHoN_GetMetaParams(pp);
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
    % Return parameters if not given any inputs
    varargout{1} = params;
    return
end
params.nHoNdims = sum(params.nSpatBins.^2*params.nSubBins*params.nNormBins);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% First stage preprocessing %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over different segments of the stimulus matrix (for memory's sake), if necessary: 
if ischar(S)
    fDir = fileparts(S);
    stimF = dir(S);
    Ss = mlAddToCell({stimF.name}',[fDir filesep],true);
    nParts = length(Ss); 
elseif isnumeric(S)
    nParts = 1;
else
    error('WTF did you give me as a stimulus? I was expecting a string or a numeric matrix.')
end

Is_SkipPart1 = false;
if isfield(params,'fInfo')
    % fInfo is information particular to this parameter preset and this
    % particular run (Training / Validation, session #, pixels for images)
    sName = sprintf('%sHoN_%dpx_%s_Ses%d_%s_%02d.mat',params.fInfo.iDir,params.fInfo.nPixels,params.fInfo.ImType,params.fInfo.Ses,params.fInfo.TrnVal,params.metaparams.preset(1));
    if exist(sName,'file')
        load(sName,'Spreproc') % Loads Spreproc variable
        Is_SkipPart1 = true;
    end
end

if ~Is_SkipPart1
    SppAll = [];
    for iPart = 1:nParts
        if exist('Ss','var')
            load(Ss{iPart},'S');
        end
        % Get number of images
        if ndims(S)==4
            nIms = size(S,4);
        else %if ndims(S)==3
            nIms = size(S,3);
        end
        % Preallocate Spreproc
        Spreproc = nan(nIms,params.nHoNdims);
        for iS = 1:nIms
            progressdot(iS,200,2000,nIms);
            % Pull single normal image
            n = S(:,:,:,iS);            
            if iS == 1
                [Spp,params] = compute_HoN(n,params);
            else
                Spp = compute_HoN(n,params);
            end
            Spreproc(iS,:) = Spp';
        end
        % Sub-optimal - we'd like to pre-allocate this, but that's too
        % annoying for now, and this shouldn't be too slow (2012.04.20 ML)
        SppAll = [SppAll;Spreproc];
        clear S;
    end
    if any(imag(SppAll(:))>0); %1e-10))

        error('You have complex numbers in your HoN Check code!')
    end
    % Just in case: get rid of tiny imaginary components of complex values
    SppAll = real(SppAll);
    Spreproc = SppAll;
    if isfield(params,'fInfo')
        save(sName,'Spreproc','params','-v7.3');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Second stage preprocessing %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (temporal frequency channels, compressing movie frames to data collection
% rate, etc)
% Collapse across time to shrink whole matrix with temporal wavelets
if params.zerotf
    tf_array = logspace(log10(params.tfmin), log10(params.tfmax), params.tfdivisions-1);
    tf_array = [0 tf_array];
else
    tf_array = logspace(log10(params.tfmin), log10(params.tfmax), params.tfdivisions);
end
ntf = length(tf_array);
% Preallocate variable to store different temporal frequencies:
Stf = zeros([size(Spreproc),ntf]);
for itf = 1:ntf
    % Create filters
    gc = normpdf(linspace(-3.5,3.5,params.tsize)) .* cos(linspace(0,2*pi*tf_array(itf),params.tsize));
    gs = normpdf(linspace(-3.5,3.5,params.tsize)) .* sin(linspace(0,2*pi*tf_array(itf),params.tsize));
    % Convolve
    sc = conv2(gc,1,Spreproc,'same');
    ss = conv2(gs,1,Spreproc,'same');
    % Square and sum
    Stf(:,:,itf) = sc.^2 + ss.^2;
end
if any(imag(Stf(:)>1e-10))
    keyboard;
    error('You have complex numbers as a result of your temporal frequency channels! Check code!')
end
% Just in case: get rid of tiny imaginary components of complex values
Stf = real(Stf);
% Concatenate temporal channels onto the end
Stf = reshape(Stf,[size(Stf,1),size(Stf,2)*size(Stf,3)]);
% Average over successive frames
Stf = reshape(Stf,[params.nFramesPerTR,size(Stf,1)/params.nFramesPerTR,size(Stf,2)]);
Spreproc = squeeze(nanmean(Stf,1));
if any(isnan(Spreproc(:)))
    warning('Converting nan values to zero!')
    Spreproc(isnan(Spreproc)) = 0;
end
% Normalize
if params.Is_Normalize
    % Z-score all channels
    mm = nanmean(Spreproc);
    ss = nanstd(Spreproc);
    SppDeMean = bsxfun(@minus,Spreproc,mm);
    SppZ = bsxfun(@rdivide,SppDeMean,ss);
    SppZ(isnan(SppZ)) = 0;
    Spreproc = SppZ;
end
if any(params.crop)
    % Crop extreme parameter values
    % squash = @(x,b) 6/(1+exp(-b*x))-3; % Range from -3 to +3
    Mn = Crop(1); Mx = Crop(2);
    % Sigmoid squashing function to limit range of data from Mn to Mx
    Spreproc = mlSquash(Spreproc,Mn,Mx);
end

% All done!
% Output
varargout{1} = Spreproc;
if nargout > 1
    varargout{2} = params;
end
