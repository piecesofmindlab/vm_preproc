function params = preprocObjectLoc_GetMetaParams(Arg)
% Usage: params = preprocObjectLoc_GetMetaParams(Arg)
% 
% Function to get parameter pre-sets for HoN preprocessing. Input "Arg" is
% a two-element numerical vector, specifying a numerical option for 
% two steps of preprocessing. 
% 
% Step 1 is everything to do with Histogram of Gradient (HoN) processing
% (size of bins in image and angle space, normalization, etc)
% 
% Step 2 is everything after (having to do with collapsing values over
% time). These are specified separately because step 1 takes 
% considerably longer than step2. An intermediate file is stored after 
% completion of step 1 to save computational time for step2 variants. 
% 
% ML 2012.01.04

params = preprocObjectLoc;
params.class = 'preprocObjectLoc';
% First-stage processing presets
switch Arg(1)
    case 1
        % Default parameters:
        %params.metaparams.descr1 = '9x9 grid, no pyramid';
        %%% Spatial bins
        params.nSpatBins = 9; % number of spatial bins across image (square grid)
    case 2
        %params.metaparams.descr1 = '17x17 grid, no pyramid';
        %%% Spatial bins
        params.nSpatBins = 17; % number of spatial bins across image (square grid)
    case 3
        %params.metaparams.descr1 = 'Pyramid1: 17x17, 9x9, 5x5';
        %%% Spatial bins
        params.nSpatBins = [17,9,5]; % number of spatial bins across image (square grid)
end
