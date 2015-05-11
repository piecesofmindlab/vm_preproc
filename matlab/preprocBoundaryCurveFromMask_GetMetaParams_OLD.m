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
params.metaparams.preset(1) = Arg(1);
switch Arg(1)
    % first-step processing presets.
    case 1
        params.metaparams.descr1 = 'First pass; 3 scales, smoothing, crop';
        % Default images/curve smoothing parameters for 3 scales @ 16,8,4
        params.Is_SmoothImage = true;
        params.ImSmoothSTD = [5,4,2];
        params.Is_SmoothCurve = true;
        params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
        params.CurvSmoothSz = [10,10,10]; % extent of smoothing envelope for each scale
        params.CollapseBinBy = 'Max'; % How to summarize over bins of curvature
        params.MaskThresh = 5; %for uint8 images
        params.nScales = 3; % Check below that other fields have 3 (or nScales) entries?
        params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
        params.ImBin_Granularity = 20; % Curvaure will be computed at Bin_Granularity * Scale size,
        % and then averaged to get a single curvature value at the specified scale
        params.ScalesDegrees = []; %? necessary?
        % For smoothing image / contours:
        params.FlattenInfCurvBy = 'crop'; % For now (2011.07.28), simply reduce curvature values > 1 or < -1 to 1 or -1        
    case 2
        params.metaparams.descr1 = '3 scales, smoothing, sigmoid';
        % Default images/curve smoothing parameters for 3 scales @ 16,8,4
        params.Is_SmoothImage = true;
        params.ImSmoothSTD = [5,4,2];
        params.Is_SmoothCurve = true;
        params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
        params.CurvSmoothSz = [10,10,10]; % extent of smoothing envelope for each scale
        params.CollapseBinBy = 'Max'; % How to summarize over bins of curvature
        params.MaskThresh = 5; %for uint8 images
        params.nScales = 3; % Check below that other fields have 3 (or nScales) entries?
        params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
        params.ImBin_Granularity = 20; % Curvaure will be computed at Bin_Granularity * Scale size,
        % and then averaged to get a single curvature value at the specified scale
        params.ScalesDegrees = []; %? necessary?
        % For smoothing image / contours:
        params.FlattenInfCurvBy = 'sigmoid'; % For now (2011.07.28), simply reduce curvature values > 1 or < -1 to 1 or -1
    case 3
        params.metaparams.descr1 = '3 scales, smoothing, sigmoid, + normalized curv in bins';
        % Default images/curve smoothing parameters for 3 scales @ 16,8,4
        params.Is_SmoothImage = true;
        params.ImSmoothSTD = [5,4,2];
        params.Is_SmoothCurve = true;
        params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
        params.CurvSmoothSz = [10,10,10]; % extent of smoothing envelope for each scale
        params.CollapseBinBy = 'NormMax'; % How to summarize over bins of curvature
        params.MaskThresh = 5; %for uint8 images
        params.nScales = 3; % Check below that other fields have 3 (or nScales) entries?
        params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
        params.ImBin_Granularity = 10; % Curvaure will be computed at Bin_Granularity * Scale size,
        % and then averaged to get a single curvature value at the specified scale
        params.ScalesDegrees = []; %? necessary?
        % For smoothing image / contours:
        params.FlattenInfCurvBy = 'sigmoid'; % For now (2011.07.28), simply reduce curvature values > 1 or < -1 to 1 or -1
    case 4
        params.metaparams.descr1 = '3 scales, smoothing, sigmoid, normalized curv, smaller bins (10)';
        % Default images/curve smoothing parameters for 3 scales @ 16,8,4
        params.Is_SmoothImage = true;
        params.ImSmoothSTD = [5,4,2];
        params.Is_SmoothCurve = true;
        params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
        params.CurvSmoothSz = [10,10,10]; % extent of smoothing envelope for each scale
        params.CollapseBinBy = 'NormMax'; % How to summarize over bins of curvature
        params.MaskThresh = 5; %for uint8 images
        params.nScales = 3; % Check below that other fields have 3 (or nScales) entries?
        params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
        params.ImBin_Granularity = 10; % Curvaure will be computed at Bin_Granularity * Scale size,
        % and then averaged to get a single curvature value at the specified scale
        params.ScalesDegrees = []; %? necessary?
        % For smoothing image / contours:
        params.FlattenInfCurvBy = 'sigmoid'; % For now (2011.07.28), simply reduce curvature values > 1 or < -1 to 1 or -1
    otherwise
        
        error('Unknown preset for step 1 of processing!')
                
end

params.metaparams.preset(2) = Arg(2);
switch Arg(2)
    % second-step processing presets.
    case 1
        params.metaparams.descr2 = '3 temporal scales, 3 bins pos/neg';
        % all parameters for binning curvature / collapsing data over time
        params.Is_AbsCurve = false;
        params.Is_BinCurve = true;
        params.Is_Rectify = false;
        params.CurveBins = [-1,-.05 .05,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 2.6666667;
        params.tfmin = 1.3333333;
        params.tfdivisions = 3;
        params.zerotf = true;
    case 2
        params.metaparams.descr2 = '3 temporal scales, 3 bins pos only';
        % all parameters for binning curvature / collapsing data over time
        params.Is_AbsCurve = true;
        params.Is_BinCurve = true;
        params.Is_Rectify = false;
        params.CurveBins = [0,.03,.3,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 2.6666667;
        params.tfmin = 1.3333333;
        params.tfdivisions = 3;
        params.zerotf = true;
    case 3
        params.metaparams.descr2 = '3 temporal scales, 5 bins pos/neg';
        params.Is_AbsCurve = false;
        params.Is_BinCurve = true;
        params.Is_Rectify = false;
        params.CurveBins = [-1,-.3,-.03,.03,.3,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 2.6666667;
        params.tfmin = 1.3333333;
        params.tfdivisions = 3;
        params.zerotf = true;
    case 4
        params.metaparams.descr2 = '2 temporal scales, rectified pos/neg only';
        % This discounts a role for zero curvature... how to account for
        % that? 
        params.Is_AbsCurve = false;
        params.Is_BinCurve = false;
        params.Is_Rectify = true;
        params.CurveBins = [-inf,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 1.3333333;
        params.tfmin = 1.3333333;
        params.tfdivisions = 2;
        params.zerotf = true;
    case 5
        params.metaparams.descr2 = '2 temporal scales, rectified pos/neg only, sqrt nonlinearity on output';
        % This discounts a role for zero curvature... how to account for
        % that? 
        params.Is_Normalize = false;
        params.nonLinearOut = 'sqrt';
        params.Is_AbsCurve = false;
        params.Is_BinCurve = false;
        params.Is_Rectify = true;
        params.CurveBins = [-inf,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 1.3333333;
        params.tfmin = 1.3333333;
        params.tfdivisions = 2;
        params.zerotf = true;
    case 6
        params.metaparams.descr2 = '2 temporal scales, rectified pos/neg only, sqrt nonlinearity on output, z-normalized';
        % This discounts a role for zero curvature... how to account for
        % that? 
        params.Is_Normalize = true;
        params.nonLinearOut = 'sqrt';
        params.Is_AbsCurve = false;
        params.Is_BinCurve = false;
        params.Is_Rectify = true;
        params.CurveBins = [-inf,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 1.3333333;
        params.tfmin = 1.3333333;
        params.tfdivisions = 2;
        params.zerotf = true;
    case 7
        params.metaparams.descr2 = '2 temporal scales, absolute curvature, sqrt nonlinearity on output, NO z-normalized';
        % This discounts a role for zero curvature... how to account for
        % that? 
        params.Is_Normalize = false;
        params.nonLinearOut = 'sqrt';
        params.Is_AbsCurve = true;
        params.Is_BinCurve = false;
        params.Is_Rectify = false;
        params.CurveBins = [-inf,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 1.3333333;
        params.tfmin = 1.3333333;
        params.tfdivisions = 2;
        params.zerotf = true;
    case 8
        params.metaparams.descr2 = '2 temporal scales, absolute curvature, sqrt nonlinearity on output, z-normalized';
        % This discounts a role for zero curvature... how to account for
        % that? 
        params.Is_Normalize = true;
        params.nonLinearOut = 'sqrt';
        params.Is_AbsCurve = true;
        params.Is_BinCurve = false;
        params.Is_Rectify = false;
        params.CurveBins = [-inf,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 1.3333333;
        params.tfmin = 1.3333333;
        params.tfdivisions = 2;
        params.zerotf = true;
    case 10
        params.metaparams.descr2 = 'BASIC: 2 temporal scales, +/- curvature, no nonlinearity on output, no norm';
        % This discounts a role for zero curvature... how to account for
        % that? 
        params.Is_Normalize = false;
        params.nonLinearOut = 'none';
        params.Is_AbsCurve = false;
        params.Is_BinCurve = false;
        params.Is_Rectify = false;
        params.CurveBins = [-inf,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 1.3333333;
        params.tfmin = 1.3333333;
        params.tfdivisions = 2;
        params.zerotf = true;
    case 11
        params.metaparams.descr2 = 'BASIC2: 2 temporal scales, +/- curvature, sqrt nonlinearity on output, no norm';
        % This discounts a role for zero curvature... how to account for
        % that? 
        params.Is_Normalize = false;
        params.nonLinearOut = 'sqrt';
        params.Is_AbsCurve = false;
        params.Is_BinCurve = false;
        params.Is_Rectify = false;
        params.CurveBins = [-inf,inf]; % Bin boundaries for curvature bins
        params.nFramesPerTR = 30;
        params.tsize = 10; % SN uses 10 for motion energy...  % temporal window of gaussian, in frames (stim presented at 15 fps)
        params.tfmax = 1.3333333;
        params.tfmin = 1.3333333;
        params.tfdivisions = 2;
        params.zerotf = true;

    otherwise
        error('Unknown preset for step 2 of processing!')
end

