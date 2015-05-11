function params = preprocHoG_GetMetaParams_ver1(Arg)
% Usage: params = preprocHoG_GetMetaParams_ver1(Arg)
% 
% Function to get parameter pre-sets for HoG preprocessing. Input "Arg" is
% a two-element numerical vector, specifying a numerical option for 
% two steps of preprocessing. 
% 
% Step 1 is everything to do with Histogram of Gradient (HoG) processing
% (size of bins in image and angle space, normalization, etc)
% 
% Step 2 is everything after (having to do with collapsing values over
% time). These are specified separately because step 1 takes 
% considerably longer than step2. An intermediate file is stored after 
% completion of step 1 to save computational time for step2 variants. 
% 
% ML 2012.01.04

params = preprocHoG;
params.metaparams.preset = Arg;
params.metaparams.descr = cell(2,1);
% First-stage processing presets
switch Arg(1)
    case 1
        params.metaparams.descr{1} = 'Original: 17x17 grid, 4 angles, 180, no pyramid';
        params.HOG_CELL_DIMS = [4,4,180];
        params.NUM_HOG_BINS = [1 1 4]; % 1s mean no overlap?
    case 2
        params.metaparams.descr{1} = 'Small: 8 px bins, 4 angles, 180, no pyramid';
        params.HOG_CELL_DIMS = [8,8,180];
        params.NUM_HOG_BINS = [1 1 4]; % 1s mean no overlap?
    case 3
        params.metaparams.descr{1} = 'Small+More Ang Bins: 8 px bins, 9 angles, 180, no pyramid';
        params.HOG_CELL_DIMS = [8,8,180];
        params.NUM_HOG_BINS = [1 1 9]; % 1s mean no overlap?
    case 4
        params.metaparams.descr{1} = 'Small+More Ang Bins: 8 px bins, 9 angles, 360, no pyramid';
        params.HOG_CELL_DIMS = [8,8,360];
        params.NUM_HOG_BINS = [1 1 9]; % 1s mean no overlap?
    otherwise
        error('Unknown parameter configuration!');        
end

% Second-stage preprocessing
switch Arg(2)
    case 1
        params.metaparams.descr{2} = 'First pass; 10s window,3 tf chans incl 0'; % NOTE! I believe the 10 is frames, not seconds...
        % Temporal frequency channels
        params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 2.6666667; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 1.3333333; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
    case 2
        % No temporal dimensions!
        params.metaparams.descr{2} = 'No temporal freq; 30 stim per TR; 1tf (0)';
        % Temporal frequency channels
        params.tsize = 1; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 0; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 1; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
        params.nFramesPerTR = 30;
    case 3
        % No temporal dimensions!
        params.metaparams.descr{2} = 'No temporal freq; 1 stim per tr; 1tf (0)';
        % Temporal frequency channels
        params.tsize = 1; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 0; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 1; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
        params.nFramesPerTR = 1;
    otherwise
        error('Unknown parameter configuration!');
end