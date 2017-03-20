def compute_normal_gradient(normals, nonlinexp=1):
    """Computes distances between normals in a pixelwise normal image.

    Differences between normal vectors are expressed as the average of the
    cosines of the angles between normals of adjacent pixels. X and Y
    directional gradients are computed, in a way analogous to the HoG
    (histogram of gradients) algorithm, but this function subtracts the full
    3D-vectors instead of 1-D pixel values. 

    Parameters
    ----------
    normals : 

    nonlinexp : scalar
        Raise whole image to this power (to adjust contrast)
    """

    # X derivative 
    norms_left = normals[:, :-2, :] 
    norms_center = normals[:, 1:-1, :] 
    norms_right = normals[:, 2:, :] 
    dx1 = np.arccos(np.sum(norms_left * norms_center, axis=2))
    dx2 = np.arccos(np.sum(norms_right * norms_center, axis=2))
    # Y derivative. 
    norms_top = normals[:-2, :, :]
    norms_middle = normals[1:-1, :, :]
    norms_bottom = normals[2:, :, :]
    dy1 = np.arccos(np.sum(norms_top * norms_middle, axis=2))
    dy2 = np.arccos(np.sum(norms_bottom * norms_middle, axis=2))
    # Take average of two gradients (e.g. center-left/center-right)
    x_grad = np.real(np.pad((dx1 + dx2) / 2, [(0, 0), (1, 1)], 'edge'))
    y_grad = np.real(np.pad((dy1 + dy2) / 2, [(1, 1), (0, 0)], 'edge'))
    # Compute magnitude and orientation of gradients
    grad_mag = x_grad**2 + y_grad**2
    grad_ori = np.arctan2(y_grad, x_grad)

    return grad_mag, grad_ori