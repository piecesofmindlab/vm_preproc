function params = preprocFFT3_GetMetaParams(Arg)
% Usage: params = preprocFFT3_GetMetaParams(Arg)
% 
% Returns params for numbered preprocFFT3 presets. 
% 
% ML 2013.07

pp.class = 'preprocFFT3';

switch Arg
    case 1
        pp.zeroSF = false;
        pp.ori_n = 8;
        pp.sf_n = 8;
        pp.tf_n = 4;
        pp.ori_max = pi;
        pp.sf_max = 32; % defaults to size of S / 2 if empty
        pp.tf_max = 8; % defaults to params.tSize/2 if empty
        % Optionally, directly specify bins (2 row matrix of bin edges: 1st row=bin min, 2nd row=bin max)
        pp.tf_bins = []; % if empty, subdivide evenly among available frequencies
        pp.sf_bins = [];
        pp.ori_bins = []; % Ori will be handled differently
        pp.tSize = 30; % should be at least 2x nTFs
        pp.tStep = 1; % values less than tSize give overlapping windows
        pp.logSpaceFreq = false; % ignored if sf_bins or tf_bins are specified
    case 2
        pp.zeroSF = false;
        pp.ori_n = 1;
        pp.sf_n = 8;
        pp.tf_n = 5;
        pp.ori_max = pi;
        pp.sf_max = 32; % defaults to size of S / 2 if empty
        pp.tf_max = 8; % defaults to params.tSize/2 if empty
        % Optionally, directly specify bins (2 row matrix of bin edges: 1st row=bin min, 2nd row=bin max)
        pp.tf_bins = []; % if empty, subdivide evenly among available frequencies
        pp.sf_bins = [];
        pp.ori_bins = []; % Ori will be handled differently
        pp.tSize = 30; % should be at least 2x nTFs
        pp.tStep = 1; % values less than tSize give overlapping windows
        pp.logSpaceFreq = false; % ignored if sf_bins or tf_bins are specified
    case 3
        % NO TF, NO ORI, just 8 bins of different spatial frequencies
        pp.zeroSF = false;
        pp.ori_n = 1;
        pp.sf_n = 8;
        pp.tf_n = 1;
        pp.ori_max = pi;
        pp.sf_max = 32; % defaults to size of S / 2 if empty
        pp.tf_max = 1; % defaults to params.tSize/2 if empty
        % Optionally, directly specify bins (2 row matrix of bin edges: 1st row=bin min, 2nd row=bin max)
        pp.tf_bins = []; % if empty, subdivide evenly among available frequencies
        pp.sf_bins = [];
        pp.ori_bins = []; % Ori will be handled differently
        pp.tSize = 30; % should be at least 2x nTFs
        pp.tStep = 1; % values less than tSize give overlapping windows
        pp.logSpaceFreq = true; % ignored if sf_bins or tf_bins are specified
end

params = pp;