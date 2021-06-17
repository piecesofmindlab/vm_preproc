import numpy as np
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
    bin_width = 360 / n
    # Define bin centers
    abins = np.linspace(-180, 180, n, endpoint=False)
    # Compute distance to each heading bin
    ang_dist = np.abs(np.degrees(vmp.utils.circ_dist(np.radians(st), np.radians(abins))))
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

# TODO: code to make a movie of heading 