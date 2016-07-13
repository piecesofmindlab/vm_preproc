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
params.class = 'preprocSceneDepthNormals';
switch Arg(1)
    case 1
        % Default parameters:
        params.metaparams.Descr = '1 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '1d, 1h, 1v bin, 5ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 1;
        params.DepthDiv = [0,inf];
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
    case 2
        % Add more depth
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, 5ScNorms';
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
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];

    case 3
        % Add more depth, diff granularity
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-50, 1h, 1v bin, 5ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(50),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];

    case 4
        % Add more normal basis vectors + 0-100 depth
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, 9ScNorms';
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
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];

    case 5
        % Add more normal basis vectors, + 0-50 depth
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-50, 1h, 1v bin, 5ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(50),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];

    case 6
        % Add more depth (10), 5 normal basis vectors
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 5ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];

    case 7
        % Add more depth (10), 9 normal basis vectors
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 9ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead %% NOTE! This is still fuckt: this direction in the Blender world is supposed to be -1
        params.normParams.removeComponent = [0,0,0];

%%% Grav centered %%%
        
    case 8
        % Default parameters, Grav-centered:
        params.metaparams.Descr = '1 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '1d, 1h, 1v bin, 5GravNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 1;
        params.DepthDiv = [0,inf];
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];
    case 9
        % Add more depth
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, 5GravNorms';
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
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];

    case 10
        % Add more depth, diff granularity
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-50, 1h, 1v bin, 5GravNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(50),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];

    case 11
        % Add more normal basis vectors + 0-100 depth
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, 9GravNorms';
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
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];

    case 12
        % Add more normal basis vectors, + 0-50 depth
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-50, 1h, 1v bin, 5GravNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(50),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];

    case 13
        % Add more depth (10), 5 normal basis vectors
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 5GravNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];

    case 14
        % Add more depth (10), 9 normal basis vectors
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 9GravNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];

%%% --- Second pass: more vertical slant normals for counterstrike data --- %%%
    case 15
        % 5 depth 0-50, 7 normal basis vectors
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 7 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-50, 1h, 1v bin, 7ScNorms';
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
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 0; 1,1,0; % 2 x 45 deg. slant walls
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
    case 16
        % 10 depth 0-100, 7 normal basis vectors
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 7 Screen basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 7ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 0; 1,1,0; % 2 x 45 deg. slant walls
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
    case 17
        % 5 depth 0-50, 7 normal basis vectors
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 7 Grav basis vectors';
        params.metaparams.AxLabel = '5d0-50, 1h, 1v bin, 7GravNorms';
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
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 0; 1,1,0; % 2 x 45 deg. slant walls
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];
    case 18
        % 10 depth 0-100, 7 normal basis vectors
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 7 Grav basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 7GravNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 0; 1,1,0; % 2 x 45 deg. slant walls
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [1,0,0];

%%% --- Depth-only models --- %%%
    case 19

        % 5 depth 0-100, 1 normal basis vector
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];

    case 20
        % 10 depth 0-100, 1 normal basis vector
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        
%%% --- Tiled depth-only models --- %%%
    case 21
        % 5 depth 0-100, 1 normal basis vector, 2x2 screen tiles
        params.metaparams.Descr = '5 depth x 2 horiz x 2 vert bin';
        params.metaparams.AxLabel = '5d0-100, 2h, 2v bin';
        nHorizDivs = 2;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 2;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.ori_norm = 1;
        
    case 22
        % 10 depth 0-100, 1 normal basis vector, 2x2 screen tiles
        params.metaparams.Descr = '10 depth x 2 horiz x 2 vert bin';
        params.metaparams.AxLabel = '10d0-100, 2h, 2v bin';
        nHorizDivs = 2;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 2;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = true;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.ori_norm = 1;
        
    case 23
        % 5 depth 0-100, 1 normal basis vector, 3x3 screen tiles
        params.metaparams.Descr = '5 depth x 3 horiz x 3 vert bin';
        params.metaparams.AxLabel = '5d0-100, 3h, 3v bin';
        nHorizDivs = 3;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 3;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.ori_norm = 1;
        
    case 24
        % 10 depth 0-100, 1 normal basis vector, 3x3 screen tiles
        params.metaparams.Descr = '10 depth x 3 horiz x 3 vert bin';
        params.metaparams.AxLabel = '10d0-100, 3h, 3v bin';
        nHorizDivs = 3;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 3;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = true;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.ori_norm = 1;
%%% --- No depth, 9 orientations --- %%%        
    case 25
        % Default parameters:
        params.metaparams.Descr = '1 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '1d, 1h, 1v bin, 9ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        % nDepthDivs = 1;
        params.DepthDiv = [0,inf];
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
%%% --- Relative depth. --- %%%
    case 26

        % 5 depth 0-1, 1 normal basis vector
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, relative depth 0-1';
        params.metaparams.AxLabel = '5d0-1, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(.1),log10(1),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];

    case 27
        % 10 depth 0-1, 1 normal basis vector
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, relative depth 0-1';
        params.metaparams.AxLabel = '10d0-1, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(.1),log10(1),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
    case 28
        % Add more depth (10), 9 normal basis vectors
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors, relative depth 0-1';
        params.metaparams.AxLabel = '10d0-1, 1h, 1v bin, 9ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(.1),log10(1),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead %% NOTE! This is still fuckt: this direction in the Blender world is supposed to be -1
        params.normParams.removeComponent = [0,0,0];
%%% --- More screen subdivisions (5x5)
    case 29
        % 5 depth 0-100, 1 normal basis vector, 5x5 screen tiles
        params.metaparams.Descr = '5 depth x 5 horiz x 5 vert bin';
        params.metaparams.AxLabel = '5d0-100, 5h, 5v bin';
        nHorizDivs = 5;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 5;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.ori_norm = 1;
        
    case 30
        % 10 depth 0-100, 1 normal basis vector, 5x5 screen tiles
        params.metaparams.Descr = '10 depth x 5 horiz x 5 vert bin';
        params.metaparams.AxLabel = '10d0-100, 5h, 5v bin';
        nHorizDivs = 5;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 5;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = true;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.ori_norm = 1;
        
%%% --- Args 1-7, With sky channel --- %%%
    case 41
        % Arg 1, w/ sky, abs depth
        % Default parameters:
        params.metaparams.Descr = '1 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors, sky';
        params.metaparams.AxLabel = '1d, 1h, 1v bin, 5ScNorms, sky';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 1;
        params.DepthDiv = [0,999];
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
    case 42
        % Arg 25, with sky
        % Default parameters:
        params.metaparams.Descr = '1 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors, sky';
        params.metaparams.AxLabel = '1d, 1h, 1v bin, 9ScNorms, sky';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        % nDepthDivs = 1;
        params.DepthDiv = [0,999];
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
    case 43
        % Arg2 + sky, abs depth
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors, sky';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, 5ScNorms, sky';
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
        params.DepthDiv = [0,d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
    case 44
        % Arg 4, w/ sky (abs depth)
        % Add more normal basis vectors + 0-100 depth
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors, sky';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, 9ScNorms, sky';
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
        params.DepthDiv = [0,d(1:end-1), 999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
    case 45
        % Arg 6, w/ sky (abs depth)
        % Add more depth (10), 5 normal basis vectors
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 5ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1), 999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
    case 46
        % Arg 7, w/ sky (abs depth)
        % Add more depth (10), 9 normal basis vectors
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 9ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1), 999]; 
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead %% NOTE! This is still fuckt: this direction in the Blender world is supposed to be -1
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true; 
        
%%% --- Abs. depth, Depth-only models (5, 7, 10 depths), with sky --- %%%
    case 47
        % 5 depth 0-100, 1 normal basis vector
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, sky';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, sky';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true; 
        
    case 48
        % 7 depths 5-100, 1 normal basis vector
        params.metaparams.Descr = '7 depth x 1 horiz x 1 vert bin, sky';
        params.metaparams.AxLabel = '7d5-100, 1h, 1v bin, sky';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 7;
        % NOTE: mo'better depth divisions:
        d = logspace(log10(5),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
        
    case 49
        % 10 depth 0-100, 1 normal basis vector
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, sky';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, sky';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
%%% --- Revisitation of original params with depth max at 999
    case 50
         % 9 normal vectors, 1 depth, max depth 999 (no sky) (arg 25, with max depth 999)
        params.metaparams.Descr = '1 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '1d, 1h, 1v bin, 9ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        % nDepthDivs = 1;
        params.DepthDiv = [0,999];
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;
    case 51
	% 1 normal, 5 depth, max depth 999 (no sky) 
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 5 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, 5ScNorms';
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
        params.DepthDiv = [0,d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;
    case 52
	% 9 normals, 5 depths, max depth 999 (no sky)
        params.metaparams.Descr = '5 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '5d0-100, 1h, 1v bin, 9ScNorms';
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
        params.DepthDiv = [0,d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;
    case 53
	% 9 normals, 10 depths, max depth 999, no sky
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin, 9ScNorms';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        % NOTE! It is not a terribly easy problem to place equi-distant points
        % around a sphere or half-sphere. See:
        % http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
        % ...for potential improvements in selecting normal bin centers
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; 1,1,1; -1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead %% NOTE! This is still fuckt: this direction in the Blender world is supposed to be -1
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;
    case 54
	% 1 normal, 10 depths, max depth 999, no sky
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [0,d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;
    case 55
	% 5 normal, 1 depths, max depth 999, no sky
        params.metaparams.Descr = '5 norm x 1 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        params.DepthDiv = [0, 999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;

%%% --- Fixing dependent model channels --- %%%
% Should be 1n<5-10>ad1x1<no-w>sky

%%% --- Abs. depth, Depth-only models (5, 7, 10 depths), with sky --- %%%
    case 147
        % 5 depth 0-100, 1 normal basis vector
        params.metaparams.Descr = '5-1=4 depth x 1 horiz x 1 vert bin, sky';
        params.metaparams.AxLabel = '4d0-100, 1h, 1v bin, sky';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true; 
        
    case 148
        % 7 depths 5-100, 1 normal basis vector
        params.metaparams.Descr = '7-1=6 depth x 1 horiz x 1 vert bin, sky';
        params.metaparams.AxLabel = '6d1-100, 1h, 1v bin, sky';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 7;
        % NOTE: mo'better depth divisions:
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
        
    case 149
        % 10 depth 0-100, 1 normal basis vector
        params.metaparams.Descr = '10-1=9 depth x 1 horiz x 1 vert bin, sky';
        params.metaparams.AxLabel = '9d0-100, 1h, 1v bin, sky';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = true;
        
    case 154
        % 1 normal, 10 depths, max depth 999, no sky
        params.metaparams.Descr = '10-1=9 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '9d0-100, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 10;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;        
    
    case 155
        % 1 normal, 5 depths, max depth 999, no sky
        params.metaparams.Descr = '5-1=4 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '4d0-100, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 5;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;              

    case 156
	% 1 normal, 7 depths, max depth 999, no sky
        params.metaparams.Descr = '10 depth x 1 horiz x 1 vert bin';
        params.metaparams.AxLabel = '10d0-100, 1h, 1v bin';
        nHorizDivs = 1;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 1;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % Normalize by depth
        params.depthNormalize = false;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        nDepthDivs = 7;
        d = logspace(log10(1),log10(100),nDepthDivs);
        params.DepthDiv = [d(1:end-1),999]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [0,1,0]; % straight-ahead only
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];
        params.sky_channel = false;      
        
    case 157
        % 9 normals, 10depths, max depth 999, w/ sky, + depthNormalize = True
        params = preprocSceneDepthNormals_GetMetaParams(46);
        params.depthNormalize = true; % true may be better; false to not break legacy code
%%% --- To come: tiled depth-only models, relative depth models, tiled relative depth models --- %%%
    


%%% --- Testing equivalence (or near equivalence) with HoN models: 
    case 201
        % 1 depth 9 normal basis vectors
        params.metaparams.Descr = '1 depth x 9 horiz x 9 vert bin, 9 Screen basis vectors';
        params.metaparams.AxLabel = '1d, 9h, 9v bin, 9ScreenNorms';
        nHorizDivs = 9;
        params.HorizDiv = linspace(0,1,nHorizDivs+1);
        params.HorizDiv(end) = inf;
        nVertDivs = 9;
        params.VertDiv = linspace(0,1,nVertDivs+1);
        params.VertDiv(end) = inf;
        % check on histograms of depth across scenes to verify that 
        % (0,1.0000, 3.1623, 10.0000, 31.6228,inf) is a good division of space
        params.DepthDiv = [0,inf]; 
        %%% Normal bins
        % Centers of normal bins:
        params.normBinCenters = [-1 0 0; 1 0 0; 0 0 -1; 0 0 1; % 4 in-plane axes:
            -1 1 -1; 1,1,-1; -1,1,1; 1,1,1; % 4 45 deg. cube corners
            0,1,0]; % straight-ahead
        % Keep normals in screen coordinates
        params.normParams.removeComponent = [0,0,0];


end



