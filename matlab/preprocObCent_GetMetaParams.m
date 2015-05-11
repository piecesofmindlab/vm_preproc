function params = preprocObCent_GetMetaParams(Arg)
% Usage: params = preprocObCent_GetMetaParams(Arg)
% 
% Function to get parameter pre-sets for Object-centered (2d)
% preprocessing. Input "Arg" is a two-element numerical vector, specifying
% a numerical option for two steps of preprocessing. 
% 
% Step 1 is everything to do with the transition to object-centered space,
% as well as a specification for which preprocessing function to use (in
% params.PP and params.preprocFn)
% 
% Step 2 is everything after (having to do with collapsing values over
% time). These are specified separately because step 1 takes 
% considerably longer than step2. An intermediate file can be stored after 
% completion of step 1 to save computational time for step2 variants. 
%
% To save an intermediate file requires extra information that will be
% experiment-specific (e.g., whether the file is for training or validation
% runs, what type of image is being processed, what size the images were).
% This info can be appended to the params struct in a sub-struct
% ("params.fInfo"), outside of this function. (This function is meant to be
% general enough to use for any experiment / stimulus set). 
% 
% ML 2012.01.04
% Updated 2012.04.20

params = preprocObCent;
params.metaparams.preset = Arg;

% First-stage processing presets
switch Arg(1)
    case 1
        params.metaparams.descr1 = 'Standard: 9x9 grid, 4 angles, 180, no pyramid';
        params.metaparams.AxLabel = 'ObCent HoG: 17x17pos, 4 ang, 180deg,';
        % Object Params
        params.windowMode = 'bbCenterSquare'; % get object centered on bounding box
        params.objSize = 72; % nan means no resizing
        params.marginSz = .02; % minimum blank border to maintain around objects
        params.objCombineMode = 'SumChannels'; % How to deal with multiple objects % 'SepChannels'; % 'KeepFirst'; % 'KeepBiggest'; % NONE of these are done yet besides first!
        % Preprocessing 
        params.preprocFn = 'preprocHoG'; % function to call to preprocess objects
        % 17x17 HoG model (See preprocHoG_GetMetaParams)
        params.PP = [1,1]; % pre-set for <preprocFn>_GetMetaParams
    case 2
        params.metaparams.descr1 = '17x17 grid, 4 angles, 180, no pyramid, 72px obj, centered & resized';
        params.metaparams.AxLabel = 'ObCent HoG: cent/resz, 17x17pos, 4 ang, 180deg,';
        % Object Params
        params.windowMode = 'bbCenterSquare'; % get object centered on bounding box
        params.objSize = 72; % nan means no resizing
        params.marginSz = .02; % minimum blank border to maintain around objects
        params.objCombineMode = 'SumChannels'; % How to deal with multiple objects % 'SepChannels'; % 'KeepFirst'; % 'KeepBiggest'; % NONE of these are done yet besides first!
        % Preprocessing 
        params.preprocFn = 'preprocHoG'; % function to call to preprocess objects
        % 17x17 HoG model (See preprocHoG_GetMetaParams)
        params.PP = [2,1]; % pre-set for <preprocFn>_GetMetaParams
    case 3
        params.metaparams.descr1 = '17x17 grid, 4 angles, 180, no pyramid, 72px obj, centered & resized';
        params.metaparams.AxLabel = 'ObCent HoG: cent/resz, 17x17pos, 4 ang, 180deg,';
        % Object Params
        params.windowMode = 'bbCenterSquare'; % get object centered on bounding box
        params.objSize = 72; % nan means no resizing
        params.marginSz = .02; % minimum blank border to maintain around objects
        params.objCombineMode = 'SumChannels'; % How to deal with multiple objects % 'SepChannels'; % 'KeepFirst'; % 'KeepBiggest'; % NONE of these are done yet besides first!
        % Preprocessing 
        params.preprocFn = 'preprocHoG'; % function to call to preprocess objects
        % 17x17 HoG model (See preprocHoG_GetMetaParams)
        params.PP = [2,1]; % pre-set for <preprocFn>_GetMetaParams
end

switch Arg(2)
    case 1  
        params.metaparams.descr2 = '3tf (0,1.3,2.6), 30fr per TR, box downsampling, Normalized';
        params.metaparams.AxLabel = [params.metaparams.AxLabel ' 3tf, mean ds'];
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
end