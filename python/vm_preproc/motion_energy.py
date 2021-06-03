# Wrapper for motion energy code
import numpy as np
import matplotlib.pyplot as plt
import file_io as fio
from matplotlib import cm, colors, animation
from matplotlib.collections import LineCollection
import six

# Custom color maps
from matplotlib.colors import LinearSegmentedColormap
blue = (0, 0, 1.0)
cyan = (0, 0.5, 1.0)
white = (1.0, 0.85, 1.0)
orange = (1.0, 0.5, 0)
red = (1.0, 0, 0)
color_cycle = [blue, cyan, white, orange, red]
alpha_cycle_0 = (1.0, 0.625, 0.25, 0.625, 1.0)
alpha_cycle_1 = (1.0, 0.5, 0.0, 0.5, 1.0)
# blue, cyan, white, orange, red
# (this is effectively a higher-contrast RdBu_r)
bcwor = LinearSegmentedColormap.from_list('bcwor', color_cycle)
bcwora = LinearSegmentedColormap.from_list('bcwora', [col + tuple([a]) for col, a in zip(color_cycle, alpha_cycle_0)])
bcworaa = LinearSegmentedColormap.from_list('bcworaa', [col + tuple([a]) for col, a in zip(color_cycle, alpha_cycle_1)])

from ._motion_energy_cpu import mk_moten_pyramid_params, compute_filter_responses as _compute_filter_responses, mk_3d_gabor

try:
    from ._motion_energy_gpu import compute_filter_responses as _compute_filter_responses_gpu
    gpu_available = True
    print("Defaulting to use GPU")
except:
    print('No GPU available')
    gpu_available = False
#gpu_available = False

def compute_motion_energy(stimulus,
                          stimulus_fps=15,
                          gabor_temporal_window=None,
                          temporal_frequencies=(0, 2, 4),
                          spatial_frequencies=(0, 2, 4, 8, 16, 32),
                          spatial_directions=(0, 45, 90, 135, 180, 225, 270, 315),
                          sf_gauss_ratio=0.6,
                          max_spatial_env=0.3,
                          gabor_spacing=3.5,
                          tf_gauss_ratio=10.,
                          max_temp_env=0.3,
                          aspect_ratio=None,
                          include_edges=False,
                          use_gpu=gpu_available,
                          ):
    """   
    Parameters
    ----------
    stimulus : 3D np.array (n, vdim, hdim)
        The movie frames. Grayscale images only.
    stimulus_fps : scalar
        The temporal frequency of the stimulus
    gabor_temporal_window : scalar, None
        The number of frames in one filter.
        If None, it defaults to floor(2/3) of `stimulus_fps`
        Similar to Nishimoto, 2011.
    """
    
    t, y, x = stimulus.shape
    if aspect_ratio is None:
        aspect_ratio = x / y
    else:
        assert np.allclose(aspect_ratio, x / y), 'Specified aspect ratio does not match input aspect ratio!'
    if gabor_temporal_window is None:
        gabor_temporal_window = int(stimulus_fps * (2. / 3.))
    if use_gpu:
        fn = _compute_filter_responses_gpu
    else:
        fn = _compute_filter_responses

    moten_pyramid_parameters = dict(
            temporal_frequencies=temporal_frequencies,
            spatial_frequencies=spatial_frequencies,
            spatial_directions=spatial_directions,
            sf_gauss_ratio=sf_gauss_ratio,
            max_spatial_env=max_spatial_env,
            gabor_spacing=gabor_spacing,
            tf_gauss_ratio=tf_gauss_ratio,
            max_temp_env=max_temp_env,
            aspect_ratio=aspect_ratio,
            include_edges=include_edges,
            )
    # gparams = mk_moten_pyramid_params(stimulus_fps, gabor_temporal_window, 
    #                                 **moten_pyramid_parameters)
    out = fn(stimulus,
            stimulus_fps,
            gabor_temporal_window=gabor_temporal_window,
            #quadrature_combination=_sqrt_sum_squares, # leave as default
            output_nonlinearity=lambda x: x,
            dozscore=False,
            **moten_pyramid_parameters
            )
    if use_gpu:
        out = np.array(out.cpu())
    return out


# List of parameters relevant to defining gabors
pyramid_param_list = ['stimulus_fps', 'gabor_temporal_window', 'temporal_frequencies', 
                      'spatial_frequencies', 'spatial_directions', 
                      'sf_gauss_ratio', 'max_spatial_env', 'gabor_spacing', 'tf_gauss_ratio', 
                      'max_temp_env', 'aspect_ratio', 'include_edges']

           # * centerx,centery : horizontal and vertical position
           # * direction       : direction of motion
           # * spatial_freq    : spatial frequency
           # * spatial_env     : spatial envelope (gaussian s.d.)
           # * temporal_freq   : temporal frequency
           # * temporal_env    : temporal envelope (gaussian s.d.)
plot_param_list = ['x_center', 'y_center', 'spatial_direction', 'spatial_frequency', 
                    'spatial_envelope', 'temporal_frequency', 'temporal_envelope']


def pyramid_to_plot_params(**moten_pyramid_parameters):
    # Filter parameters
    moten_pyramid_parameters = dict((k,v) for k, v in moten_pyramid_parameters.items() if k in pyramid_param_list)
    # Convert to gabor parameters
    gparams = mk_moten_pyramid_params(**moten_pyramid_parameters).T
    # Generate dict of named parameters instead of implicit array
    plot_params = {}
    for i, k in enumerate(plot_param_list):
        plot_params[k] = gparams[i]
    if 'aspect_ratio' in moten_pyramid_parameters:
        plot_params['aspect_ratio'] = moten_pyramid_parameters['aspect_ratio']
    return plot_params


def show_motion_energy(features, params, ax=None, is_overlay=False, 
        figsize=(5.12, 5.12), marker_scale=2000, line_scale=1, lw_dict=None, 
        bg_col=(.11, .11, .11), bg_alpha=0.1, vmin=None, vmax=None, 
        groups=None, tf_to_show=None, sf_to_show=None, cmap=bcworaa,):
    '''Display short lines at location/orientation/scale of Gabor wavelet channels 

    A cartoony visualization of what the wavelets compute. 

    Parameters
    ----------
    features : 1D array
        One weight for each Gabor wavelet channel to plot, normalized to range 0-1
    params : dict
        Specifies params 
        (NOTE: The 1D vector in each field should match up with the weights in `features`)
        x_center = x positions for each Gabor wavelet (0-1 across image)
        y_center = y positions for each Gabor wavelet (0-1 across image)
        spatial_direction = orientation for each Gabor wavelet (in degrees)
        spatial_frequency = spatial frequency for each Gabor filter (in cycles / image)
        temporal_frequency = temporal frequency for each Gabor filter (in cycles / filter)
        spatial_envelope = scale for each Gabor wavelet (0-1 across image)
    ax : matplotlib axis
        axis into which to plot (if None, a new figure is created)
    sfile : str
        file path to save figure; if None, nothing is saved, just plots
    is_overlay : bool
        Whether to format the plot as an overlay for other images or not. Formatting
        as an overlay sets the background to `bg_alpha`. 
    cmap : matplotlib colormap
        colormap for plotting values in `features`


    Other Parameters
    ----------------
    tf_to_show : list or None
        indices for which temporal frequency (or frequencies) to display 
    sf_to_show : 


    Notes
    -----
    As they are currently computed, Gabor wavelets are not normalized by different scales and spatial
    frequencies. This means that large / low-frequency Gabor wavelets computed from an image generally
    have much larger values than small / low-frequency Gabor wavelets. Thus, for purposes of visualizing
    Gabor wavelets of different scales computed for the same image, it is currently a good idea to 
    normalize the values of each channel separately in some way. For example, you might take the 
    Z score across time and clip outliers (say, values > 4.5)

    '''
    # Handle inputs
    gmax = np.max(np.abs(features))
    if ('temporal_frequencies' in params) and ('temporal_frequency' not in params):
        # Params are pyramid creation params. Convert.
        params = pyramid_to_plot_params(**params)
    if vmin is None:
        vmin = -gmax
    if vmax is None:
        vmax = gmax
    # Set colors of displayed lines
    cnorm = colors.Normalize(vmin=vmin, vmax=vmax)
    cols = cmap(cnorm(features))
    # 
    if 'temporal_frequency' in params:
        tfs = params['temporal_frequency']
    else:
        tfs = []
    sfs = params['spatial_frequency']
    if 'spatial_direction' in params:
        oris = params['spatial_direction']
    else:
        oris = []
    u_sfs = np.unique(sfs)
    u_tfs = np.unique(tfs)
    # `spatial_envelope` is the std. dev. of the Gabor motion energy filter; 
    # thus, a good radius for the lines to be drawn here.
    radii = params['spatial_envelope'] * line_scale
    mksz = params['spatial_envelope'] * marker_scale
    xs = params['x_center']
    ys = params['y_center']
    if ax is None:
        fig = plt.figure(figsize=figsize)
        ax = plt.gca()
        ax.set_position((0, 0, 1, 1))
        show_fig = True
    else:
        fig = ax.get_figure()
        show_fig = False
    # Add scale to this...?
    width = params['aspect_ratio']
    height = 1.0
    # Get indices to select specific temporal or spatial frequency Gabors
    if not tf_to_show is None:
        tf_idx = np.isclose(tfs, tf_to_show)
    else:
        tf_idx = np.ones(xs.shape) > 0
    sf_idx = sfs > 0
    sf0_idx = sfs == 0
    if not sf_to_show is None:
        if not isinstance(sf_to_show, (list, tuple)):
            sf_to_show = [sf_to_show]
        sfi = np.any(np.vstack([np.isclose(sfs, sf_) for sf_ in sf_to_show]), axis=0)
        sf_idx = sf_idx & sfi
        sf0_idx = sf0_idx & sfi
    # Get linewidths for spatial frequencies
    if lw_dict is None:
        max_lw = 16
        min_lw = 2
        lw_ = np.linspace(max_lw, min_lw, len(u_sfs))
        # Other options for mapping spatial freq. to line width:
        # or: lw_ = np.logspace(1, 3, len(sfs), base=2)
        # or: lw_ = np.unique(sfs)**-1 / np.max(np.unique(sfs)**-1)*6.
        lw_dict = dict((sf, lw) for sf, lw in zip(u_sfs, lw_))
    lws = np.zeros(xs.shape) # Nans?
    for sf in u_sfs:
        if sf==0:
            continue
        jj = sfs == sf
        lws[jj] = lw_dict[sf]

    ii = tf_idx & sf_idx
    i0 = tf_idx & sf0_idx
    lw = [l for i, l in zip(ii, lws) if i]
    #mksz = [100*r for i, r in zip(i0, radii) if i]
    # X, Y offsets for oriented edges (from center point of Gabor)
    if np.any(ii) and len(oris) > 0:
        xa = radii*np.sin(np.radians(oris))
        ya = radii*np.cos(np.radians(oris))
        # X, Y 
        X = np.array([xs[ii] + xa[ii], xs[ii] - xa[ii]])
        Y = np.array([(1-ys[ii]) + ya[ii], (1-ys[ii]) - ya[ii]])
        #Y = (1-Y)  # Flip to image coordinates
        # Define line segments in a list
        edges = [[(X.T[i, 0], Y.T[i, 0]), (X.T[i, 1], Y.T[i, 1])] for i in range(np.sum(ii))]
        # Add line collection to plot
        LC = LineCollection(edges, colors=cols[ii, :], linewidth=lw)
        ax.add_collection(LC)
    # Add dots for sf=0
    if np.any(i0):
        plt.scatter(xs[sf0_idx], (1-ys[sf0_idx]), color=cols[sf0_idx, :], s=mksz[i0])
    # Final Setup
    plt.setp(ax, aspect='equal', xlim=(0, width), ylim=(0, height), xticks=(), yticks=())
    pdict = dict(color=bg_col, alpha=1) 
    if is_overlay:
        pdict.update(alpha=bg_alpha)
        plt.setp(fig.patch, alpha=0.)
    plt.setp(ax.patch, **pdict)



def show_motion_energy_color(features, params, ax=None, is_overlay=False,
        figsize=(5.12, 5.12), marker_scale=2000, line_scale=1, lw_dict=None, 
        combine_ori_fn=np.mean, bg_col=(.11, .11, .11), bg_alpha=0.1, 
        vmin=None, vmax=None, groups=None):
    '''Display short lines at location/orientation/scale of Gabor wavelet channels 

    A cartoony visualization of Gabor motion energy features. Each color represents
    a different temporal frequency (originally, r = 0 hz, g = 2 hz, b = 4 hz). For
    other motion energy filters, different visualizations will be needed.

    Parameters
    ----------
    features : 1D array
       One weight for each Gabor wavelet channel to plot
    params : dict
        parameters used to compute the motion energy features;
        i.e., all kwargs passed to `compute_motion_energy()`
    ax : axis
        axis into which to plot. If None, new figure + axis
        are created
    is_overlay : bool
        whether plot is meant as an overlay for an image or movie 
        frame (if True, background options are applied, i.e.
        background is mostly transparent)
    marker_scale : scalar
        Arbitrary scaling from values for size of features
    line_scale : scalar 
        same.
    lw_dict : dict
        dictionary of line widths for filters of different 
        spatial frequencies. See code.
    combine_ori_fn : function



    Notes
    -----
    As they are currently computed, Gabor wavelets are not normalized by different scales and spatial
    frequencies. This means that large / low-frequency Gabor wavelets computed from an image generally
    have much larger values than small / low-frequency Gabor wavelets. Thus, for purposes of visualizing
    Gabor wavelets of different scales computed for the same image, it is currently a good idea to 
    Thi Normalization for visualization is best done separately for each channel over a timecourse - 
    e.g., you can take the Z score across time clip outliers (say, > 4.5), and re-scale the resulting
    values from -1 to 1; then multiply that by .5 and add .5


    '''
    # Handle inputs
    gmax = np.max(np.abs(features))
    update = groups is not None
    if not update:
        groups = []
    if ('temporal_frequencies' in params) and ('temporal_frequency' not in params):
        # Params are pyramid creation params. Convert.
        params = pyramid_to_plot_params(**params)    
    if vmin is None:
        vmin = -gmax
    if vmax is None:
        vmax = gmax
    cnorm = colors.Normalize(vmin=vmin, vmax=vmax, clip=True)
    gnorm = cnorm(features)
    # Simpler parameters
    xs = params['x_center'] # / params['aspect_ratio'] # Seems sketch
    ys = params['y_center']
    tfs = params['temporal_frequency']
    sfs = params['spatial_frequency']
    oris = params['spatial_direction']
    # `spatial_envelope` parameter is the std. dev. of the Gabor;
    # thus, a good radius for the lines to be drawn here.
    radii = params['spatial_envelope'] * line_scale
    height = 1.0
    width = params['aspect_ratio']
    xa = radii * np.sin(np.radians(oris))
    ya = radii * np.cos(np.radians(oris))
    # Define line segments
    X = np.array([xs + xa, xs - xa])
    #Y = (1 - np.array([(1-ys) + ya, (1-ys) - ya]))
    #Y = np.array([(1-ys) + ya, (1-ys) - ya])
    Y = 1 - np.array([ys + ya, ys - ya])
    edges = np.array([[(X.T[i, 0], Y.T[i, 0]), (X.T[i, 1], Y.T[i, 1])] for i in range(np.max(X.shape))])
    # Define marker size for sf=0 (Gaussians)
    mksz = params['spatial_envelope'] * marker_scale
    # Prep plot
    if ax is None:
        fig = plt.figure(figsize=figsize)
        ax = plt.gca()
        ax.set_position((0, 0, 1, 1))
        show_fig = True
    else:
        fig = ax.get_figure()
        show_fig = False
    # Get indices to select specific temporal or spatial frequency Gabors
    u_tfs = np.unique(tfs)
    u_sfs = np.unique(sfs)
    # Get linewidths for spatial frequencies
    if lw_dict is None:
        max_lw = 16
        min_lw = 2
        u_sfs = np.unique(sfs)
        lw_ = np.linspace(max_lw, min_lw, len(u_sfs))
        # Other options for mapping spatial freq. to line width:
        # or: lw_ = np.logspace(1, 3, len(sfs), base=2)
        # or: lw_ = np.unique(sfs)**-1 / np.max(np.unique(sfs)**-1)*6.
        lw_dict = dict((sf, lw) for sf, lw in zip(u_sfs, lw_))
    lws = np.zeros(xs.shape) # Nans?
    for sf in u_sfs:
        if sf==0:
            continue
        jj = sfs == sf
        lws[jj] = lw_dict[sf]

    oris_big = oris > 179.9

    for j, sf in enumerate(u_sfs):
        sfi = np.isclose(sfs, sf)
        # Deal with opposite orientations (directions of motion, if present)
        # These lines (maybe, implicilty?) assume they will be combined somehow 
        # rather than dealt with separately.
        tfis = [np.isclose(tfs, tf) for tf in u_tfs]
        ns = [np.sum(sfi & tfi) for tfi in tfis]
        n = np.min(ns)
        cols = np.zeros((n, 4))
        for itf, tf in enumerate(u_tfs):
            tfi = np.isclose(tfs, tf)
            if np.any(oris_big[sfi & tfi]):
                frac_gt_180 = np.mean(oris_big[sfi & tfi])
                if not frac_gt_180 == 0.5:
                    raise ValueError('Assumptions not met! half of orientations are not 180 + other half!')
                to_plot = gnorm[sfi & tfi].copy()
                # Test that oris match up
                o1 = oris[sfi & tfi][~oris_big[sfi & tfi]]
                o2 = oris[sfi & tfi][oris_big[sfi & tfi]]
                assert np.allclose(o1 + 180, o2)
                combined_data = np.vstack([to_plot[oris_big[sfi & tfi]],
                                           to_plot[~oris_big[sfi & tfi]]])
                # Redefine to_plot to be some function of other orientations
                to_plot = combine_ori_fn(combined_data, axis=0)
            else:
                to_plot = gnorm[sfi & tfi].copy()
            cols[:, itf] = to_plot
        # Alpha channel
        cols[:, 3] = np.abs(cols[:, :3] - 0.5).max(axis=1) * 2
        tfi = tfis[np.argmin(ns)]
        jj = sfi & tfi
        if sf == 0:
            if update:
                groups[j].set_color(cols)
            else:
                DOTS = ax.scatter(xs[jj], (1 - ys[jj]), color=cols, s=mksz[jj])
                groups.append(DOTS)
        else:
            if update:
                groups[j].set_color(cols)
            else:
                LC = LineCollection(edges[jj], colors=cols, linewidth=lws[jj])
                groups.append(LC)
                ax.add_collection(LC)    
    # Final Setup
    plt.setp(ax, aspect='equal', xlim=(0, width), ylim=(0, height),
             xticks=(), yticks=())
    pdict = dict(color=bg_col, alpha=1)
    if is_overlay:
        pdict.update(alpha=bg_alpha)
        plt.setp(fig.patch, alpha=0.)
    plt.setp(ax.patch, **pdict)
    return groups

def make_motion_energy_animation_color(images, features, params, figsize=(5, 5), **kwargs):
    """Make a colorized animation of motion energy features

    Parameters
    ----------
    images : array
        stack of images, (time, vdim, hdim, [c]), in a format showable by plt.imshow()
    features : array
        (time x features) array of motion energy features
    params : dict
        dictionary of parameters used to compute the motion energy features
    figsize : tuple
        Size of figure

    Other Parameters
    ----------------
    kwargs are passed to `show_motion_energy_color()`
    
    Notes
    -----
    Good tutorial, fancy extras: https://alexgude.com/blog/matplotlib-blitting-supernova/
    """
    from functools import partial
    # First set up the figure, the axis, and the plot element we want to animate
    fig, ax = plt.subplots(figsize=figsize)
    # Shape
    extent = [0, params['aspect_ratio'], 0, 1]
    # interval is milliseconds; convert fps to milliseconds per frame
    interval = 1000 / params['stimulus_fps']
    # Setup
    if np.ndim(images) == 3:
        n_frames, y, x = images.shape
        im_shape = (y, x)
        imkw=dict(cmap='gray')
    else:
        n_frames, y, x, c = images.shape
        im_shape = (y, x, c) 
        imkw = {}
    im = ax.imshow(images[0], extent=extent, **imkw)
    grps = show_motion_energy_color(features[0], params, ax=ax, 
                is_overlay=True, **kwargs)
    artists = (im, *grps)
    plt.close(fig.number)
    # initialization function: plot the background of each frame
    def init_func(fig, ax, artists):
        _ = show_motion_energy_color(np.zeros_like(features[0]), params, 
            ax=ax, is_overlay=True, groups=artists[1:], **kwargs)
        im.set_array(np.zeros(im_shape))
        return artists 
    # animation function. This is called sequentially
    def update_func(i, artists, features):
        _ = show_motion_energy_color(features[i], params, 
            ax=ax, is_overlay=True, groups=artists[1:], **kwargs)
        artists[0].set_array(images[i])
        return artists
    init = partial(init_func, fig=fig, ax=ax, artists=artists)
    update = partial(update_func, artists=artists, features=features)
    # call the animator. blit=True means only re-draw the parts that have changed.
    anim = animation.FuncAnimation(fig, 
                func=update, 
                init_func=init,
                frames=n_frames, 
                interval=interval, 
                blit=True)
    return anim


def plot_moten_values(feature_values, params, vmin=None, vmax=None, cmap=None, 
        marker_scale=2000, line_scale=1, lw_dict=None, 
        ax=None, figsize=None, is_overlay=False,
        bg_col=(.11, .11, .11), bg_alpha=0.1, 
        groups=None, combine_ori_fn=np.max, 
        tf_to_show=None, sf_to_show=None):
    '''Display short lines at location/orientation/scale of Gabor wavelet channels 

    A simplified visualization of Gabor motion energy features. Each color represents
    a different temporal frequency (originally, r = 0 hz, g = 2 hz, b = 4 hz). For
    other motion energy filters, different visualizations will be needed.

    Parameters
    ----------
    feature_values : 1D array
        One value for each Gabor wavelet channel to plot
    params : dict
        Parameters used to compute the motion energy features;
        easiest to use `pyramid.parameters` used to compute features
    vmin : scalar
        Minimum value for color mapping. If both vmin and vmax
        are None, defaults to -max(abs(feature_values))
    vmax : scalar
        Maximum value for color mapping. If both vmin and vmax
        are None, defaults to +max(abs(feature_values))
    cmap : string or matplotlib colormap
        colormap (for plots of single temporal frequencies only)
    marker_scale : scalar
        Scaling from values for size of dots
    line_scale : scalar
        Scaling from values for size of lines
    lw_dict : dict
        dict of widths for lines of each spatial frequency. 
        Defaults to thicker lines for lower spatial frequencies,
        but results of defaults are not optimal for all plot sizes.
    ax : axis
        Axis into which to plot. If None, new figure + axis
        are created
    figsize : tuple
        figure size passed to matplotlib figure creation
    is_overlay : bool
        whether plot is meant as an overlay for an image or movie 
        frame (if True, background options are applied, i.e.
        background is mostly transparent)
    bg_col : tuple
        background color
    bg_alpha : scalar
        background alpha for overlay plots
    groups : list of matplotlib groups
        used for animations. If passed in, function updates colors 
        in a list of matplotlib artists rather than creating new lines
    combine_ori_fn : function
        function to use to combine values for values that would occupy
        exactly the same line (i.e. motion in exactly opposite directions)
        There is no good value for this; having to combine these is a 
        shortcoming of this plotting method.
    tf_to_show : scalar
        value for which temporal frequency to show, if only one temporal
        frequency is desired. Must match one of the temporal frequencies
        of the filters.
    sf_to_show : scalar
        same as tf_to_show, but for spatial frequencies. Both of these
        selection criteria can be applied simultaneously to show
        e.g. only values of high spatial and temporal frequency Gabors

    Notes
    -----
    As they are currently computed, Gabor wavelets are not normalized by different scales and spatial
    frequencies. This means that large / low-frequency Gabor wavelets computed from an image generally
    have much larger values than small / low-frequency Gabor wavelets. Thus, for purposes of visualizing
    Gabor wavelets of different scales computed for the same image, it is currently a good idea to 
    normalize the values in different channels in some way. For example, you can take the Z score across 
    time and clip outliers (say, > 4.5)


    '''
    #import six
    #import matplotlib.pyplot as plt
    #from matplotlib import cm, colors, animation
    #from matplotlib.collections import LineCollection

    # Handle inputs
    gmax = np.max(np.abs(feature_values))
    update = groups is not None
    if not update:
        groups = []
    if vmin is None:
        vmin = -gmax
    if vmax is None:
        vmax = gmax
    # Set colors of displayed lines
    cnorm = colors.Normalize(vmin=vmin, vmax=vmax, clip=True)
    gnorm = cnorm(feature_values)
    if isinstance(cmap, six.string_types):
        cmap = cm.get_cmap(cmap)
    # cols = cnorm(gnorm)
    # Simpler parameters
    xs = params['x_center'] # / params['aspect_ratio'] # Seems sketch
    ys = params['y_center']
    tfs = params['temporal_frequency']
    sfs = params['spatial_frequency']
    oris = params['spatial_direction']
    # `spatial_envelope` parameter is the std. dev. of the Gabor;
    # thus, a good radius for the lines to be drawn here.
    radii = params['spatial_envelope'] * line_scale
    height = 1.0
    width = params['aspect_ratio']
    # Define marker size for sf=0 (Gaussians)
    mksz = params['spatial_envelope'] * marker_scale    
    # Optionally cull some values
    to_keep = np.ones(xs.shape) > 0
    if sf_to_show is not None:
        to_keep = to_keep & np.isclose(sfs, sf_to_show)
    if tf_to_show is not None:
        to_keep = to_keep & np.isclose(tfs, tf_to_show)
    gnorm = gnorm[to_keep]
    xs = xs[to_keep]
    ys = ys[to_keep]
    tfs = tfs[to_keep]
    sfs = sfs[to_keep]
    oris = oris[to_keep]
    radii = radii[to_keep]
    mksz = mksz[to_keep]
    # Define locations for lines
    xa = radii * np.sin(np.radians(oris))
    ya = radii * np.cos(np.radians(oris))
    # Define line segments
    X = np.array([xs + xa, xs - xa])
    Y = 1 - np.array([ys + ya, ys - ya])
    edges = np.array([[(X.T[i, 0], Y.T[i, 0]), (X.T[i, 1], Y.T[i, 1])] for i in range(np.max(X.shape))])
    # Prep plot
    if ax is None:
        fig = plt.figure(figsize=figsize)
        ax = plt.gca()
        ax.set_position((0, 0, 1, 1))
        show_fig = True
    else:
        fig = ax.get_figure()
        show_fig = False
    # Get indices to select specific temporal or spatial frequency Gabors
    u_tfs = np.unique(tfs)
    if len(u_tfs) > 3:
        raise ValueError(('Cannot plot more than 3 temporal frequencies in the same plot. \n'
                          'You can use `tf_to_show` to plot each individaully.'))
    u_sfs = np.unique(sfs)
    # Get linewidths for spatial frequencies
    if lw_dict is None:
        max_lw = 16
        min_lw = 2
        u_sfs = np.unique(sfs)
        lw_ = np.linspace(max_lw, min_lw, len(u_sfs))
        # Other options for mapping spatial freq. to line width:
        # or: lw_ = np.logspace(1, 3, len(sfs), base=2)
        # or: lw_ = np.unique(sfs)**-1 / np.max(np.unique(sfs)**-1)*6.
        lw_dict = dict((sf, lw) for sf, lw in zip(u_sfs, lw_))
    lws = np.zeros(xs.shape) # Nans?
    for sf in u_sfs:
        if sf==0:
            continue
        jj = sfs == sf
        lws[jj] = lw_dict[sf]

    oris_big = oris > 179.9

    for j, sf in enumerate(u_sfs):
        sfi = np.isclose(sfs, sf)
        # Deal with opposite orientations (directions of motion, if present)
        # These lines (maybe, implicilty?) assume they will be combined somehow 
        # rather than dealt with separately.
        tfis = [np.isclose(tfs, tf) for tf in u_tfs]
        ns = [np.sum(sfi & tfi) for tfi in tfis]
        n = np.min(ns)
        if (len(u_tfs) == 1) and (cmap is not None):
            # Only one temporal frequency, color map it
            cols = cmap(gnorm[sfi])
        else:
            # Attempt to map multiple tfs to R, G, B colors
            cols = np.zeros((n, 4))
            for itf, tf in enumerate(u_tfs):
                tfi = np.isclose(tfs, tf)
                if np.any(oris_big[sfi & tfi]):
                    frac_gt_180 = np.mean(oris_big[sfi & tfi])
                    if not frac_gt_180 == 0.5:
                        raise ValueError('Assumptions not met! half of orientations are not 180 + other half!')
                    to_plot = gnorm[sfi & tfi].copy()
                    # Test that oris match up
                    o1 = oris[sfi & tfi][~oris_big[sfi & tfi]]
                    o2 = oris[sfi & tfi][oris_big[sfi & tfi]]
                    assert np.allclose(o1 + 180, o2)
                    combined_data = np.vstack([to_plot[oris_big[sfi & tfi]],
                                               to_plot[~oris_big[sfi & tfi]]])
                    # Redefine to_plot to be some function of other orientations
                    to_plot = combine_ori_fn(combined_data, axis=0)
                else:
                    to_plot = gnorm[sfi & tfi].copy()
                cols[:, itf] = to_plot
            # Alpha channel
            cols[:, 3] = np.abs(cols[:, :2] - 0.5).max(axis=1) * 2
        tfi = tfis[np.argmin(ns)]
        jj = sfi & tfi
        if sf == 0:
            if update:
                groups[j].set_color(cols)
            else:
                DOTS = ax.scatter(xs[jj], (1 - ys[jj]), color=cols, s=mksz[jj])
                groups.append(DOTS)
        else:
            if update:
                groups[j].set_color(cols)
            else:
                LC = LineCollection(edges[jj], colors=cols, linewidth=lws[jj])
                groups.append(LC)
                ax.add_collection(LC)    
    # Final Setup
    plt.setp(ax, aspect='equal', xlim=(0, width), ylim=(0, height),
             xticks=(), yticks=())
    pdict = dict(color=bg_col, alpha=1)
    if is_overlay:
        pdict.update(alpha=bg_alpha)
        plt.setp(fig.patch, alpha=0.)
    plt.setp(ax.patch, **pdict)
    return groups

def plot_moten_value_movie(images, feature_values, params, figsize=(5, 5), **kwargs):
    """Make a colorized animation of motion energy features

    Parameters
    ----------
    images : array
        stack of images, (time, vdim, hdim, [c]), in a format that can be 
        displayed by plt.imshow()
    feature_values : array
        (time x features) array of motion energy feature values
    params : dict
        dictionary of parameters used to compute the motion energy features
    figsize : tuple
        Size of figure

    Other Parameters
    ----------------
    kwargs are passed to `plot_moten_values()`. Note it is often
    necessary to set vmin and vmax for consistent plotting of values
    across time.
    
    Notes
    -----
    Good tutorial, fancy extras: https://alexgude.com/blog/matplotlib-blitting-supernova/
    """
    #import matplotlib.pyplot as plt
    #from matplotlib import cm, colors, animation
    #from functools import partial
    # First set up the figure, the axis, and the plot element we want to animate
    fig, ax = plt.subplots(figsize=figsize)
    # Shape
    extent = [0, params['aspect_ratio'], 0, 1]
    # interval is milliseconds; convert fps to milliseconds per frame
    interval = 1000 / params['stimulus_fps']
    # Setup
    if np.ndim(images) == 3:
        n_frames, y, x = images.shape
        im_shape = (y, x)
        imkw=dict(cmap='gray')
    else:
        n_frames, y, x, c = images.shape
        im_shape = (y, x, c) 
        imkw = {}
    im = ax.imshow(images[0], extent=extent, **imkw)
    grps = plot_moten_values(feature_values[0], params, ax=ax, 
                is_overlay=True, **kwargs)
    artists = (im, *grps)
    plt.close(fig.number)
    # initialization function: plot the background of each frame
    def init_func(fig, ax, artists):
        _ = plot_moten_values(np.zeros_like(feature_values[0]), params, 
            ax=ax, is_overlay=True, groups=artists[1:], **kwargs)
        im.set_array(np.zeros(im_shape))
        return artists 
    # animation function. This is called sequentially
    def update_func(i, artists, feature_values):
        _ = plot_moten_values(feature_values[i], params, 
            ax=ax, is_overlay=True, groups=artists[1:], **kwargs)
        artists[0].set_array(images[i])
        return artists
    init = partial(init_func, fig=fig, ax=ax, artists=artists)
    update = partial(update_func, artists=artists, feature_values=feature_values)
    # call the animator. blit=True means only re-draw the parts that have changed.
    anim = animation.FuncAnimation(fig, 
                func=update, 
                init_func=init,
                frames=n_frames, 
                interval=interval, 
                blit=True)
    return anim
