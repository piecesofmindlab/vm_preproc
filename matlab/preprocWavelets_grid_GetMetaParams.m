function pp = preprocWavelets_grid_GetMetaParams(Arg)
% Usage: params = preprocWavelets_grid_GetMetaParams(Arg)
% 
% Returns params for numbered preprocWavelets_grid presets. 1 and 2 are
% SN's parameters of choice for the natural movie stimuli in Nishimoto et
% al 2011

pp = preprocWavelets_grid;
pp.argNum = Arg;

switch Arg
    case 1
        % smaller motion energy model
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 15 fps
        pp.tfmin = 1.33333; % = 2hz @ 15 fps
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
    case 2
        % larger motion energy model 
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% NOTE! Originally, 3-13 were used for different normalization    %%%
    %%% parameters  for Gabor wavelet models, when ML figured out that  %%%
    %%% the ObjectNormal models, in particular, were NOT at all         %%%
    %%% Gaussian. However, that aspect of preprocessing has been moved  %%%
    %%% to a new section as of 2013.04, so 3-13 are here re-claimed.    %%%
    %%% FOR NOW, the old 'Gabor_128px_<ImType>_<Num>_Ses1' type model   %%%
    %%% names are still in the model database (new-type preproc will    %%%
    %%% not over-write them)                                            %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 3
        % Same as 1, but NO PYRAMID
        % smaller motion energy model
        % STRFlab conventions, housekeeping
        pp.wclass = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % T/F. Include gaussians w/ no spat. freq.
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 1;
        pp.sfmax = 24; %
        pp.sfmin = 24; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % no idea
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
    case 4
        % Same as 2, but NO PYRAMID.
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 1;
        pp.sfmax = 32; %
        pp.sfmin = 32; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % max (min?) SF for which phase is computed
        pp.zeromean = 1; 
    case 5
        % model 1 w/ NO TEMPORAL CHANNELS
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0; %2.66667; % = 4hz @ 15 fps
        pp.tfmin = 0; %1.33333; % = 2hz @ 15 fps
        pp.tsize = 1;
        pp.tf_gaussratio = 1; %10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
    case 6
        % larger motion energy model for multi-session fMRI data sets
        % /ephys? : NO TEMPORAL CHANNELS, w/ pyr, w/ ori
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
    case 7
        % Model 1 (fewer locations), + ori, - pyr, -tf ; directionSelective = true
        % STRFlab conventions, housekeeping
        pp.wclass = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % T/F. Include gaussians w/ no spat. freq.
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 1;
        pp.sfmax = 24; %
        pp.sfmin = 24; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % no idea
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;

    case 8
        % Model 2 (more locations), NO TEMPORAL CHANNELS, NO PYRAMID
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 1;
        pp.sfmax = 32; %
        pp.sfmin = 32; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
    case 9
        % Model 1, w/ NO ORIENTATIONS JUST GAUSSIANS
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 15 fps
        pp.tfmin = 1.33333; % = 2hz @ 15 fps
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
        
    case 10
        % Model 2 (more locations) NO ORIENTATIONS JUST GAUSSIANS
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
        
    case 11
        % Same as 1, but no zero SF channels
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWaveletsNonLinear';
        pp.wclass = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 0; % T/F. Include gaussians w/ no spat. freq.
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % no idea
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.normalize = 0;
        pp.zeromean = 1;
    case 12
        error('reserved for no 0 SF version of argnum2')
    case 13
        % btw 1 and 2, w/ diff pyramid structure
        % smaller motion energy model
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWaveletsNonLinear';
        pp.wclass = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        pp.reduceChannels = NaN; %??
        %pp.gainControl = []; %??
        %pp.gainControlOut = []; %??
        %pp.f_gaussratio = 0.5000; %??
        %pp.fenv_max = 0.3000; %??
        %pp.zeromean_value = 33.9937; % Subtracted off if provided. 
        %pp.gaborparams: [8x2139 single]; % computed in function
        %p.nChan = 2139; % 
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % T/F. Include gaussians w/ no spat. freq.
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 3;
        pp.sfmax = 24; %32; %
        pp.sfmin = 6; %8;%        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % no idea
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.nonLinOutExp = 'log'; % Output nonlinearity
        pp.nonLinOutParam = 1.0000e-05; % Used? no idea.
        pp.normalize = 0;
        pp.zeromean = 1;
        
        
    case 14
        % larger motion energy model for multi-session fMRI data sets/ephys?
        % NO ORIENTATIONS, NO TF
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
    % 15 reserved for ??
    
    case 15
        % Extra large motion energy model (many spatial locations)
        % NO ORIENTATIONS, NO TF
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 42; %32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;            
    case 16
        % larger motion energy model
        % NO TEMPORAL CHANNELS, but with time window = 10
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
    case 17
        % Model 1, w/ no direction selectivity, 4 oris
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 15 fps
        pp.tfmin = 1.33333; % = 2hz @ 15 fps
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 4;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
        
    case 18
        % Model 2, w/ no direction selectivity, 4 oris
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 4;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
        
    case 19
        % Model 1, w/ no direction selectivity, 8 oris
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 15 fps
        pp.tfmin = 1.33333; % = 2hz @ 15 fps
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
        
    case 20
        % Model 2, w/ no direction selectivity, 8 oris
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
    case 21
        % Model 1 grid, NO pyramid, NO TF, NO Ori
    case 22
        % Model 2 grid, NO pyramid, NO TF, NO Ori
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 1;
        pp.sfmax = 32; %
        pp.sfmin = 32; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        

    case 23
        % Model 1, no grid, no pyramid, + ori, 8 oris        
    case 24
        % Model 2 (more locations), no grid, no pyramid, + ori, 8 oris
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 1;
        pp.sfmax = 32; %
        pp.sfmin = 32; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
    case 25
        % Model 1 grid, - pyr, -ori, + tf
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 15 fps
        pp.tfmin = 1.33333; % = 2hz @ 15 fps
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 1;
        pp.sfmax = 24; %
        pp.sfmin = 24; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
        
    case 26
        % Model 2 grid, - pyr, -ori, + tf
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 1;
        pp.sfmax = 32; %
        pp.sfmin = 32; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                     HCP Stimlulus preprocessign                     %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 51
        % smaller motion energy model
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 1.66667; % = 4hz @ 24 fps, w/ 10 frame t limit
        pp.tfmin = 0.83333; % = 2hz @ 24 fps, w/ 10 frame t limit
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
    case 52
        % larger motion energy model 
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 1.66667; % = 4hz @ 24 fps, w/ 10 frame t limit
        pp.tfmin = 0.83333; % = 2hz @ 24 fps, w/ 10 frame t limit
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%       Large Gabor wavelets for scene-selective areas                %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    case 61
        0;
        % WORKING HERE
    case 71
        % ONLY motion channels from arg 1 (Thus, the channels from 71 and 5 combine to make all channels in arg 1)
        % smaller motion energy model
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 2;
        pp.tfmax = 2.66667; % = 4hz @ 15 fps
        pp.tfmin = 1.33333; % = 2hz @ 15 fps
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 0; % NOPE.
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;        
    case 72
        % ONLY motion channels from arg 2 (Thus, the channels from 72 and 6 combine to make all channels in arg 2)
        % larger motion energy model 
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 2;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 0;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;              
        
    case 81
        % smaller motion energy model
        pp = preprocWavelets_grid_GetMetaParams(1);
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 60 fps # was 15
        pp.tfmin = 1.33333; % = 2hz @ 60 fps # was 15
        pp.tsize = 40; % This is the only change that needed making... Yes?
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
    case 82
        % larger motion energy model
        pp = preprocWavelets_grid_GetMetaParams(2);
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 60 fps # was 15
        pp.tfmin = 1.33333; % = 2hz @ 60 fps # was 15
        pp.tsize = 40; % This is the only change that needed making... Yes?
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
    case 83
        % smaller motion energy model
        pp = preprocWavelets_grid_GetMetaParams(1);
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 60 fps # was 15
        pp.tfmin = 1.33333; % = 2hz @ 60 fps # was 15
        pp.tsize = 20; % This is the only change that needed making... Yes?
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
    case 84
        % larger motion energy model
        pp = preprocWavelets_grid_GetMetaParams(2);
        % Temporal frequency params
        pp.tfdivisions = 3;
        pp.tfmax = 2.66667; % = 4hz @ 60 fps # was 15
        pp.tfmin = 1.33333; % = 2hz @ 60 fps # was 15
        pp.tsize = 20; % This is the only change that needed making... Yes?
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;

        
    case 102
        % special case for preprocessing for LocalizedWhiteNoise stim
        pp = preprocWavelets_grid_GetMetaParams(2);
        pp.zeromean_value = 60.3156;
    case 106
        pp = preprocWavelets_grid_GetMetaParams(6);
        pp.zeromean_value = 60.3156;
        
    case 201
        % larger motion energy model for multi-session fMRI data sets
        % /ephys? : NO TEMPORAL CHANNELS, w/ pyr, w/ ori
        % STRFlab conventions, housekeeping
        % BASED ON preset #6; variations by AM to explore parameter space
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        pp.aspect_ratio = 2;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
    case 202
        % larger motion energy model for multi-session fMRI data sets
        % /ephys? : NO TEMPORAL CHANNELS, w/ pyr, w/ ori
        % STRFlab conventions, housekeeping
        % BASED ON preset #6; variations by AM to explore parameter space
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 1;
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        pp.aspect_ratio = 3;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Nested models %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 301
        % Object model only
        % larger motion energy model for multi-session fMRI data sets/ephys?
        % NO ORIENTATIONS, NO TF
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 10; % Different
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; 
        pp.directionSelective = 0;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;               
    case 302
        % Non-SF=0 channels from arg 6
        % TF = 0 only, w/ pyr, w/ ori
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0;
        pp.tfmin = 0;
        pp.tsize = 10; % DIFFERENT
        pp.tf_gaussratio = 1; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 0; % DIFFERENT 
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5; % DIFFERENT 
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;         
    case 303
        % larger motion energy model 
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1;
        pp.wrap_all = 0;
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN;
        % Temporal frequency params
        pp.tfdivisions = 2;
        pp.tfmax = 2.66667;
        pp.tfmin = 1.33333;
        pp.tsize = 10;
        pp.tf_gaussratio = 10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 0; % DIFFERENT
        % Orientation/direction params
        pp.dirdivisions = 8;
        pp.local_dc = 1; % REVISIT ME: zero??
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 32; %
        pp.sfmin = 2; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 3.5; % Governs how closely spaced channels are
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % (whether to use fenv_max for both senv_max and tenv_max) 
        pp.senv_max = 0.3000;
        % Nonlinearities
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;              
    case 1000
        % model 1 w/ NO TEMPORAL CHANNELS
        % STRFlab conventions, housekeeping
        pp.class = 'preprocWavelets_grid';
        pp.show_or_preprocess = 1; % True to preprocess; false to return gabor channels
        pp.verbose = 1;
        pp.gaborcachemode = 0;
        pp.valid_w_index = NaN; % Select particular gabor channels by number
        % Temporal frequency params
        pp.tfdivisions = 1;
        pp.tfmax = 0; %2.66667; % = 4hz @ 15 fps
        pp.tfmin = 0; %1.33333; % = 2hz @ 15 fps
        pp.tsize = 1;
        pp.tf_gaussratio = 1; %10; 
        pp.tenv_max = 0.3000;
        pp.zerotf = 1;
        pp.f_gaussratio = .5;
        % Orientation/direction params
        pp.dirdivisions = 0;
        pp.local_dc = 1; % T/F. Include circular gaussians (w/ no spat. freq.)
        pp.directionSelective = 1;
        % Spatial extent params
        pp.sfdivisions = 5;
        pp.sfmax = 24; %
        pp.sfmin = 1.5; %
        pp.f_step_log = 1; % Applies to both SF and TF?
        pp.std_step = 4; % Governs how closely spaced channels are; a reasonable range is 2.5-4
        pp.sf_gaussratio = 0.6000; % 81 channels @maxsf=24; 9x9 ; 13x13 @maxsf=32
        pp.fenv_mode = 0; % use same env for spatial & temporal gabors
        pp.senv_max = 0.3000;
        pp.wrap_all = 0;
        % Handling phase
        pp.phasemode = 0; % Determines how to do phase (square & sum quadrature pairs, etc)
        pp.phasemode_sfmax = NaN; % No idea
        pp.zeromean = 1;

end
