function params = preprocIntegralCurvature_GetMetaParams(ArgNum)
% Usage: params = preprocIntegralCurvature_GetMetaParams(ArgNum)
% 
% Get numbered arguments for preprocIntegralCurvature
% 
% ML 2013.08.30

params = preprocIntegralCurvature;
params.class = 'preprocIntegralCurvature';

switch ArgNum
    case 1
        % Basics: 
        params.scale = [8]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1; % % NOT CHANGED below yet. by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'none'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 2
        % Basics, multi-scale (2 scales)
        params.scale = [8,16]; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'none'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 3
        % Basics, multi-scale (2 scales), absolute
        params.scale = [8,16]; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 4
        % Basics, multi-scale (2 scales), rectified
        params.scale = [8,16]; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'rectify'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% --- Different scale options --- %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 5
        % Single scale (8) w/ absolute curvature
        params.scale = [8]; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false; 
    case 6
        % Single scale (12) w/ absolute curvature
        params.scale = [12]; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false; 
    case 7
        % Single-scale (16), absolute
        params.scale = [16]; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false; 
    case 8
        % Single-scale (24), absolute
        params.scale = [24]; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false; 
    case 9
        % Single-scale (8), more bins
        params.scale = 8; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = .5; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false;
    case 10
        % Single-scale (16), more bins
        params.scale = 16; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = .5; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false;
    case 11
        % Single-scale (16), more bins
        params.scale = 24; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = .5; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false;
    case 12        
        % Single-scale (24), more bins
        params.scale = 24; % gives 15 x 15, 5x5 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = .3333; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false;
    case 13
        % Multi-scale, all scales (8,12,16,24)
        params.scale = [8,12,16,24]; % 
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = [1.5,1,.75,1/6+.005]; %10,10,10,15 % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false;
    case 14
        % Multi-scale, all scales @ 10 bins (8,12,16,24)
        params.scale = [8,12,16,24]; % 
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = [1.5,1,.75,.5]; %10,10,10,15 % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false;
    case 15
        % Multi-scale, 2 scales @ 10 bins (8,12,16,24)
        params.scale = [12,24]; % 
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv'
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none';
        params.Is_FillHoles = true;
        params.blur = 'gaussian';
        params.dsMethod = 'nearest'; % 'bilinear'
        params.nansub = 0; % 1i;
        params.dsFactor = [1,.5]; %10,10 % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true;
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
        params.Is_Recache = false;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Grid search for single radii of curvature, bin scale %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 101
        % r=8,b=30
        params.scale = [8]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = .5; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 102
        % r=8,b=15
        params.scale = [8]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 103
        % r=8,b=10
        params.scale = [8]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1.5; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 104
        % r=8,b=7
        params.scale = [8]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 2; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 105
        % r=8,b=5
        params.scale = [8]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 3; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 106
        % r=12,b=30
        params.scale = [12]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = .335; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 107
        % r=12,b=15
        params.scale = [12]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = .666; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 108
        % r=12,b=10
        params.scale = [12]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 109
        % r=12,b=7
        params.scale = [12]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1.335; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 110
        % r=12,b=5
        params.scale = [12]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 2; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';        
    case 111
        % r=16,b=30
        params.scale = [16]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = .255; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 112
        % r=16,b=15
        params.scale = [16]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = .5; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 113
        % r=16,b=10
        params.scale = [16]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = .75; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 114
        % r=16,b=7
        params.scale = [16]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 115
        % r=16,b=5
        params.scale = [16]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1.5; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 116
        % r=24,b=30
        params.scale = [24]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1/3+.005; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 117
        % r=24,b=15
        params.scale = [24]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1/6+.005; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 118
        % r=24,b=10
        params.scale = [24]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = .5; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 119
        % r=24,b=7
        params.scale = [24]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = .74; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
    case 120
        % r=24,b=5
        params.scale = [24]; % gives 15 x 15 grid of locations
        params.curvMethod = 'forloop'; % [Change 'forLoop' it sucks] 'conv' % NOT CHANGED: do it the good way. think about re-doing all w/ better comp. by edges. Maybe.
        params.mergeObjects = 'last'; % 'first'; 'last'; 'none'; % NOT CHANGED below yet
        params.Is_FillHoles = true; % NOT CHANGED below yet.
        params.blur = 'gaussian'; % NOT CHANGED below yet.
        params.dsMethod = 'nearest'; % 'bilinear' % NOT CHANGED below yet.
        params.nansub = 0; % 1i; % NOT CHANGED below yet.
        params.dsFactor = 1; % by default, downsample to bins the size of the diameter of the disk used to compute curvature. dsFactor is a multiplier for diameter: smaller = more bins
        params.normalizeByContour = true; % Change? 
        params.signOpt = 'absolute'; % rectify, absolute, bin, etc.
        params.tmpPath = '/auto/k8/tempcache/';
end