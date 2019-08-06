Function [stim, params] = preprocWavelets_phase2(rawStim, params)
% function [stim, params] = preprocWavelets(rawStim, params);
%
% A script for preprocessing of stimuli using a Gabor wavelet bais set
%
% INPUT:
%           [rawStim] = A X-by-Y-by-T matrix containing stimuli (movie)
%            [params] = structure that contains parameters for preprocessing
%       .dirdivisions = Number of directions for wavelets (default: 8)
%         .fdivisions = Number of frequencies (default: 5)
%       .veldivisions = Number of velocities (default: 5)
%              .tsize = Number of frames to calculate wavelets (default: 10)
%              .sfmax = The maximum spatial frequency/stimulus size at zero velocity (default: 9)
%              .sfmin = The minimum spatial frequency/stimulus size  at zero velocity (default: 2)
%         .f_step_log = A flag to specify linear or log step of frequency (default: 0)
%              .tfmax = The maximum temporal frequency/stimulus size (default: 3.5)
%      .sf_gaussratio = The ratio between the Gaussian window and spatial frequency (default: 0.5)
%      .tf_gaussratio = The ratio between the Gaussian window and temporal frequency (default: 0.4)
%           .std_step = Spatial separation of each wavelet in terms of sigma of
%                       the Gaussian window (default: 2.5)
%          .phasemode = A parameter to specify how to deal with phase information
%                         0: spectral amplitude (default)
%                         1: linear sin and cos phase ampliture (2x number of wavelets)
%                         2: half-rectified sin and cos phase amplitude (4x number of wavelets)
%                         3: 0+1 (3x number of wavelets)
%                         4: 0+2 (5x number of wavelets)
%                         5: phase, atan2(chout90,chout0)
%                         6: 0+5 (2x number of wavelets)
%                         7: phase, atan2(chout90,chout0), half-rectified
%                         8: 0+7 (3x number of wavelets)
%    .phasemode_sfmax = The maximum spatial frequency to use phase information
%                       For higher frequency wavelets over this value, only
%                       spectral amplitude information are used.  (default: Inf)
% .show_or_preprocess = If this is set to 0, the function returns wavelets
%                       of size(S) * number of channels, instead of preprocessed
%                       stimuli. This may be used for visualization purpose.
%                       If .valid_w_index is also set, this returns only a subset of
%                       wavelets specified by .valid_w_index. (default: 1)
%           .senv_max = The maximum spatial envelope (default: 0.3)
%           .tenv_max = The maximum temporal envelope (default: 0.3)
%           .local_dc = A flag to add localized dc (i.e., 0 spatial freq.) channels (default: 0)
%      .valid_w_index = This is used to specify a subset of wavelets to obtain.
%                       (See .show_or_preprocess)
%          .normalize = A flag to normalize mean and stds for each channel (default: 1)
%            .verbose = a flag for verbose mode (default: 1)
%
% OUTPUT:
%              [stim] = Preprocessed stimuli that can be used for STRF fitting.
%                       NxD matrix, N=sample size, D=dimensions.
%            [params] = structure that contains parameters for preprocessing, with additional fields:
%              .nChan = Number of preprocessed channels 
%                       (dimensionality of each data vector, AKA: D=dimensions)
%        .gaborparams = A set of parameters for each Gabor wavelet.
%                       This is a p-by-D matrix where p is number of parameters (8)
%                       and D is the number of wavelet channels
%                       Each field in gaborparams represents:
%                       [pos_x pos_y direction s_freq t_freq s_size t_size phasevalue]
%                       phasevalue can be 0 to 6, where
%                         0: spectra
%                         1: linear sin transform
%                         2: linear cos transform
%                         3: half-rectified sin transform (positive values)
%                         4: half-rectified sin transform (negative values)
%                         5: half-rectified cos transform (positive values)
%                         6: half-rectified cos transform (negative values)
%                         7: dPhase/dt
%                         8: dPhase/dt (positive values)
%                         9: dPhase/dt (negative values)
%               .stds = standard deviations for each channel (set if .normalize is non-zero)
%              .means = means for each channel (set if normalize is non-zero)
%     .zeromean_value = Offset value of total movie. This is set if .zeromean is non-zero.
%
% EXAMPLE:
%  params = preprocWavelets;
%    returns the default set of parameters.
%
%  [stim, params] = preprocWavelets(S, PARAMS)
%    returns preprocessed stimuli (or wavelets) and parameters
%
% SEE ALSO: make3dgabor, preprocSpectra
% ====================


%%% Set up parameters
if ~exist('params','var')
     params = [];
end
params = setDefaultParameters(params);

if nargin<1 % just called to set the default set of parameters
	stim = params;
	return;
end


start_t = cputime;

stimxytsize = size(rawStim);
if length(stimxytsize) == 2
	stimxytsize = [stimxytsize 1]; % make sure 3 dimensions
end

patchxytsize = [stimxytsize(1:2) params.tsize];
xypixels = prod(patchxytsize(1:2));
verbose = params.verbose;

rawStim = single(rawStim);
rawStim = reshape(rawStim, [prod(stimxytsize(1:2)) stimxytsize(3)]);

if params.show_or_preprocess
	if params.zeromean
		if verbose, fprintf('[[zero mean stimuli]]\n'); end
		if isfield(params, 'zeromean_value')
			rawStim = rawStim - params.zeromean_value;
		else
			thismean = mean(rawStim(:));
			rawStim = rawStim - thismean;
			params.zeromean_value = thismean;
		end
	end
end


%%% Make a list of gabor parameters
if ~isfield(params,'gaborparams') || params.phasemode == 5 || ...
	  params.phasemode == 7
   if verbose, fprintf('Making a list of gabor parameters... '); end
   [gparams] = getGaborParameters(params);
else
    gparams = params.gaborparams;
end
waveletchannelnum = size(gparams,2);

if verbose, fprintf('channel num: %d\n', waveletchannelnum); end

if verbose && any(params.valid_w_index)
	fprintf('Valid channel num: %d\n', length(params.valid_w_index));
end


%%% Set up a matrix to fill-in
if params.show_or_preprocess
	if verbose, disp('Preprocessing...'); end
	stim = zeros(stimxytsize(3), waveletchannelnum, 'single');
else
	if verbose, disp('Making wavelets...'); end
	if ~any(params.valid_w_index)
		gnum = length(waveletchannelnum);
	else
		gnum = length(params.valid_w_index);
	end
	gaborbank = zeros([patchxytsize gnum], 'single');
end


%%% Preprocessing...

% ignore wavelet pixels for speed-up where:
masklimit = 0.001;   %% pixel value < masklimit AND
maskenv_below = 0.1; % spatial envelope < maskenv_below x stimulus size

if params.gaborcachemode==1
    gaborcache = zeros([patchxytsize waveletchannelnum*2], 'single');
end


lastgparam = zeros(8,1);
wcount = 0;
for ii=1:waveletchannelnum

	if any(params.valid_w_index) && ~any(ii==params.valid_w_index), continue, end

	thisgparam = gparams(:,ii);
	thesame = 1;
	if any(thisgparam(1:7) ~=lastgparam(1:7))
		thesame = 0;
	end
	if ~thesame
        if params.gaborcachemode==2
	        gabor0 = params.gaborcache(:,:,:,(ii-1)*2+1);
            gabor90 = params.gaborcache(:,:,:,(ii-1)*2+2);
        else
		    [gabor0 gabor90] = make3dgabor(patchxytsize, [thisgparam(1:end-1); 0]);
        end
        if params.gaborcachemode==1
		    gaborcache(:,:,:,(ii-1)*2+1) = gabor0;
            gaborcache(:,:,:,(ii-1)*2+2) = gabor90;
        end
		lastgparam = thisgparam;
	end
	phaseparam = thisgparam(8);
	if params.show_or_preprocess
		if ~thesame
			gabor0 = reshape(gabor0,[xypixels params.tsize]);
			gabor90 = reshape(gabor90,[xypixels params.tsize]);
			senv = thisgparam(6);
			if senv<maskenv_below
				g0 = find(max(abs(gabor0),[],2)>masklimit);
				chout0 = dotdelay(gabor0(g0,:), rawStim(g0,:));
				g90 = find(max(abs(gabor90),[],2)>masklimit);
				chout90 = dotdelay(gabor90(g90,:), rawStim(g90,:));
			else
				chout0 = dotdelay(gabor0, rawStim);
				chout90 = dotdelay(gabor90, rawStim);
			end
		end
		switch phaseparam
		case 0
			chout = sqrt(chout0.^2 + chout90.^2);
			stim(:,ii) = chout;
		case 1
			chout = chout0;
			stim(:,ii) = chout;
		case 2
			chout = chout90;
			stim(:,ii) = chout;
		case 3
			chout = chout0;
			chout(chout<0) = 0;
			stim(:,ii) = chout;
		case 4
			chout = chout0;
			chout(chout>0) = 0;
			stim(:,ii) = -chout;
		case 5
			chout = chout90;
			chout(chout<0) = 0;
			stim(:,ii) = chout;
		case 6
			chout = chout90;
			chout(chout>0) = 0;
			stim(:,ii) = -chout;
        case 7
            chout = atan2(chout90,chout0);
            dtphase = [0; diff(chout,1,1)];
            dtphase = dtphase+ -2*pi*sign(dtphase).*round(abs(dtphase)./(2*pi));
            stim(:,ii) = dtphase;
        case 8
            chout = atan2(chout90,chout0);
            dtphase = [0; diff(chout,1,1)];
            dtphase = dtphase+ -2*pi*sign(dtphase).* ...
					  round(abs(dtphase)./(2*pi));
            dtphase(dtphase<0) = 0;
            stim(:,ii) = dtphase;
        case 9
            chout = atan2(chout90,chout0);
            dtphase = [0; diff(chout,1,1)];
            dtphase = dtphase+ -2*pi*sign(dtphase).* ...
					  round(abs(dtphase)./(2*pi));
            dtphase(dtphase>0) = 0;
            stim(:,ii) = -dtphase;
        case 10
            chout = atan2(chout90,chout0);
            stim(:,ii) = chout;
        end
	else
		wcount = wcount + 1;
		switch phaseparam
		case {1,3,4}
			gaborbank(:,:,:,wcount) = gabor0;
		case {0,2,5,6,7,8,9, 10}
			gaborbank(:,:,:,wcount) = gabor90;
		end
	end

	if verbose
		if mod(ii, 50) == 0, fprintf('.'), end
		if mod(ii, 1000) == 0, fprintf(' %d channels done.\n', ii), end
	end
end
if verbose && params.show_or_preprocess, fprintf(' %d channels done.\n', ii); end

if params.gaborcachemode==1
    params.gaborcache = gaborcache;
    params.gaborcachemode = 2;
end


if verbose
	disp(sprintf('Wavelet preprocessing done in %.1f min.', (cputime-start_t)/60));
	if params.show_or_preprocess
		disp(sprintf('%d channels, %d samples', size(stim,2), size(stim,1)));
	else
		disp(sprintf('%d channels', size(gaborbank,4)));
	end
end


if params.show_or_preprocess
    if params.phasemode==5 || params.phasemode==6 || params.phasemode==7 ...
		  || params.phasemode==8
        pind = find(gparams(8,:)==7 | gparams(8,:)==8 | gparams(8,:)==9);
        disp('thresholding phase channels...');
        for p=1:length(pind)
            phasech = stim(:,pind(p));
            if gparams(8,pind(p)-1) == 0 % look for the
                                         % corresponding amplitude channel
                ampch = stim(:,pind(p)-1);
            else
                ampch = stim(:,pind(p)-2);
            end
            a_thresh = nanstd(ampch)*params.a_thresh;
            avalind = ampch>a_thresh;
            avalind = and(avalind, [0; avalind(1:end-1)]);
            phasech(~avalind) = 0;
            stim(:,pind(p)) = phasech;
        end
        if params.phasemode==5 || params.phasemode==7 % return dPhase/dt channels only
            stim = stim(:,pind);
            gparams = gparams(:,pind);
            fprintf('Using only dPhase/dt channels: %d\n', size(stim,2));
        end
    end

	if params.normalize
		if isfield(params, 'means') % Already preprocessed. Use the means and stds
			global s; s = stim; clear stim; % a trick to modify stim without copying it
			norm_std_mean_global(params.stds, params.means);
			stim = s; clear s;
		else
			global s; s = stim; clear stim; % a trick to modify stim without copying it
			[stds, means] = norm_std_mean_global();
			stim = s; clear s;
			params.means = means;
			params.stds = stds;
		end
	end
else % return gabors, not pre-processed data
	stim = gaborbank;
end

params.gaborparams = gparams;
params.nChan = size(gparams,2);

return;



%---------------------------------------------------------------------
%  Default parameter settings
%---------------------------------------------------------------------

function params = setDefaultParameters(params)

if ~isfield(params, 'dirdivisions')
	 params.dirdivisions = 8;
end

if ~isfield(params, 'fdivisions')
	 params.fdivisions = 5;
end

if ~isfield(params, 'veldivisions')
	 params.veldivisions = 5;
end

if ~isfield(params, 'tsize')
	 params.tsize = 9;
end

if ~isfield(params, 'sfmax')
	 params.sfmax = 9.0;
end

if ~isfield(params, 'sfmin')
	 params.sfmin = 2.0;
end

if ~isfield(params, 'f_step_log')
	 params.f_step_log = 0;
end

if ~isfield(params, 'tfmax')
	 params.tfmax = 3.0;
end

if ~isfield(params, 'sf_gaussratio')
	 params.sf_gaussratio = 0.5;
end

if ~isfield(params, 'tf_gaussratio')
	 params.tf_gaussratio = 0.4;
end

if ~isfield(params, 'std_step')
	 params.std_step = 2.5;
end

if ~isfield(params, 'phasemode')
	params.phasemode = 0;
	params.phasemode_sfmax = Inf;
end

if ~isfield(params, 'senv_max')
	 params.senv_max = 0.3;
end

if ~isfield(params, 'tenv_max')
	 params.tenv_max = 0.3;
end

if ~isfield(params, 'local_dc')
	params.local_dc = 0;
end

if ~isfield(params, 'normalize')
	 params.normalize = 1;
end

if ~isfield(params, 'zeromean')
	 params.zeromean = 1;
end

if ~isfield(params, 'show_or_preprocess')
	params.show_or_preprocess = 1;
end

if ~isfield(params, 'wrap_all')
	params.wrap_all = 0;
end

if ~isfield(params, 'verbose')
	params.verbose = 1;
end

if ~isfield(params, 'directionSelective')
	 params.directionSelective = 1;
end


if ~isfield(params, 'gaborcachemode')
     params.gaborcachemode = 0;
end


if ~isfield(params, 'valid_w_index')
	params.valid_w_index = NaN;
end

if ~isfield(params, 'fenv_mode')
	params.fenv_mode = 0;
else
    if ~isfield(params, 'f_gaussratio')
        params.f_gaussratio = 0.5;
    end
    if ~isfield(params, 'fenv_max')
        params.fenv_max = 0.3;
    end
    
end

params.class = 'preprocWavelets_phase';

return;

%---------------------------------------------------------------------
% Making a list of gabor parameters
%---------------------------------------------------------------------
function gparams = getGaborParameters(params)

velangle_array = (0:params.veldivisions-1)/params.veldivisions*90;
sfmin_normalized = params.sfmin/params.sfmax;

if params.f_step_log
	freq_array = logspace(log10(sfmin_normalized), log10(1), params.fdivisions);
else
	freq_array = linspace(sfmin_normalized, 1, params.fdivisions);
end
dir_array = (0:params.dirdivisions-1)/params.dirdivisions*360;

switch params.phasemode
case 0  % spectral amplitudes
	pmarray = [0];
case 1  % linear sin and cos transform amplitudes
	pmarray = [1 2];
case 2  % half rectified sin and cos amplitudes
	pmarray = [3 4 5 6];
case 3  % 0+1
	pmarray = [0 1 2];
case 4  % 0+2
	pmarray = [0 3 4 5 6];
case 5  % dphase: atan2(sin,cos)
    pmarray = [0 7];
case 6  % 0+5
    pmarray = [0 7];
case 7  % dphase: atan2(sin,cos), half-rectified
    pmarray = [0 8 9];
case 8  % 0+7
    pmarray = [0 8 9];
case 9  % phase
    pmarray = [10];
case 10  % 0+9
    pmarray = [0 10];
end

dirstart = 1;
if params.local_dc
	dirstart = 0; %% add local dc channels
end

waveletcount = 0;
gparams = zeros(8, 20000, 'single'); % prepare for some amount of memory for gparams

for vi=1:params.veldivisions
	velangle = velangle_array(vi);
	for fi = 1:params.fdivisions
		freq = freq_array(fi);
		sf = cos(velangle*pi/180)*params.sfmax*freq;
		tf = sin(velangle*pi/180)*params.tfmax*freq;


        if params.fenv_mode
            f = sqrt(sf.^2+tf.^2);
            fenv = min([params.fenv_max 1/f*params.f_gaussratio]);
            tenv = fenv;
            senv = fenv;
        else
            senv = params.senv_max;
            if sf ~= 0
                senv = min([params.senv_max 1/sf*params.sf_gaussratio]);
            end    
            tenv = params.tenv_max;
            if tf ~= 0
                tenv = min([params.tenv_max 1/tf*params.tf_gaussratio]);
            end
        end
        
        
% 		senv = min([params.senv_max 1/sf*params.sf_gaussratio]);
% 		if tf ~= 0
% 			tenv = min([params.tenv_max 1/tf*params.tf_gaussratio]);
% 		else
% 			tenv = params.tenv_max;
%         end

        if params.directionSelective == 0
            tf = tf + i;
        end
        
		numsps2 =floor((1-senv*params.std_step)/(params.std_step*senv)/2);
		numsps2 = max([numsps2 0]);
        if numsps2>=1 && params.wrap_all
            numsps2 = numsps2 + 1;
        end
		centers = senv*params.std_step*(-numsps2:numsps2) + 0.5;
		[cx cy] = meshgrid(centers, centers);

		thisnumdirs = length(dir_array);
		if velangle == 0 || params.directionSelective == 0
			thisnumdirs = ceil(thisnumdirs/2);  % use only ~180 deg
		end
		if freq == 0
			thisnumdirs = 1;
		end
		for xyi = 1:length(cx(:))
			xcenter = cx(xyi);
			ycenter = cy(xyi);
			for diri = dirstart:thisnumdirs
				if diri
					dir = dir_array(diri); thissf = sf;
				else
					dir = 0; thissf = 0; % local dc channels
				end
				if  sf >= params.phasemode_sfmax
					waveletcount = waveletcount+1;
					thisgparam = [xcenter ycenter dir thissf tf senv tenv 0];
					gparams(:,waveletcount) = thisgparam;
				else
					for pmod = pmarray
						waveletcount = waveletcount+1;
						thisgparam = [xcenter ycenter dir thissf tf senv tenv pmod];
						gparams(:,waveletcount) = thisgparam;
					end
				end
			end
		end
	end
end

gparams = gparams(:,1:waveletcount);

