function params = preprocSceneDepthNormals_GetMetaParams(Arg)
% Usage: params = preprocSceneDepthNormals_GetMetaParams(Arg)
% 
% Function to get parameter pre-sets for SceneDepthNormals" preprocessing.
% Input "Arg" is a two-element numerical vector, specifying a numerical
% option for two steps of preprocessing. 
% 
% Step 1 is everything to do with "SceneDepthNormals" processing
% (size of bins in image and angle space, normalization, etc)
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
% ML 2012.11.12

params = preprocSceneDepthNormals;
%params = rmfield(params,'HoGparams');
params.metaparams.preset = Arg;
% First-stage processing presets
params.class = 'preprocSceneDepthNormals'
switch Arg(1)
    case 1
        % Default parameters:
        params.metaparams.Descr = '1 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '1d x 1h x 1v x 9norms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        params.DepthDiv = [0,inf];
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
            -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
            0,0,1]; % straight-ahead
        %params.Is_2D = false; % Whether to flatten all normals into the image plane
        
        
%         %%% Normalization parameters
%         params.HON_NORM_MAXVAL = 0.2; % max value at which to clip HoN energy (Taken from HoG code - update??)
%         params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
%         %number of HoG channels. Not explored thoroughly as of 2012.04.11
%         params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to prevent division by 0?
    case 2        
        % Default parameters:
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '5d x 1h x 1v x 9norms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
            -1 -1 1; -1,1,1; 1,1,1; 1,-1,1; % 4 45 deg. cube corners
            0,0,1]; % straight-ahead
        
%         %%% Normalization parameters
%         params.HON_NORM_MAXVAL = 0.2; % max value at which to clip HoN energy (Taken from HoG code - update??)
%         params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
%         %number of HoG channels. Not explored thoroughly as of 2012.04.11
%         params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to prevent division by 0?
    case 3
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 5 normal basis vectors';
        params.metaparams.AxLabel = '5d x 1h x 1 vert bin, 9norms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 0 1 0; 1 0 0; 0 -1 0; % 4 in-plane axes:
            0,0,1]; % straight-ahead
        %params.Is_2D = false; % Whether to flatten all normals into the image plane
        
        
%         %%% Normalization parameters
%         params.HON_NORM_MAXVAL = 0.2; % max value at which to clip HoN energy (Taken from HoG code - update??)
%         params.HON_NORM_EPS = 1.0; % regularization factor 1; multiplier for
%         %number of HoG channels. Not explored thoroughly as of 2012.04.11
%         params.HON_NORM_EPS2 = 0.001; % regularization factor 2: added to prevent division by 0?

end



