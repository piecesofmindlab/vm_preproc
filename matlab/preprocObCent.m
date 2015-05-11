function varargout = preprocObCent(S,pp)
% Usage: [Spreproc,params] = preprocObCent(S,params)
% 
% Preprocess object-centered models. Centers each object* in the center of
% an image, and perfoms a second preprocessing step on that object (HoG,
% Gabor, curvature, whatever). 
% 
% *for now, simply computes a bounding box around the object; does not
% center of mass, major/minor medial axes, or anything like that.
% 
% Input S should be a mask stack, or a file string specifying one (or more)
% mask stacks. Alternately, it can be a cell array, with the first argument
% as a mask stack, and the second argument as an [image array to be masked]
% 
% ML 2012.04.12

% Inputs
if ~exist('pp','var')
    pp = struct;    
elseif exist('pp','var') && isnumeric(pp)
    % if params are given in the form: [1,3]; 
    pp = preprocObCent_GetMetaParams(pp);
end

% Default params 
params.windowMode = 'bbCenterSquare'; % get object centered on bounding box
params.objSize = 72; % nan means no resizing
params.marginSz = .02; % minimum blank border to maintain around objects
params.objCombineMode = 'SumChannels'; % How to deal with multiple objects % 'SepChannels'; % 'KeepFirst'; % 'KeepBiggest'; % NONE of these are done yet besides first!
params.preprocFn = 'preprocHoG'; % function to call to preprocess objects
params.PP = [1,1]; % pre-set for <preprocFn>_GetMetaParams
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
% Update input params w/ defaults
params = mlFillStruct(pp,params,true);
% Get preprocFun metaparams if necessary:
if isnumeric(params.PP)
    params.PP = feval([params.preprocFn '_GetMetaParams'],params.PP);
end

params.nPPDims = params.PP.nHoGdims; % !! Will need changing!!
if ~ismember(params.objCombineMode,{'SumChannels'}); %{'SepChannels'}) % No other options is working yet!
    disp('No other options but "SumChannels" are working yet!');
    keyboard; % Needs work!
    multBy = nObj; % nObj = max number of objects in mask...
    % This should not be HoG-specific, but should affect params.nPPDims
    for iHoGp = 1:4;
        X = HoGp{iHoGp};
        params.HoGparams.(X) = repmat(params.HoGparams.(X),multBy,1);
    end
end

if ~nargin
    varargout{1} = params;
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% First stage preprocessing %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over different segments of the stimulus matrix (for memory's sake), if necessary: 
if ischar(S)
    fDir = fileparts(S);
    stimF = dir(S);
    Ss = mlAddToCell({stimF.name}',[fDir filesep],true);
    nParts = length(Ss); 
elseif iscell(S)
    error('intent is to use cell arrays for masking images / normals, but it''s not ready yet!');
    %keyboard;
elseif isnumeric(S)
    nParts = 1;
else
    error('WTF did you give me as a stimulus? I was expecting a string, cell, or a numeric matrix.')
end

Is_SkipPart1 = false;
if isfield(params,'fInfo')
    % fInfo is information particular to this parameter preset and this
    % particular run (Training / Validation, session #, pixels for images)    
    sName = fullfile(params.fInfo.iDir,sprintf('ObCent_%02d_Ses%d_%s.mat',params.metaparams.preset(1),params.fInfo.Ses,params.fInfo.TrnVal));
    if exist(sName,'file')
        load(sName,'Spreproc') % Loads Spreproc variable
        Is_SkipPart1 = true;
    end
end
if ~Is_SkipPart1
    SppAll = [];
    for iPart = 1:nParts
        if exist('Ss','var') && iscell(Ss)
            if ismember('S',who('-file',Ss{iPart}))
                load(Ss{iPart},'S');
            elseif ismember('MaskStack',who('-file',Ss{iPart}))
                load(Ss{iPart},'MaskStack');
                S = MaskStack;
            end
        %elseif exist('Ss','var') && isstruct(Ss)
        %    % Get file list 
        %    keyboard;
        %    0;
        end
        % Get number of images
        nIms = size(S,ndims(S));
        nObjs = size(S,ndims(S)-1); % max number of objects per scene
        % Preallocate Spreproc
        Spreproc = nan(nIms,params.nPPDims);
        for iS = 1:nIms
            progressdot(iS,200,2000,nIms)
            % Pull single image for preprocessing
            idx = repmat({':'},1,ndims(S)-1);
            im = S(idx{:},iS);
            Spp = []; % preallocate!!
            % Get rid of all temporal parameters
            Ct = 1;
            for iObj = 1:4; 
                mIm = im(:,:,iObj); 
                if any(mIm(:)); 
                    obIm = getObjFromMask(mIm,params.objSize,params.marginSz,params.windowMode); 
                    % This could be nearly any preprocessing step...
                    Spp(:,:,Ct) = feval(params.preprocFn,obIm,params.PP); %preprocHoG(obIm,pp);
                    Ct = Ct+1;
                    % Other possiblities: 
                    % no scale invariance - only translation invariance? 
                    % only parameterize outline, in some partition that
                    % relies on circumfrence rather than area?                     
                else
                    % What if objSize is nan??
                    % (that is: what if we want to keep objects at their
                    % original scales??)
                    obIm = zeros(params.objSize);
                end
            end
            if isempty(Spp)
                % In case all objects are off the screen
                Spp = zeros(size(Spreproc,2),1);
            end
            switch params.objCombineMode
                case 'SumChannels'
                    Spreproc(iS,:) = sum(Spp,3)';
                case 'mean'
                    0; % unfinished;
            end
        end
        % Sub-optimal - This should be pre-allocated, but that's too
        % annoying for now, and this shouldn't be too slow (2012.04.20 ML)
        SppAll = [SppAll;Spreproc];
        clear S;
    end
    Spreproc = SppAll;
    %params.nSpatBins = SpBins;
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
% (Return Spreproc, save elsewhere)
varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end
