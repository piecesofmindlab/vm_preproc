import numpy as np
from . import utils
import plot_utils

def bin_heading_simple(angles, n=12, remove_nans=True):
    """Bin a heading (in degrees) into `n` bins

    Parameters
    ----------
    angles : array
        t x 1 array of heading angles in degrees
    n : scalar int
        number of bins

    Notes
    -----
    Currently only evenly spaced bins
    """
    if np.ndims(angles) == 1:
        angles = angles[:, np.newaxis]
    bin_width = 360 / n
    # Define bin centers
    abins = np.linspace(-180, 180, n, endpoint=False)
    # Compute distance to each heading bin
    ang_dist = np.abs(np.degrees(utils.circ_dist(np.radians(angles), np.radians(abins))))
    # soft histogram
    out = np.maximum(0, bin_width - ang_dist) / bin_width
    if remove_nans:
        # remove nans
        out[np.isnan(out)] = 0
    return out


# Visualization
def plot_heading(angle, image=None, figsize=(8, 6), ccol=(0.8, 0.8, 0.8), acol='yellow', ax=None):

    import matplotlib.pyplot as plt

    if ax is None:
        fig, ax0 = plt.subplots(figsize=figsize)
        ax = fig.add_subplot(projection='3d')
    else:
        fig = ax.get_figure()
        ax0 = fig.add_subplot(zorder=-1, position=ax.get_position())
    if image is None:
        ax0.set_axis_off()
    else:
        ax0.imshow(image)        
    ax.view_init(azim=90, elev=30)
    cpos = plot_utils.circle_pos(1.0, 32)
    cpos = np.vstack([cpos, cpos[0]])
    ax.plot(*cpos.T, np.zeros((len(cpos),)), '-', color=ccol)
    ax.plot([0, np.cos(angle + np.pi/2)], [0, np.sin(angle+np.pi/2)], [0, 0], color=acol)
    ax.patch.set_alpha(0)
    ax.set_ylim([1, -1])
    ax.set_axis_off()
    return ax

def make_heading_animation(angles, images=None, n_frames=None, figsize=(8, 6), ccol=(0.8, 0.8, 0.8), acol='yellow', img_ax=None, ax=None, fps=15):

    import matplotlib.pyplot as plt
    from matplotlib import animation
    from functools import partial

    # Inputs
    if n_frames is None:
        n_frames = len(angles)
    else:
        n_frames = np.minimum(n_frames, len(angles))
    # interval is milliseconds; convert fps to milliseconds per frame
    interval = 1000 / fps

    # First set up the figure, the axis, and the plot element we want to animate
    if (ax is None) and (img_ax is None):
        fig, img_ax = plt.subplots(figsize=figsize)
        ax = fig.add_subplot(projection='3d')
    if ax is None:
        fig = img_ax.get_figure()
        ax = fig.add_subplot(zorder=1, position=img_ax.get_position())
    if img_ax is None:
        fig = ax.get_figure()
        img_ax = fig.add_subplot(zorder=-1, position=ax.get_position())
    if images is None:
        img_ax.set_axis_off()
        imh = None
    else:
        imh = img_ax.imshow(images[0])

    ax.view_init(azim=90, elev=30)
    # Plot circle
    cpos = plot_utils.circle_pos(1.0, 32)
    cpos = np.vstack([cpos, cpos[0]])
    _ = ax.plot(*cpos.T, np.zeros((len(cpos),)), '-', color=ccol)
    # Plot heading angle
    l0, = ax.plot([0, np.cos(angles[0] + np.pi/2)], [0, np.sin(angles[0]+np.pi/2)], [0, 0], color=acol)
    # Tweak plot
    ax.patch.set_alpha(0)
    ax.set_ylim([1, -1])
    ax.set_axis_off()
    # Keep artists
    axs = [ax, img_ax]
    artists = [l0, imh]
    # Setup done, close figure & define update functions
    plt.close(fig.number)
    # initialization function: plot the background of each frame
    def init_func(fig, axs, artists):
        artists[0].set_data_3d([[0, 0], [0, 0], [0,0]])
        artists[1].set_array(images[0])
        return artists 
    # animation function. This is called sequentially
    def update_func(i, artists, angles, images):        
        artists[0].set_data_3d([[0, np.cos(angles[i] + np.pi/2)], [0, np.sin(angles[i]+np.pi/2)], [0, 0]])
        if images is not None:
            artists[1].set_array(images[i])
        return artists

    init = partial(init_func, fig=fig, axs=axs, artists=artists)
    update = partial(update_func, artists=artists, angles=angles, images=images)
    # call the animator. blit=True means only re-draw the parts that have changed.
    anim = animation.FuncAnimation(fig, 
                func=update, 
                init_func=init,
                frames=n_frames, 
                interval=interval, 
                blit=True)
    return anim

