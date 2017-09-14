# Compute motion energy
from __future__ import division
import numpy as np
import time

def _make_gabor():
    pass

def _define_filter_pyramid(spatial_freqs=(), 
                           temporal_freqs=(),
                           orientations=(),
                           locations=(),
                           image_size=(),
                           ):
    """Define filter pyramid"""
    pass

def make_gabors():
    # formerly show_or_preproces
    pass

def make_3d_gabor(xytsize, center_x=0, center_y=0, orientation=90, 
                  spatial_frequency=5, temporal_frequency=4, 
                  spatial_envelope=10, temporal_envelope=9,
                  phase=0):
    #function [gabor, gabor90] = make3dgabor(xytsize, params)

    """
    returns a gabor functions of size X-by-Y-by-T, specified by a vector PARAMS.

    Parameters
    ----------
    xytsize = vector of x, y, and t size, i.e. [64 64 5]
    center_x : scalar
        spatial x center of Gabor function. The axes are normalized to 0 (lower 
        left corner) to 1(upper right corner). e.g., [0.5 0.5] put the Gabor 
        at the center of the matrix.
    center_y : scalar
        spatial y center of Gabor function. See above.
    orientation = scalar
        The direction of the Gabor function in degree (0-360).
    spatial_freqency = scalar
        Determine how many cycles per image for spatial dimensions.
    temporal_freqency : scalar 
        Determine how many cycles per [time window]
    phase : scalar
        Phase of the Gabor function (optional, default is 0)

     OUTPUT:
           [gabor] = a gabor function of size X-by-Y-by-T, specified by a vector PARAMS.
         [gabor90] = the quadrature pair Gabor function
    """
    dx = np.linspace(0, 1, xytsize[0]) #0:(1/(xytsize(1)-1)):1;
    dy = np.linspace(0, 1, xytsize[1]) # 0:(1/(xytsize(2)-1)):1;
    if len(xytsize) < 3:
        xytsize += (1,)
    if xytsize[2] > 1:
        dt = np.linspace(0, 1, xytsize[2]) # 0:(1/(xytsize(3)-1)):1;
    else:  
        dt = 0.5;

    iy, ix, it = np.meshgrid(dx, dy, dt) #ndgrid(dx, dy, dt);

    gauss = np.exp( -((ix - center_x)**2 + (iy - center_y)**2) / (2 * spatial_envelope**2) - (it - 0.5)**2 / (2 * temporal_envelope**2))

    fx = -spatial_frequency * np.cos(orientation / 180 * pi) * 2 * pi
    fy = spatial_frequency * np.sin(orientation / 180 * pi) * 2 * pi
    ft = temporal_frequency * 2 * pi

    grat = np.sin((ix - center_x) * fx + (iy - center_y) * fy + (it - 0.5) * ft + phase)
    gabor = gauss * grat

    grat = np.cos((ix - center_x) * fx + (iy - center_y) * fy + (it - 0.5) * ft + phase)
    gabor90 = gauss * grat

    if np.max(np.abs(gabor)) == 0:
        gabor = -gabor90

    gabor = gabor.astype(np.float32)
    gabor90 = gabor90.astype(np.float32)


# def motion_energy(S, 
#     stim_hz=15, # NOT NECESSARILY TRUE need a warning
#     stim_degrees=22.5,
#     direction_divisions=8,
#     direction_selective=False,
#     # SF
#     sf_min=2.0, # in cycles / degree
#     sf_max=9.0,
#     sf_divisions=5,
#     sf_gaussratio=0.5,
#     s_env_max=0.3,
#     std_step=2.5,
#     wrap_all=False,
#     # TF
#     tf_min=1.0, # Change to Hz! 0.0, # in Hz
#     tf_max=3.0, # Change to Hz!
#     tf_divisions=5,
#     t_size=9,
#     zero_tf=True,
#     tf_gaussratio=0.4,
#     t_env_max=0.3,

#     gabor_params=None,

#     phase_mode=0,
#     phase_mode_sf_max = np.inf,
#     f_step_log=False,
#     f_env_mode=False,
#     f_env_max=0.3,
#     channel_index=None,
#     local_dc=0,
#     zeromean=True,
#     zeromean_value=None, # combine to one
#     verbose=False):
#     """

#     Notes: 
#     changes from matlab code:
#     zeromean_value is gone; if you want to normalize by RGB units, do it outside this function
#     show_or_preprocess is gone; use other function
#     separate processing of color channels is gone; do that outside this function
#     """
#     gaborcachemode = 0 # Hrm...

#     # Caching - re-implement?
#     # if ischar(S):
#     #     # Recover matrix from reference matrix (used for recursive calls for
#     #     # color stimuli)
#     #     S = refmat_recover(S); 
     
#     # Timing
#     start_t = time.time()
#     # Stimulus check
#     if np.ndim(S)==3:
#         # Assure 3 dimensions
#         im_y, im_x, n_frames = S.shape
#     elif np.ndim(S)==2:
#         im_y, im_x = S.shape
#         n_frames = 1
#     if S.dtype not in (np.float,):
#         S = S.astype(np.float32)
#     # Stimulus aspect ratio; always X/Y (width/height)
#     # Allow specification of aspect ratio?? Always compute from image, yes?
#     aspect_ratio = im_x / im_y
#     patchxytsize = (im_y, im_x, t_size)
#     S = S.reshape([im_y * im_x, n_frames])

#     if zeromean:
#         if verbose:
#             print('[[zero mean stimuli]]'):
#         if zeromean_value is None:
#             zeromean_value = S.mean()
#         S -= zeromean_value
        
#     # Make a list of gabor parameters
#     if ~isfield(params,'gaborparams') || phasemode == 5 || phasemode == 7:
#         if verbose, fprintf('Making a list of gabor parameters... \n'); :
#         # Added aspect ratio as necessary influence on Gabor parameters

# ###########################################
# ### --- STOPPED HERE, WORKING BELOW --- ###
# ###########################################        
# # (on get_gabor_parameters)
#         [gparams] = get_gabor_parameters(params,aspect_ratio);
#     else:
#         gparams = gaborparams;

#     waveletchannelnum = len(gparams)

#     if verbose:
#         print('%d channels total\n', waveletchannelnum); 

#     if verbose and channel_index is not None:
#         print('Valid channel num: %d\n', len(channel_index));

#     # Set up a matrix to fill in
#     if show_or_preprocess:
#         if verbose, disp('Preprocessing...'); :
#         Spreproc = zeros(stimxytsize(3), waveletchannelnum, 'single');
#     else:
#         if verbose, disp('Making wavelets...'); :
#         if ~np.any(channel_index):
#             gnum = length(waveletchannelnum);
#         else:
#             gnum = length(channel_index);
        
#         gaborbank = zeros([patchxytsize gnum], 'single');


#     #---------------------------------------------------------------------
#     # Preprocessing
#     #---------------------------------------------------------------------
#     # ignore wavelet pixels for speed-up where:
#     masklimit = 0.001;   ## pixel value < masklimit AND
#     maskenv_below = 0.1; # spatial envelope < maskenv_below x stimulus size

#     if gaborcachemode==1:
#         gaborcache = zeros([2 prod(patchxytsize(1:2)) waveletchannelnum], 'single');
#         gtwcache = zeros([2 t_size waveletchannelnum], 'single');


#     lastgparam = zeros(9,1);
#     wcount = 0;
#     for ii=1:waveletchannelnum
        
#         if np.any(channel_index) && ~np.any(ii==channel_index):
#             continue
        
#         thisgparam = gparams(:,ii);
#         thesame = 1;
#         if np.any(thisgparam([1:7,9]) ~=lastgparam([1:7,9])) :
#             thesame = 0;
        
#         if ~thesame:
#             if gaborcachemode==2:
#                 gabors = gaborcache(:,:,ii);
#                 gtw = gtwcache(:,:,ii);
#             else:
#                 [gabor0,gabor90,gtw] = make3dgabor_frames(patchxytsize, [thisgparam(1:7); 0; thisgparam(9)]);
#                 gabors = [gabor0(:) gabor90(:)]';
            
#             if gaborcachemode==1:
#                 gaborcache(:,:,ii) = gabors;
#                 gtwcache(:,:,ii) = gtw;
            
#             lastgparam = thisgparam;
        
#         phaseparam = thisgparam(8);
#         if show_or_preprocess:
#             if ~thesame:
#                 senv = thisgparam(6);
#                 if senv<maskenv_below:
#                     smask = find(sum(abs(gabors),1)>masklimit);
#                     [chout0,chout90] = dotdelay_frames(gabors(:,smask), gtw, S(smask,:));
#                 else:
#                     [chout0,chout90] = dotdelay_frames(gabors, gtw, S);
                
            
#             switch phaseparam
#                 case 0
#                     chout = sqrt(chout0.^2 + chout90.^2);
#                     Spreproc(:,ii) = chout;
#                 case 1
#                     chout = chout0;
#                     Spreproc(:,ii) = chout;
#                 case 2
#                     chout = chout90;
#                     Spreproc(:,ii) = chout;
#                 case 3
#                     chout = chout0;
#                     chout(chout<0) = 0;
#                     Spreproc(:,ii) = chout;
#                 case 4
#                     chout = chout0;
#                     chout(chout>0) = 0;
#                     Spreproc(:,ii) = -chout;
#                 case 5
#                     chout = chout90;
#                     chout(chout<0) = 0;
#                     Spreproc(:,ii) = chout;
#                 case 6
#                     chout = chout90;
#                     chout(chout>0) = 0;
#                     Spreproc(:,ii) = -chout;
#                 case 7
#                     chout = atan2(chout90,chout0);
#                     dtphase = [0; diff(chout,1,1)];
#                     dtphase = dtphase+ -2*pi*sign(dtphase).*round(abs(dtphase)./(2*pi));
#                     Spreproc(:,ii) = dtphase;
#                 case 8
#                     chout = atan2(chout90,chout0);
#                     dtphase = [0; diff(chout,1,1)];
#                     dtphase = dtphase+ -2*pi*sign(dtphase).* ...
#                         round(abs(dtphase)./(2*pi));
#                     dtphase(dtphase<0) = 0;
#                     Spreproc(:,ii) = dtphase;
#                 case 9
#                     chout = atan2(chout90,chout0);
#                     dtphase = [0; diff(chout,1,1)];
#                     dtphase = dtphase+ -2*pi*sign(dtphase).* ...
#                         round(abs(dtphase)./(2*pi));
#                     dtphase(dtphase>0) = 0;
#                     Spreproc(:,ii) = -dtphase;
            
#         else:
#             wcount = wcount + 1;
#             switch phaseparam
#                 case {1,3,4}
#                     # reconstruct space-time Gabor
#                     rgs = gabors(1,:)'*gtw(2,:)+gabors(2,:)'*gtw(1,:);
#                     rgs=reshape(rgs, [patchxytsize]);
#                     gaborbank(:,:,:,wcount) = rgs;
#                 case {0,2,5,6,7,8,9}
#                     # reconstruct space-time Gabor
#                     rgc = -gabors(1,:)'*gtw(1,:)+gabors(2,:)'*gtw(2,:);
#                     rgc=reshape(rgc, [patchxytsize]);
#                     gaborbank(:,:,:,wcount) = rgc;
            
        
        
#         if verbose:
#             progressdot(ii,50,1000,waveletchannelnum);
        


#     if gaborcachemode==1:
#         gaborcache = gaborcache;
#         gtwcache = gtwcache;
#         gaborcachemode = 2;


#     if verbose:
#         disp(sprintf('Wavelet preprocessing done in #.1f min (cputime).', (cputime-start_t)/60));
#         if show_or_preprocess:
#             disp(sprintf('#d channels, #d samples', size(Spreproc,2), size(Spreproc,1)));
#         else:
#             disp(sprintf('#d channels', size(gaborbank,4)));
        


#     if show_or_preprocess:
#         if phasemode==5 | phasemode==6 | phasemode==7 | phasemode==8:
#             pind = find(gparams(8,:)==7 | gparams(8,:)==8 | gparams(8,:)==9);
#             disp('thresholding phase channels...');
#             for p=1:length(pind)
#                 phasech = Spreproc(:,pind(p));
#                 if gparams(8,pind(p)-1) == 0 :
#                     # look for the
#                     # corresponding amplitude channel
#                     ampch = Spreproc(:,pind(p)-1);
#                 else:
#                     ampch = Spreproc(:,pind(p)-2);
                
#                 a_thresh = nanstd(ampch)*a_thresh;
#                 avalind = ampch>a_thresh;
#                 avalind = and(avalind, [0; avalind(1:-1)]);
#                 phasech(~avalind) = 0;
#                 Spreproc(:,pind(p)) = phasech;
            
#             if phasemode==5 | phasemode==7 :
#                 # return dPhase/dt channels only
#                 Spreproc = Spreproc(:,pind);
#                 gparams = gparams(:,pind);
#                 fprintf('Using only dPhase/dt channels: #d\n', size(Spreproc,2));
            
        
        
#     else :
#         # return gabors, not pre-processed data
#         Spreproc = gaborbank;


#     gaborparams = gparams;
#     nChan = size(gparams,2);

#     varargout{1} = Spreproc;
#     if nargout>1:
#         varargout{2} = params;


#     return;


# #---------------------------------------------------------------------
# # Making a list of gabor parameters
# #---------------------------------------------------------------------
# def get_gabor_parameters(
#     stim_hz=15, # NOT NECESSARILY TRUE need a warning
#     stim_degrees=22.5,
#     direction_divisions=8,
#     direction_selective=False,
#     # SF
#     sf_min=2.0, # in cycles / degree
#     sf_max=9.0,
#     sf_divisions=5,
#     sf_gaussratio=0.5,
#     s_env_max=0.3,
#     std_step=2.5,
#     wrap_all=False,
#     # TF
#     tf_min=1.0, # Change to Hz! 0.0, # in Hz
#     tf_max=3.0, # Change to Hz!
#     tf_divisions=5,
#     t_size=9,
#     zero_tf=True,
#     tf_gaussratio=0.4,
#     t_env_max=0.3,

#     gabor_params=None,

#     phase_mode=0,
#     phase_mode_sf_max = np.inf,
#     f_step_log=False,
#     f_env_mode=False,
#     f_env_max=0.3,
#     channel_index=None,
#     local_dc=0,
#     zeromean=True,
#     zeromean_value=None, # combine to one
#     verbose=False):


#     if f_step_log:
#         sf_array = np.logspace(np.log10(sf_min), np.log10(sf_max), sf_divisions);
#         if zero_tf:
#             tf_array = np.logspace(np.log10(tf_min), np.log10(tf_max), tf_divisions-1);
#             tf_array = [0 tf_array];
#         else:
#             tf_array = np.logspace(np.log10(tf_min), np.log10(tf_max), tf_divisions);
        
#     else:
#         sf_array = np.linspace(sf_min, sf_max, sf_divisions);
#         tf_array = np.linspace(tf_min, tf_max, tf_divisions);

#     dir_array = np.arange(direction_divisions) / direction_divisions * 360 # OR: * 2 * np.pi?
#     dirstart = 1
#     if local_dc:
#         dirstart = 0 # add local dc channels

#     if phasemode==0:
#         pmarray = [0]
#     elif phasemode==1:
#         # linear sin and cos transform amplitudes
#         pmarray = [1 2]
#     elif phasemode==2:
#         # half rectified sin and cos amplitudes
#         pmarray = [3 4 5 6]
#     elif phasemode==3:
#         # 0+1
#         pmarray = [0 1 2]
#     elif phasemode==4:
#         # 0+2
#         pmarray = [0 3 4 5 6]
#     elif phasemode==5:
#         # phase: atan2(sin,cos)
#         pmarray = [0 7]
#     elif phasemode==6:
#         # 0+5
#         pmarray = [0 7]
#     elif phasemode==7:
#         # phase: atan2(sin,cos), half-rectified
#         pmarray = [0 8 9]
#     elif phasemode==8:
#         # 0+7
#         pmarray = [0 8 9]

#     waveletcount = 0;
#     #gparams = np.zeros(8, 20000, 'single'); # prepare for some amount of memory for gparams
#     # 
#     # # Add a row to gparams to account for aspect ratio
#     # gparams = [gparams;ones(1,size(gparams,2),'single')];
#     for tf in tf_array:
#         for sf in sf_array:
#             senv = s_env_max
#             if sf != 0:
#                 senv = np.min([s_env_max, 1 / sf * sf_gaussratio])
#             tenv = t_env_max;
#             if tf != 0:
#                 tenv = min([t_env_max, 1 / tf * tf_gaussratio])

#             if not direction_selective:
#                 tf += i            
#             # Account for asymmetrical images
#             if aspect_ratio==1:
#                 # Symmetrical images
#                 numsps2 = np.floor((1 - senv * std_step) / (std_step * senv) / 2)
#                 numsps2 = np.max([numsps2, 0]);
#                 if numsps2 >= 1 and wrap_all:
#                     numsps2 = numsps2 + 1
                
#                 centers = senv * std_step * np.arange(-numsps2, numsps2) + 0.5
#                 [cx, cy] = np.meshgrid(centers, centers)
#                 print('AR=1, sf=%.2f, nx=%d, ny=%d\n', sf, len(cx), len(cy))
#             else:
#                 # aspect_ratio is x/y. Thus ar*x = true x OR y/ar = true y
#                 # Compute 
#                 g_sz_x = senv * std_step
#                 n_gabors_x = np.floor((1 - g_sz_x) / (g_sz_x) / 2)
#                 n_gabors_x = np.max([n_gabors_x, 0])
#                 # THIS RIGHT HERE. this makes the aspect ratio actually y:x,
#                 # and applies the aspect ratio only in the y direction.
#                 # poss: treat size as 1 (or rather, aspect ratio=1) -- this
#                 # would recover the same centers as AR=1. then make elongated
#                 # gabor's using the AR and direction, so that elongation is in
#                 # the direction. Center one such at each center; they'll
#                 # overlap and overflow (in which case truncate), then look...
#                 g_sz_y = senv * std_step * aspect_ratio;
#                 #g_sz_y = senv*std_step;
#                 n_gabors_y = floor((1-g_sz_y)/(g_sz_y)/2);
#                 n_gabors_y = max([n_gabors_y,0]);
#                 #REPLACED:
#                 #numsps2 =floor((1-senv*std_step)/(std_step*senv)/2);
#                 #numsps2 = max([numsps2 0]);
#                 #if numsps2>=1 && wrap_all:
#                 if wrap_all:
#                     error('I don''t know what to do with wrap_all parameter yet w/ asymmetrical images...')
#                     #numsps2 = numsps2 + 1;
                
#                 centers_x = g_sz_x*(-n_gabors_x:n_gabors_x) + 0.5 ;
#                 centers_y = g_sz_y*(-n_gabors_y:n_gabors_y) + 0.5 ;
#                 [cx, cy] = meshgrid(centers_x, centers_y);
#                 # Elongate gabors if differential sampling in x and y does not:
#                 # make the gabors circular
#                 # BUT ONLY IF there is no elongation parameter? (BUT WHERE THE
#                 # HELL DOES/DID THAT COME IN? nowhere that I (ML) can find in
#                 # Shinji's code. Must have been a hand-coded addition to
#                 # make3dgabor_frames.
#                 sampling_aspect_ratio = length(centers_x)/length(centers_y);
#                 elong = aspect_ratio / sampling_aspect_ratio;
#                 fprintf('AR=#.2f, sf=#.2f, g_sz_x=#.2f, nx=#d, g_sz_y=#.2f, ny=#d\n',aspect_ratio,sf,g_sz_x,length(cx),g_sz_y,length(cy));
#                 #keyboard;
                    
#             thisnumdirs = length(dir_array);
#             if tf == 0 || direction_selective == 0:
#                 thisnumdirs = ceil(thisnumdirs/2);  # use only ~180 deg
            
#             if sf == 0:
#                 thisnumdirs = 1;
            
#             for xyi = 1:length(cx(:))
#                 xcenter = cx(xyi);
#                 ycenter = cy(xyi);
#                 for diri = dirstart:thisnumdirs
#                     if diri:
#                         dir = dir_array(diri); thissf = sf;
#                     else:
#                         if local_dc == 1:
#                             dir = 0; thissf = 0; # local dc channels
#                         else:
#                             dir = 0; thissf = sf*0.01; # to avoid the exact same channel
                        
                    
#                     if  thissf >= phasemode_sfmax:
#                         waveletcount = waveletcount+1;
#                         thisgparam = [xcenter ycenter dir thissf tf senv tenv 0 1];
#                         if aspect_ratio != 1:
#                             thisgparam(9) = max(elong,1);
                        
#                         gparams(:,waveletcount) = thisgparam;
#                     else:
#                         for pmod = pmarray
#                             waveletcount = waveletcount+1;
#                             thisgparam = [xcenter ycenter dir thissf tf senv tenv pmod 1];
#                             if aspect_ratio != 1:
#                                 thisgparam(9) = max(elong,1);
                            
#                             gparams(:,waveletcount) = thisgparam;
                        
                    
                
            
        


#     gparams = gparams(:,1:waveletcount);
