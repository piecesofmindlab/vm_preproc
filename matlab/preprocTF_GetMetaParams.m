function params = preprocTF_GetMetaParams(Arg)
% Usage: params = preprocTF_GetMetaParams(Arg)
% 
% ML 2012.11.16

params.class = 'preprocTF';
switch Arg
    case 1
        % No temporal freq channels; 1 freq at 0 tf for each frame
        % Temporal frequency channels
        params.tsize = 1; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 0; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 1; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
    case 2
        % No temporal freq channels; 1 freq at 0 tf for each frame; 666 ms window
        % Temporal frequency channels
        params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 0; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 0; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 1; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
    case 3
        % 3 temporal frequency channels @ 0-2-4 hz, 10fr (666ms) envelope
        params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 2.6666667; % maximum temporal frequency encoded (tf is actually log10(params.tfmax)
        params.tfmin = 1.3333333; % minimum temporal frequency encoded (tf is actually log10(params.tfmin)
        params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
    case 4
        % 3 temporal frequency channels @ 0-1-2 hz, 10fr (666ms) envelope
        params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 1.3333333; % maximum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
        params.tfmin = .6666666; % minimum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
        params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
    case 5
        % 2 temporal frequency channels @ 0-2 hz, 10fr (666ms) envelope
        params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 1.3333333; % maximum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
        params.tfmin = 1.3333333; % minimum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
        params.tfdivisions = 2; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
    case 6
        % 2 temporal frequency channels @ 0-4 hz, 10fr (666ms) envelope
        params.tsize = 10; % temporal window of gaussian, in frames (stim presented at 15 fps); SN uses 10 for motion energy
        params.tfmax = 2.666667; % maximum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
        params.tfmin = 2.666667; % minimum temporal frequency encoded (tf is actually tf/ (tsize/15fps)
        params.tfdivisions = 2; % number of tf channels, logarithmically spaced between min and max
        params.zerotf = true; % include zero tf ( =to Gaussian(?) mean of time points w/ no temporal modulation)
    case 10
        % 0-2-4 for stimuli presented at 33.3/2 = 16.66 Hz
        hz = 16.66666;
        params.tsize = 10;
        params.tfmax = 4 * params.tsize/hz;
        params.tfmin = 2 * params.tsize/hz;
        params.zerotf = true;
        params.tfdivisions = 3; % number of tf channels, logarithmically spaced between min and max
    otherwise
        error('Unknown parameter configuration!');
end
