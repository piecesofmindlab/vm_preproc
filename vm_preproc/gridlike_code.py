# Grid cell processing

import numpy as np


def sincos_mod(angle, mod_factor=6, remove_nans=True):
    """Get sin and cos of angle modulo some factor
    
    Dead simple; for computation of grid-like codes in fMRI

    Parameters
    ----------
    angle : array-like
        angle, in degrees
    mod_factor : scalar int
        modulo factor; tests for grid coding with this degree of symmetry
    """
    s = np.sin(np.radians(angle) * mod_factor)
    c = np.cos(np.radians(angle) * mod_factor)
    if np.ndim(s) == 2:
        out = np.hstack([s, c])
    else:
        out = np.vstack([s, c]).T
    if remove_nans:
        out = np.nan_to_num(out)
    return out


def animate_sincos(ang, mod=1, figsize=(5,5), fps=30, n_frames=1000):
    """Create animation of angle, with sin and cos """
    import matplotlib.pyplot as plt
    from matplotlib import animation
    from functools import partial

    n_frames = np.minimum(n_frames, len(ang))
    # Mod angles
    a = np.sin(np.radians(ang) * mod)
    b = np.cos(np.radians(ang) * mod)
    
    # First set up the figure, the axis, and the plot element we want to animate
    fig, ax = plt.subplots(subplot_kw=dict(projection='polar'))
    # For cos
    l0, = ax.plot([0, 0], [0, 1], 'b.-')
    # For sin
    l1, = ax.plot([0, 2 * np.pi / (4 * mod)], [0, 1], 'r.-')
    # For abs angle
    l2, = ax.plot([0, np.radians(ang[0])], [0, 1],  'm.-', lw=0.5)
    lines = [l0, l1, l2]
    ax.set_theta_direction(-1)
    ax.set_theta_offset(np.pi / 2.0)
    ax.set_xticks(np.arange(0, 2 * np.pi, np.pi / (mod/2)))
    ax.set_yticks([-1, 0, 1])
    ax.grid(axis='y', linestyle='--')
    # interval is milliseconds; convert fps to milliseconds per frame
    interval = 1000 / fps
    # Setup
    plt.close(fig.number)
    # initialization function: plot the background of each frame
    def init_func(fig, ax, artists):
        artists[0].set_data([[0, -1], [0, 0]])
        artists[1].set_data([[0, -1], [0, 0]])
        artists[2].set_data([[0, -1], [0, 0]])
        return artists 
    # animation function. This is called sequentially
    def update_func(i, artists):        
        artists[0].set_data([[0, 0], [-1, b[i]]])
        artists[1].set_data([[0, (2 * np.pi) / (4 * mod)], [-1, a[i]]])
        artists[2].set_data([[0, np.radians(ang[i])], [-1, 1]])
        return artists 
    init = partial(init_func, fig=fig, ax=ax, artists=lines)
    update = partial(update_func, artists=lines)
    # call the animator. blit=True means only re-draw the parts that have changed.
    anim = animation.FuncAnimation(fig, 
                func=update, 
                init_func=init,
                frames=n_frames, 
                interval=interval, 
                blit=True)
    return anim
