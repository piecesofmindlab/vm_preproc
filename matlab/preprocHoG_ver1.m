function varargout = preprocHoG_ver1(S,params)
% Usage: [Spreproc,params] = preprocHoG(S,params) 
%  (or): params = preprocHoG % For default parameters
% 
% Preprocess an image or image stack with Histogram of Gradient (HoG)
% features.  Based on L. Boudev's implmenetation of Dalal & Triggs, 2005
% CPVR. For original code, see
% /auto/k1/mark/AuxCode/poselets_June2011/code/poselet_detection/
% 
% This is a TEMPORARY file, which needs to be replaced with more flexible,
% general code. For now, it computes ONE possible HoG feature set with
% fixed parameters for training and validation data for the LH image data
% set. 
% 
% Currently only implements L. Bourdev's HoG code. TO DO: Make general
% enough to call other HoG code. FOR NOW: Play with params for this
% version, see if it works at all.
% 
% ML 2011.10.02
% Partial update 2011.12.29
% Update 2012.01.04

if ~exist('params','var')||isempty(params)
    % Default parameters. If params is not supplied, return only params.
    % NOTE: All these parameters may not be necessary. Kept for now for ease.
    % ML 2011.10.02
    params.WhichHoG = 'LubomirBourdev'; % LB's implementation
    
    params.DEBUG=0; % debug and verbosity level %% USELESS? 01.03.2012
    % Original: params.HOG_CELL_DIMS = [16 16 180]; % for larger images (~500 px)
    params.HOG_CELL_DIMS = [4,4,180]; % intended for images that are shrunk by 4x... Compute on bigger images??
    % Original: params.NUM_HOG_BINS = [2 2 9]; % 2 specifies (1px) overlap, yes?  
    params.NUM_HOG_BINS = [1 1 9]; % Thus: no overlap btw. bins
    params.HOG_WTSCALE = 2; %??
    params.HOG_NORM_EPS = 1; %??
    params.HOG_NORM_EPS2 = 0.01; %??
    params.HOG_NORM_MAXVAL = 0.2; %??
    params.HOG_NO_GAUSSIAN_WEIGHT=false;
    params.USE_PHOG=false;
    params.AvgPyramidLayers = true;
    %params.USE_MEX_HOG=false; % disable this to use Matlab version instead of mex file for HOG
    %params.USE_MEX_RESIZE=false; % disable this to use Matlab version instead of mex file for imresize
    
    % Second-stage preprocessing
    params.Is_Normalize = true; % Z-score [Not done! OR squash to (reasonable) range. Needs work / more options. LB's code performs some normalization by default.]
    params.nonLinearOut = 'none'; % Does nothing - not implemented yet! 
    params.Is_Rectify = false; % separate +/- channels. Does nothing - not implemented yet!
    params.nFramesPerTR = 30;
    % Temporal frequency channels
    params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
    params.tfmax = 2.6666667; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
    params.tfmin = 1.3333333; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
    params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
    params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
    if nargout==1
        varargout{1} = params;
    elseif nargout==2
        varargout{1} = S;
        varargout{2} = params;
    end
    return
elseif isnumeric(params)
    % if params are given in the form: [1,3]; 
    params = preprocHoG_GetMetaParams(params);
end

% Get number of images
if ndims(S)==4
    nIms = size(S,4);
else %if ndims(S)==3
    nIms = size(S,3);
end
% Options for HoG implementation
switch params.WhichHoG
    case 'LubomirBourdev'
        % Path to code
        %addpath('/auto/k1/mark/AuxCode/HoG/');
        addpath('/Users/mark/AuxCode/HoG/');
        % L. Bourdev's implementation
        %warning('Hard coded # of HoG bins! fix!');
        % Modifiy parameters slightly for L Bourdev's version
        pp = params;
        % If bins aren't square, this might be problematic...
        margin = 2; % 1 on each side
        if params.USE_PHOG
            if params.AvgPyramidLayers
                disp('Needs update!')
                keyboard
                params.nHoGDims = 0;
            else
                disp('Needs update!')
                keyboard
                params.nHoGDims = 0;
            end
        else
            nBinsX = floor((size(S,2)-margin)/params.HOG_CELL_DIMS(2));
            nBinsY = floor((size(S,1)-margin)/params.HOG_CELL_DIMS(1));
            params.nHoGDims = nBinsX*nBinsY*params.NUM_HOG_BINS(3);
        end
        pp.sX = nan(nIms,nBinsX);
        pp.sY = nan(nIms,nBinsY);
        
        % Preallocate
        Spreproc = nan(nIms,params.nHoGDims);
        for iS = 1:nIms
            if ndims(S)==4
                im = rgb2gray(S(:,:,:,iS));
            else
                im = S(:,:,iS);
            end
            [tmpS,sX,sY] = compute_hog(im,pp);
            if params.USE_PHOG
                if params.AvgPyramidLayers
                    HoG2 = squeeze(mean(mean(tmpS.hog2)));
                    HoG4 = squeeze(mean(mean(tmpS.hog4)));
                else
                    HoG2 = tmpS.hog2;
                    HoG4 = tmpS.hog4;
                end
                
                Spreproc(iS,:) = [tmpS.hog1(:);HoG2(:);HoG4(:)];
            else
                Spreproc(iS,:) = tmpS(:);
                % \/ This is useless. \/
                params.sX(iS,:) = sX;
                params.sY(iS,:) = sY;
                % /\ get rid of it or change it /\
            end
        end
    case 'AnnaBosch'
        % Anna Bosch's pHoG/Canny implementation
        error('Not ready yet!')
        % Paths to other modules??
    case 'PietroDollar'
        % Pietro Dollar's HoG implementation
        error('Not ready yet!')
        % Paths to other modules??
end

% (Save intermediate file?)
%save(
% TODO: LoadClean function to get rid of all ML-specific stuff from params
% files...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Second stage preprocessing %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (temporal frequency channels, compressing movie frames to data collection
% rate, etc)

% (Load intermediate file?)

% Rectify (or not). Doubles parameter count.
if params.Is_Rectify
    p = max(Spreproc,0);
    n = min(Spreproc,0);
    Spreproc = [p,n];
end
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
    sc = conv2(gc,1,Spreproc,'same');% Is "Same" safe to use here?? CHECK!!
    ss = conv2(gs,1,Spreproc,'same');
    % Square and sum
    Stf(:,:,itf) = sc.^2 + ss.^2;
end
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
    mm = nanmean(Spreproc);
    ss = nanstd(Spreproc);
    SppDeMean = bsxfun(@minus,Spreproc,mm);
    SppZ = bsxfun(@rdivide,SppDeMean,ss);
    SppZ(isnan(SppZ)) = 0;
    if false % Skip for now... 2012.01.06
        % Straight Z score gives wacky results: curves appear so sparsely
        % that it's not uncommon for a given channel to have one point of
        % high curvature appear, and nothing else (or, no other high values
        % of curvature for the whole training set). This means that z
        % scoring by channel can give really high z scores - up to 35 - to
        % some values of curvature, which is not appropriate. Solution:
        % squash 'em back down with a sigmoid function, same as above for
        % curvature.
        % Sigmoid squashing function:
        squash = @(x,b) 6/(1+exp(-b*x))-3; % Range from -3 to +3
        bb = 1; % this is the choice of STD... 2 seems to work well, but I don't have a rigorous reason for that.
        SppZs = zeros(size(SppZ));
        for iN = 1:size(SppZ,2);
            SppZs(:,iN) = arrayfun(@(ii) squash(ii,bb),SppZ(:,iN));
        end
        Spreproc = SppZs;
    end
    Spreproc = SppZ;
end
% All done!
% (Return Spreproc, save elsewhere)
varargout{1} = Spreproc;
varargout{2} = params;