function params = preprocBoundaryCurveFromMask_GetMetaParams(Arg)
% Usage: params = preprocBoundaryCurveFromMask_GetMetaParams(Arg)
% 
% Function to get parameter pre-sets for two different step of processing.
% Step 1 - specified by first argument - is everything to do with curvature
% processing. Step 2 is everything after (having to do with collapsing
% values over time). These are specified separately because step 1 takes
% considerably longer than step2. Thus an intermediate file will be stored
% after step 1 to save computational time for step2 variants. 
% 
%

params = preprocBoundaryCurveFromMask;
params.class = 'preprocBoundaryCurveFromMask';
params.metaparams.preset(1) = Arg(1);
switch Arg(1)
    % first-step processing presets.
    case 1
        params.metaparams.Descr = '17x17 spatial bins, 1 scale, sigmoid squash, Max + rectify within bins';
        params.metaparams.AxLabel = '17x17 bin, max curv + rectify';
        % Default images/curve smoothing parameters for 3 scales @ 16,8,4
        % First-stage processing
        params.Scales = [17]; % one scale
        params.ImSmoothSTD = [5]; % Leave empty for no smoothing
        params.CurvSmoothSTD = [3]; %1.5; % STD of smoothing Gaussian for each scale
        params.ImBinSzPx = 16; % Curvaure will be computed at ImBinSzPx * Scale size,
        params.MaskThresh = 5; %for uint8 images
        params.BinFn = {{'mlMaxPosNeg'},{'curvRectify'}}; % How to summarize over bins of curvature
        params.nDimsPerBin = 2; % This could be computed, but given the number of variations of BinFn, it's easier to specify it explictly
        params.DimValues = {'pos','neg'}; % For later labels / visualization
        params.FlattenInfCurvFn = {'mlSquash',-1,1}; % function + arguments for reducing large / infinite values of curvature
        params.Is_FillHoles = true; % false = do not fill holes, incorporate holes in objects into boundary curvature
        params.Is_ClipOccluded = true;
        params.Is_Normalize = true;
    case 2
        params.metaparams.Descr = '17x17 spatial bins, 1 scale, sigmoid squash, Max + soft bin';
        params.metaparams.AxLabel = '17x17 bin, max curv + soft bin';
        % Default images/curve smoothing parameters for 3 scales @ 16,8,4
        % First-stage processing
        params.Scales = [17]; % one scale
        params.ImSmoothSTD = [5]; % Leave empty for no smoothing
        params.CurvSmoothSTD = [3]; %1.5; % STD of smoothing Gaussian for each scale
        params.ImBinSzPx = 16; % Curvaure will be computed at ImBinSzPx * Scale size,
        params.MaskThresh = 5; %for uint8 images
        % Args for curvSoftBinSum are: 
        % (<k vector (not given here),<bin centers>, <bin width>,<div by>)
        % div by is either a constant (to equate for size of each bin) or,
        % if not included, defaults to the number of points of curvature in
        % the bin (thus curvature normalized by length of curvature...?
        % though this seems shitty... re-do this one?)
        params.BinFn = {{'mlMaxPosNeg'},{'curvSoftBinSum',-1:.5:1,.5,20}}; % How to summarize over bins of curvature
        params.nDimsPerBin = 5; % This could be computed, but given the number of variations of BinFn, it's easier to specify it explictly
        params.DimValues = {'bin',-1,.5,0,.5,1}; % For later labels / visualization
        params.FlattenInfCurvFn = {'mlSquash',-1,1}; % function + arguments for reducing large / infinite values of curvature
        params.Is_FillHoles = true; % false = do not fill holes, incorporate holes in objects into boundary curvature
        params.Is_ClipOccluded = true;
        params.Is_Normalize = true;
    case 3
        params.metaparams.Descr = '17x17 spatial bins, 1 scale, sigmoid squash, soft bin only';
        params.metaparams.AxLabel = '17x17 bin, soft bin';
        % Default images/curve smoothing parameters for 3 scales @ 16,8,4
        % First-stage processing
        params.Scales = [17]; % one scale
        params.ImSmoothSTD = [5]; % Leave empty for no smoothing
        params.CurvSmoothSTD = [3]; %1.5; % STD of smoothing Gaussian for each scale
        params.ImBinSzPx = 16; % Curvaure will be computed at ImBinSzPx * Scale size,
        params.MaskThresh = 5; %for uint8 images
        params.BinFn = {{'curvSoftBinSum',-1:.5:1,.5,20}}; % How to summarize over bins of curvature
        params.nDimsPerBin = 5; % This could be computed, but given the number of variations of BinFn, it's easier to specify it explictly
        params.DimValues = {'bin',-1,.5,0,.5,1}; % For later labels / visualization
        params.FlattenInfCurvFn = {'mlSquash',-1,1}; % function + arguments for reducing large / infinite values of curvature
        params.Is_FillHoles = true; % false = do not fill holes, incorporate holes in objects into boundary curvature
        params.Is_ClipOccluded = true;
        params.Is_Normalize = true;
    case 4
        params.metaparams.Descr = '19x19 spatial bins, 1 scale, sigmoid squash, Max + rectify within bins';
        params.metaparams.AxLabel = '19x19 bin, max curv + rectify';
        % Default images/curve smoothing parameters for 3 scales @ 16,8,4
        % First-stage processing
        params.Scales = [19]; % one scale
        params.ImSmoothSTD = [5]; % Leave empty for no smoothing
        params.CurvSmoothSTD = [3]; %1.5; % STD of smoothing Gaussian for each scale
        params.ImBinSzPx = 16; % Curvaure will be computed at ImBinSzPx * Scale size,
        params.MaskThresh = 5; %for uint8 images
        params.BinFn = {{'mlMaxPosNeg'},{'curvRectify'}}; % How to summarize over bins of curvature
        params.nDimsPerBin = 2; % This could be computed, but given the number of variations of BinFn, it's easier to specify it explictly
        params.DimValues = {'pos','neg'}; % For later labels / visualization
        params.FlattenInfCurvFn = {'mlSquash',-1,1}; % function + arguments for reducing large / infinite values of curvature
        params.Is_FillHoles = true; % false = do not fill holes, incorporate holes in objects into boundary curvature
        params.Is_ClipOccluded = true;
        params.Is_Normalize = true;
        
%     case 2
%         params.metaparams.descr1 = '3 scales, smoothing, sigmoid';
%         % Default images/curve smoothing parameters for 3 scales @ 16,8,4
%         params.Is_SmoothImage = true;
%         params.ImSmoothSTD = [5,4,2];
%         params.Is_SmoothCurve = true;
%         params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
%         params.CurvSmoothSz = [10,10,10]; % extent of smoothing envelope for each scale
%         params.CollapseBinBy = 'Max'; % How to summarize over bins of curvature
%         params.MaskThresh = 5; %for uint8 images
%         params.nScales = 3; % Check below that other fields have 3 (or nScales) entries?
%         params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
%         params.ImBin_Granularity = 20; % Curvaure will be computed at Bin_Granularity * Scale size,
%         % and then averaged to get a single curvature value at the specified scale
%         params.ScalesDegrees = []; %? necessary?
%         % For smoothing image / contours:
%         params.FlattenInfCurvBy = 'sigmoid'; % For now (2011.07.28), simply reduce curvature values > 1 or < -1 to 1 or -1
%     case 3
%         params.metaparams.descr1 = '3 scales, smoothing, sigmoid, + normalized curv in bins';
%         % Default images/curve smoothing parameters for 3 scales @ 16,8,4
%         params.Is_SmoothImage = true;
%         params.ImSmoothSTD = [5,4,2];
%         params.Is_SmoothCurve = true;
%         params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
%         params.CurvSmoothSz = [10,10,10]; % extent of smoothing envelope for each scale
%         params.CollapseBinBy = 'NormMax'; % How to summarize over bins of curvature
%         params.MaskThresh = 5; %for uint8 images
%         params.nScales = 3; % Check below that other fields have 3 (or nScales) entries?
%         params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
%         params.ImBin_Granularity = 10; % Curvaure will be computed at Bin_Granularity * Scale size,
%         % and then averaged to get a single curvature value at the specified scale
%         params.ScalesDegrees = []; %? necessary?
%         % For smoothing image / contours:
%         params.FlattenInfCurvBy = 'sigmoid'; % For now (2011.07.28), simply reduce curvature values > 1 or < -1 to 1 or -1
%     case 4
%         params.metaparams.descr1 = '3 scales, smoothing, sigmoid, normalized curv, smaller bins (10)';
%         % Default images/curve smoothing parameters for 3 scales @ 16,8,4
%         params.Is_SmoothImage = true;
%         params.ImSmoothSTD = [5,4,2];
%         params.Is_SmoothCurve = true;
%         params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
%         params.CurvSmoothSz = [10,10,10]; % extent of smoothing envelope for each scale
%         params.CollapseBinBy = 'NormMax'; % How to summarize over bins of curvature
%         params.MaskThresh = 5; %for uint8 images
%         params.nScales = 3; % Check below that other fields have 3 (or nScales) entries?
%         params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
%         params.ImBin_Granularity = 10; % Curvaure will be computed at Bin_Granularity * Scale size,
%         % and then averaged to get a single curvature value at the specified scale
%         params.ScalesDegrees = []; %? necessary?
%         % For smoothing image / contours:
%         params.FlattenInfCurvBy = 'sigmoid'; % For now (2011.07.28), simply reduce curvature values > 1 or < -1 to 1 or -1
    otherwise
        
        error('Unknown preset for step 1 of processing!')
                
end
