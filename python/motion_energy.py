# Compute motion energy
from __future__ import division
import itertools as itools
import numpy as np
import time

def _make_gabor():
    pass

def _define_filter_pyramid(spatial_freqs=(), 
                           temporal_freqs=(0, 2, 4),
                           orientations=(0, 45, 90, 135, 180, 225, 270, 315),
                           locations=None, # Fixed by SF if not None
                           stimulus_size_degrees=(22, 22), # For UCB setup. SPECIFY!
                           stimulus_size_pixels=(96, 96),
                           stimulus_hz=15,
                           phase_mode = None, # define me
                           ):
    """Define filter pyramid"""

    filters = []
    for sf, tf, ori, loc in itools.product(spatial_freqs, temporal_freqs, orientations, locations):
        filters.append(dict(xytsize=None,
                            center_x=x,
                            center_y=y,
                            orientation=ori,
                            spatial_frequency=sf,
                            temporal_frequency=tf,
                            stimulus_size_degrees=stimulus_size_degrees,
                            stimulus_size_pixels=stimulus_size_pixels)
                       )
    return filters

def make_gabors(gabor_params):
    # formerly handled by show_or_preproces flag 
    wcount = 0 # ??
    for gp in gabor_params:
        # NOT WORKING WIP
        wcount += 1;
        if phaseparam in (1, 3, 4):
            # reconstruct space-time Gabor
            rgs = gabors[1, :].T * gtw[2, :] + gabors[2, :].T * gtw[1, :]
            rgs = np.reshape(rgs, [patchxytsize])
            gaborbank[:, :, :, wcount] = rgs
        elif phaseparam in (0, 2, 5, 6, 7, 8, 9):
            # reconstruct space-time Gabor
            rgc = -gabors[1, :].T * gtw[1, :] + gabors[2, :].T * gtw[2, :]
            rgc = np.reshape(rgc, patchxytsize)
            gaborbank[:, :, :, wcount] = rgc

    return gaborbank

def make_3d_gabor(xytsize, center_x=0.5, center_y=0.5, orientation=90, 
                  spatial_frequency=5, temporal_frequency=2.6, 
                  spatial_envelope=0.3, temporal_envelope=0.3, 
                  phase=0, stimulus_hz=None, stimulus_size_degrees=None):
    """
    Creates two Gabor functions (90º phase offset) of size (X, Y, T)

    Parameters
    ----------
    xytsize = vector of x, y, and t size, i.e. [64 64 5]
    center_x : scalar
        spatial x center of Gabor function. The axes are normalized to 0 (lower 
        left corner) to 1(upper right corner). e.g., [0.5 0.5] put the Gabor 
        at the center of the array.
    center_y : scalar
        spatial y center of Gabor function. See above.
    orientation = scalar
        The direction of the Gabor function in degree (0-360).
    spatial_freqency = scalar
        Determine how many cycles per image for spatial dimensions.
    temporal_frequency : scalar 
        Determine how many cycles per [time window]
    phase : scalar
        Phase of the Gabor function (optional, default is 0)
    stimulus_hz : int or None
        Frame rate of stimulus. If not provided (None), `temporal_frequency`
        is assumed to be in units of cycles / temporal window (t of xytsize)
    stimulus_size_degrees : tuple or None
        (x, y) size of stimulus in degrees of visual angle. If not provided
        (None), `spatial_frequency` and `spatial_envelope` are assumed to be 
        in units of cycles / image and fraction of the image, respectively.

    Returns
    -------
    gabor = array
        a gabor function of size X-by-Y-by-T
    gabor90 = array
        the quadrature pair the Gabor function
    """
    if len(xytsize) < 3:
        xytsize += (1,)
    sz_x, sz_y, sz_t = xytsize
    aspect_ratio = sz_x / sz_y
    dx = np.linspace(0, aspect_ratio, sz_x)
    dy = np.linspace(0, 1, sz_y)
    if sz_t > 1:
        dt = np.linspace(0, 1, sz_t, endpoint=False) # why?
    else:  
        dt = [0.5]
    
    iy, ix, it = np.meshgrid(dx, dy, dt)
    if stimulus_hz is not None:
        # Convert `temporal_frequency` to cycles / temporal_window

        pass
    if stimulus_size_degrees is not None:
        # Convert `spatial_frequency` to cycles / image
        # Asymmetrical images??
        spatial_frequency *= stimulus_size_degrees # cycles/image = (cycles/degree) * (degrees / image)
        pass

    gauss = np.exp( -((ix - center_x)**2 + (iy - center_y)**2) / (2 * spatial_envelope**2) - (it - 0.5)**2 / (2 * temporal_envelope**2))

    fx = -spatial_frequency * np.cos(orientation / 180 * np.pi) * 2 * np.pi
    fy = spatial_frequency * np.sin(orientation / 180 * np.pi) * 2 * np.pi
    ft = temporal_frequency * 2 * np.pi

    grat = np.sin((ix - center_x) * fx + (iy - center_y) * fy + (it - 0.5) * ft + phase)
    gabor = gauss * grat

    grat = np.cos((ix - center_x) * fx + (iy - center_y) * fy + (it - 0.5) * ft + phase)
    gabor90 = gauss * grat

    if np.max(np.abs(gabor)) == 0:
        gabor = -gabor90

    gabor = gabor.astype(np.float32)
    gabor90 = gabor90.astype(np.float32)
    return gabor, gabor90

def motion_energy(stimulus, 
    stimulus_hz=None,
    stimulus_size_degrees=None,
    direction_divisions=8,
    direction_selective=False,
    # SF
    sf_min=2.0, # in cycles / degree or cycles / image?
    sf_max=9.0,
    sf_divisions=5,
    sf_gaussratio=0.5,
    s_env_max=0.3,
    std_step=2.5,
    wrap_all=False,
    # TF
    tf_min=1.0, # Change to Hz! 0.0, # in Hz
    tf_max=3.0, # Change to Hz!
    tf_divisions=5,
    t_size=9,
    zero_tf=True,
    tf_gaussratio=0.4,
    t_env_max=0.3,

    phase_mode=0,
    phase_mode_sf_max = np.inf,
    f_step_log=False,
    f_env_mode=False,
    f_env_max=0.3,
    channel_index=None,
    local_dc=0,
    zeromean=True,
    zeromean_value=None, # combine to one
    verbose=False):
    """

    Notes: 
    changes from matlab code:
    zeromean_value is gone; if you want to normalize by RGB units, do it outside this function
    show_or_preprocess is gone; use other function
    separate processing of color channels is gone; do that outside this function
    deleted gabor_params (WTF was that?)
    """
    gaborcachemode = 0 # Hrm...

    # Caching - re-implement?
    # if ischar(stimulus):
    #     # Recover matrix from reference matrix (used for recursive calls for
    #     # color stimuli)
    #     stimulus = refmat_recover(stimulus); 
     
    # Timing
    start_t = time.time()
    # Stimulus checks
    im_y, im_x, n_frames = np.atleast_3d(stimulus).shape
    if stimulus.dtype not in (np.float, ):
        stimulus = stimulus.astype(np.float32)
    # Check min/max?
    # Stimulus aspect ratio; always X/Y (width/height)
    aspect_ratio = im_x / im_y
    patchxytsize = (im_y, im_x, t_size)
    stimulus = stimulus.reshape([im_y * im_x, n_frames])
    pixels_per_degree = np.mean([px/deg for px, deg in zip([im_y, im_x], stimulus_size_degrees)])
    if zeromean is True:
        if verbose:
            print('[[zero mean stimuli]]')
        zeromean = stimulus.mean()
        stimulus -= zeromean
        
    # Make a list of gabor parameters
    if (gabor_params is None) or (phasemode == 5) or (phasemode == 7): 
        if verbose:
            fprintf('Making a list of gabor parameters... \n');
        # Added aspect ratio as necessary influence on Gabor parameters

###########################################
### --- STOPPED HERE, WORKING BELOW --- ###
###########################################        
# (on get_gabor_parameters)
        gparams = get_gabor_parameters(params, aspect_ratio);

    waveletchannelnum = len(gparams)

    if verbose:
        print('%d channels total\n', waveletchannelnum); 

    if verbose and channel_index is not None:
        print('Valid channel num: %d\n', len(channel_index));

    # Set up a matrix to fill in
    if show_or_preprocess:
        if verbose:
            print('Preprocessing...')
        spreproc = zeros(stimxytsize(3), waveletchannelnum, 'single');
    else:
        if verbose:
             print('Making wavelets...')
        if ~np.any(channel_index):
            gnum = len(waveletchannelnum);
        else:
            gnum = len(channel_index);
        
        gaborbank = zeros([patchxytsize, gnum], 'single');


    #---------------------------------------------------------------------
    # Preprocessing
    #---------------------------------------------------------------------
    # ignore wavelet pixels for speed-up where:
    masklimit = 0.001;   ## pixel value < masklimit AND
    maskenv_below = 0.1; # spatial envelope < maskenv_below x stimulus size

    if gaborcachemode==1:
        gaborcache = zeros([2 prod(patchxytsize(1:2)) waveletchannelnum], 'single');
        gtwcache = zeros([2 t_size waveletchannelnum], 'single');


    lastgparam = zeros(9, 1);
    wcount = 0;
    for ii=1:waveletchannelnum
        
        if np.any(channel_index) && ~np.any(ii==channel_index):
            continue
        
        thisgparam = gparams(:, ii);
        thesame = True
        if np.any(thisgparam([1:7, 9]) ~=lastgparam([1:7, 9])) :
            thesame = False
        
        if not thesame:
            if gaborcachemode==2:
                gabors = gaborcache(:, :, ii);
                gtw = gtwcache(:, :, ii);
            else:
                gabor0, gabor90, gtw = make3dgabor_frames(patchxytsize, [thisgparam(1:7); 0; thisgparam(9)]);
                gabors = np.array([gabor0.flatten(), gabor90.flatten()]).T
            
            if gaborcachemode==1:
                gaborcache[:, :, ii] = gabors
                gtwcache[:, :, ii] = gtw
            
            lastgparam = thisgparam
        
        phaseparam = thisgparam[8]
        if not thesame:
            spatial_envelope = thisgparam(6);
            if spatial_envelope < maskenv_below:
                # UNTESTED
                smask = np.nonzero(np.sum(np.abs(gabors), 0) > masklimit)
                chout0, chout90 = dotdelay_frames(gabors(:, smask), gtw, stimulus(smask, :))
            else:
                chout0, chout90 = dotdelay_frames(gabors, gtw, stimulus)
            
        
        if phaseparam == 0:
            # norm of two outputs
            chout = np.sqrt(chout0**2 + chout90**2)
            spreproc[:, ii] = chout
        elif phaseparam == 1:
            # only linear output
            chout = chout0
            spreproc[:, ii] = chout
        elif phaseparam == 2:
            # Only 90º offset output
            chout = chout90
            spreproc[:, ii] = chout
        elif phaseparam == 3:
            # Rectified 
            chout = chout0
            chout[chout < 0] = 0
            spreproc[:, ii] = chout
        elif phaseparam == 4:
            chout = chout0
            chout[chout > 0] = 0
            spreproc[:, ii] = -chout
        elif phaseparam == 5:
            chout = chout90
            chout[chout < 0] = 0
            spreproc[:, ii] = chout
        elif phaseparam == 6:
            chout = chout90
            chout[chout > 0] = 0
            spreproc[:, ii] = -chout
        elif phaseparam == 7:
            chout = np.arctan2(chout90, chout0)
            dtphase = np.vstack([[0], np.diff(chout, 1, 1)]) # prob borked
            dtphase = dtphase + -2 * pi * np.sign(dtphase) * np.round(np.abs(dtphase) / (2 * pi))
            spreproc[:, ii] = dtphase
        elif phaseparam == 8:
            chout = np.arctan2(chout90, chout0)
            dtphase = [0; diff(chout, 1, 1)]
            dtphase = dtphase+ -2*pi*sign(dtphase).* ...
                round(abs(dtphase)./(2*pi))
            dtphase(dtphase<0) = 0
            spreproc[:, ii] = dtphase
        elif phaseparam == 9:
            chout = np.arctan2(chout90, chout0)
            dtphase = [0; diff(chout, 1, 1)]
            dtphase = dtphase+ -2*pi*sign(dtphase).* ...
                round(abs(dtphase)./(2*pi))
            dtphase(dtphase>0) = 0
            spreproc(:, ii) = -dtphase            
        
        # Some progress indicator
        #if verbose:
        #    progressdot(ii, 50, 1000, waveletchannelnum);

    if gaborcachemode==1:
        gaborcache = gaborcache
        gtwcache = gtwcache
        gaborcachemode = 2


    if verbose:
        disp(sprintf('Wavelet preprocessing done in #.1f min (cputime).', (cputime-start_t)/60))
        if show_or_preprocess:
            disp(sprintf('#d channels, #d samples', size(spreproc, 2), size(spreproc, 1)))        

    if show_or_preprocess:
        if phasemode==5 | phasemode==6 | phasemode==7 | phasemode==8:
            pind = np.nonzero(gparams[8, :]==7 | gparams[8, :]==8 | gparams[8, :]==9)
            print('thresholding phase channels...')
            for p in range(len(pind)):
                phasech = spreproc[:, pind[p]]
                if gparams[8, pind[p]-1] == 0 :
                    # look for the corresponding amplitude channel
                    ampch = spreproc[:, pind[p]-1]
                else:
                    ampch = spreproc[:, pind[p]-2]
                
                a_thresh = nanstd(ampch)*a_thresh
                avalind = ampch>a_thresh
                avalind = and(avalind, [0; avalind(1:-1)])
                phasech(~avalind) = 0
                spreproc(:, pind(p)) = phasech
            
            if phasemode==5 | phasemode==7 :
                # return dPhase/dt channels only
                spreproc = spreproc(:, pind)
                gparams = gparams(:, pind)
                fprintf('Using only dPhase/dt channels: #d\n', size(spreproc, 2))


    gaborparams = gparams

    return spreproc


#---------------------------------------------------------------------
# Making a list of gabor parameters
#---------------------------------------------------------------------
def get_gabor_parameters(
    stimulus_size_pixels, # xytsize?
    stimulus_hz,
    stimulus_size_degrees=22.5,
    direction_divisions=8,
    direction_selective=False,
    # SF
    sf_min=2.0, # in cycles / degree
    sf_max=9.0,
    sf_divisions=5,
    sf_gaussratio=0.5,
    s_env_max=0.3,
    std_step=2.5,
    wrap_all=False,
    # TF
    tf_min=1.0, # Change to Hz! 0.0, # in Hz
    tf_max=3.0, # Change to Hz!
    tf_divisions=5,
    t_size=9,
    zero_tf=True,
    tf_gaussratio=0.4,
    t_env_max=0.3,

    phase_mode=0,
    phase_mode_sf_max = np.inf,
    f_step_log=False,
    f_env_mode=False,
    f_env_max=0.3,
    channel_index=None,
    local_dc=0,
    zeromean=True,
    zeromean_value=None, # combine to one
    verbose=False):


    if f_step_log:
        sf_array = np.logspace(np.log10(sf_min), np.log10(sf_max), sf_divisions)
        if zero_tf:
            tf_array = np.logspace(np.log10(tf_min), np.log10(tf_max), tf_divisions-1)
            tf_array = np.hstack([0, tf_array])
        else:
            tf_array = np.logspace(np.log10(tf_min), np.log10(tf_max), tf_divisions)
        
    else:
        sf_array = np.linspace(sf_min, sf_max, sf_divisions)
        tf_array = np.linspace(tf_min, tf_max, tf_divisions)

    dir_array = np.arange(direction_divisions) / direction_divisions * 360 # OR: * 2 * np.pi?
    dirstart = 1
    if local_dc:
        dirstart = 0 # add local dc channels

    if phasemode==0:
        pmarray = [0]
    elif phasemode==1:
        # linear sin and cos transform amplitudes
        pmarray = [1, 2]
    elif phasemode==2:
        # half rectified sin and cos amplitudes
        pmarray = [3, 4, 5, 6]
    elif phasemode==3:
        # 0+1
        pmarray = [0, 1, 2]
    elif phasemode==4:
        # 0+2
        pmarray = [0, 3, 4, 5, 6]
    elif phasemode==5:
        # phase: atan2(sin, cos)
        pmarray = [0, 7]
    elif phasemode==6:
        # 0+5
        pmarray = [0, 7]
    elif phasemode==7:
        # phase: atan2(sin, cos), half-rectified
        pmarray = [0, 8, 9]
    elif phasemode==8:
        # 0+7
        pmarray = [0, 8, 9]

    waveletcount = 0;
    #gparams = np.zeros(8, 20000, 'single'); # prepare for some amount of memory for gparams
    # 
    # # Add a row to gparams to account for aspect ratio
    # gparams = [gparams;ones(1, size(gparams, 2), 'single')];
    for tf in tf_array:
        for sf in sf_array:
            spatial_envelope = s_env_max
            if sf != 0:
                spatial_envelope = np.min([s_env_max, 1 / sf * sf_gaussratio])
            temporal_envelope = t_env_max
            if tf != 0:
                temporal_envelope = min([t_env_max, 1 / tf * tf_gaussratio])

            if not direction_selective:
                tf += i            
            # Account for asymmetrical images
            if aspect_ratio==1:
                # Symmetrical images
                numsps2 = np.floor((1 - spatial_envelope * std_step) / (std_step * spatial_envelope) / 2)
                numsps2 = np.max([numsps2, 0]);
                if numsps2 >= 1 and wrap_all:
                    numsps2 = numsps2 + 1
                
                centers = spatial_envelope * std_step * np.arange(-numsps2, numsps2) + 0.5
                [cx, cy] = np.meshgrid(centers, centers)
                print('AR=1, sf=%.2f, nx=%d, ny=%d\n', sf, len(cx), len(cy))
            else:
                # aspect_ratio is x/y. Thus ar*x = true x OR y/ar = true y
                # Compute 
                g_sz_x = spatial_envelope * std_step
                n_gabors_x = np.floor((1 - g_sz_x) / (g_sz_x) / 2)
                n_gabors_x = np.max([n_gabors_x, 0])
                # THIS RIGHT HERE. this makes the aspect ratio actually y:x,
                # and applies the aspect ratio only in the y direction.
                # poss: treat size as 1 (or rather, aspect ratio=1) -- this
                # would recover the same centers as AR=1. then make elongated
                # gabor's using the AR and direction, so that elongation is in
                # the direction. Center one such at each center; they'll
                # overlap and overflow (in which case truncate), then look...
                g_sz_y = spatial_envelope * std_step * aspect_ratio;
                #g_sz_y = spatial_envelope*std_step;
                n_gabors_y = floor((1-g_sz_y)/(g_sz_y)/2);
                n_gabors_y = max([n_gabors_y, 0]);
                #REPLACED:
                #numsps2 =floor((1-spatial_envelope*std_step)/(std_step*spatial_envelope)/2);
                #numsps2 = max([numsps2 0]);
                #if numsps2>=1 && wrap_all:
                if wrap_all:
                    error('I don''t know what to do with wrap_all parameter yet w/ asymmetrical images...')
                    #numsps2 = numsps2 + 1;
                
                centers_x = g_sz_x*(-n_gabors_x:n_gabors_x) + 0.5 ;
                centers_y = g_sz_y*(-n_gabors_y:n_gabors_y) + 0.5 ;
                [cx, cy] = meshgrid(centers_x, centers_y);
                # Elongate gabors if differential sampling in x and y does not:
                # make the gabors circular
                # BUT ONLY IF there is no elongation parameter? (BUT WHERE THE
                # HELL DOES/DID THAT COME IN? nowhere that I (ML) can find in
                # Shinji's code. Must have been a hand-coded addition to
                # make3dgabor_frames.
                sampling_aspect_ratio = len(centers_x)/len(centers_y);
                elong = aspect_ratio / sampling_aspect_ratio;
                fprintf('AR=#.2f, sf=#.2f, g_sz_x=#.2f, nx=#d, g_sz_y=#.2f, ny=#d\n', aspect_ratio, sf, g_sz_x, len(cx), g_sz_y, len(cy));
                #keyboard;
                    
            thisnumdirs = len(dir_array);
            if tf == 0 || direction_selective == 0:
                thisnumdirs = ceil(thisnumdirs/2);  # use only ~180 deg
            
            if sf == 0:
                thisnumdirs = 1;
            
            for xyi in range(len(cx.flatten())):
                xcenter = cx[xyi]
                ycenter = cy[xyi]
                for diri in range(dirstart, thisnumdirs): #dirstart:thisnumdirs
                    if diri:
                        dir = dir_array(diri)
                        thissf = sf
                    else:
                        if local_dc == 1:
                            dir = 0; thissf = 0; # local dc channels
                        else:
                            dir = 0; thissf = sf*0.01; # to avoid the exact same channel
                        
                    
                    if  thissf >= phasemode_sfmax:
                        waveletcount = waveletcount+1;
                        thisgparam = [xcenter ycenter dir thissf tf spatial_envelope temporal_envelope 0 1];
                        if aspect_ratio != 1:
                            thisgparam(9) = max(elong, 1);
                        
                        gparams(:, waveletcount) = thisgparam;
                    else:
                        for pmod in pmarray:
                            waveletcount = waveletcount+1
                            thisgparam = [xcenter ycenter dir thissf tf spatial_envelope temporal_envelope pmod 1]
                            if aspect_ratio != 1:
                                thisgparam(9) = max(elong, 1)
                            
                            gparams[:, waveletcount] = thisgparam
                        
                    
                
            
        


    gparams = gparams(:, 1:waveletcount);
