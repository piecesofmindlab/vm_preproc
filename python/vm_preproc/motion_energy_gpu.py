'''Motion-energy filters (after Nishimoto, 2011)

Adapted from:
/auto/k1/shinji/matlab/strflab_adds/make3dgabor_frames.m
/auto/k1/shinji/matlab/strflab_adds/preprocWavelets_grid.m
/auto/k1/shinji/matlab/strflab_adds/preprocWaveletsNonLinear.m

Anwar O. Nunez-Elizalde (Jan, 2016)
Ported to GPU by Michael Eickenberg (July, 2019)
'''

import itertools
from PIL import Image
import numpy as np
import torch

from buffer_list import BufferList

##############################
# Helper functions
##############################

#from .motion_energy_aone import imagearr2luminance
#from .motion_energy_aone import resize_image
#from .motion_energy_aone import load_image_luminance



def _log_compress(x, offset=1e-05):
    return torch.log(x + offset)


def _sqrt_sum_squares(x,y):
    return torch.sqrt(x**2 + y**2)


def compute_spatial_gabor_responses(stimulus,
                                    spatial_frequencies=(0,2,4,8,16,32),
                                    quadrature_combination=_sqrt_sum_squares,
                                    output_nonlinearity=_log_compress,
                                    use_cuda=True):
    """Compute the spatial gabor filters' response to each stimulus.

    Parameters
    ----------
    stimulus : 3D np.array (n, vdim, hdim)
        The stimulus frames.
    spatial_frequencies : array-like
        The spatial frequencies to compute. The spatial envelope is determined by this.
    quadrature_combination : function, optional
        Specifies how to combine the channel reponses quadratures.
        The function must take the sin and cos as arguments in order.
        Defaults to: (sin^2 + cos^2)^1/2
    output_nonlinearity : function, optional
        Passes the channels (after `quadrature_combination`) through a
        non-linearity. The function input is the (`n`,`nfilters`) array.
        Defaults to: ln(x + 1e-05)
    use_cuda : bool
        Whether to use the GPU for the computations


    Returns
    -------
    filter_responses : np.array, (n, nfilters)
    """
    _, vdim, hdim = stimulus.shape
    aspect_ratio = hdim/float(vdim)

    stimulus = stimulus.reshape(stimulus.shape[0], -1)
    gabor_parameters = mk_moten_pyramid_params(1.,
                                               1.,
                                               temporal_frequencies=[0.],
                                               spatial_directions=[0.],
                                               spatial_frequencies=spatial_frequencies,
                                               )

    channels = []

    for idx, gabor_param in enumerate(gabor_parameters):
        sgabor_sin, sgabor_cos, _, _ = mk_3d_gabor((hdim,vdim,1.0),
                                                   *gabor_param,
                                                   aspect_ratio=aspect_ratio)

        channel_sin, channel_cos = dotspatial_frames(sgabor_sin, sgabor_cos, stimulus)
        channel = quadrature_combination(channel_sin, channel_cos)
        channels.append(channel)
    channels = np.asarray(channels).T
    channels = output_nonlinearity(channels)
    return channels


def compute_filter_responses(stimulus,
                             stimulus_fps,
                             gabor_temporal_window=None,
                             quadrature_combination=_sqrt_sum_squares,
                             output_nonlinearity=_log_compress,
                             use_cuda=True,
                             **moten_pyramid_parameters):
    """Compute the motion-energy filters' response to the stimuli.

    Parameters
    ----------
    stimulus : 3D np.array (n, vdim, hdim)
        The movie frames.
    stimulus_fps : scalar
        The temporal frequency of the stimulus
    gabor_temporal_window : scalar, None
        The number of frames in one filter.
        If None, it defaults to floor(2/3) of `stimulus_fps`
        Similar to Nishimoto, 2011.

    quadrature_combination : function, optional
        Specifies how to combine the channel reponses quadratures.
        The function must take the sin and cos as arguments in order.
        Defaults to: (sin^2 + cos^2)^1/2
    output_nonlinearity : function, optional
        Passes the channels (after `quadrature_combination`) through a
        non-linearity. The function input is the (`n`,`nfilters`) array.
        Defaults to: ln(x + 1e-05)
    use_cuda: bool
        Whether the computation should happen on GPU

    moten_pyramid_parameters: dict
        See :func:`mk_moten_pyramid_params` for details on parameters
        specifiying a motion-energy pyramid.

    Returns
    -------
    filter_responses : np.array, (n, nfilters)
    """
    _, vdim, hdim = stimulus.shape
    aspect_ratio = moten_pyramid_parameters.get('aspect_ratio', hdim/float(vdim))
    stimulus = stimulus.reshape(stimulus.shape[0], -1)

    stimulus = torch.from_numpy(stimulus.astype('float32'))
    if use_cuda:
        stimulus = stimulus.cuda()

    if gabor_temporal_window is None:
        gabor_temporal_window = int(stimulus_fps*(2./3.))

    gabor_parameters = mk_moten_pyramid_params(stimulus_fps,
                                               gabor_temporal_window,
                                               aspect_ratio=aspect_ratio,
                                               **moten_pyramid_parameters)

    channels = []

    for idx, gabor_param in enumerate(gabor_parameters):
        gabor = mk_3d_gabor((hdim,vdim,gabor_temporal_window),
                            *gabor_param,
                            aspect_ratio=aspect_ratio)
        gabor = map(np.float32, gabor)
        gabor0, gabor90, tgabor0, tgabor90 = map(torch.from_numpy, gabor)
        if use_cuda:
            gabor0, gabor90, tgabor0, tgabor90 = (gabor0.cuda(),
                                                  gabor90.cuda(),
                                                  tgabor0.cuda(),
                                                  tgabor90.cuda())


        channel_sin, channel_cos = dotdelay_frames(gabor0, gabor90,
                                                   tgabor0, tgabor90,
                                                   stimulus,
                                                   )
        channel = quadrature_combination(channel_sin, channel_cos)
        channels.append(channel)
    channels = torch.stack(channels, 1)
    channels = output_nonlinearity(channels)
    return channels


from .motion_energy_aone import mk_spatiotemporal_gabor
from .motion_energy_aone import mk_moten_pyramid_params

##############################
# core functionality
##############################

from .motion_energy_aone import mk_3d_gabor
from numbers import Number

def dotspatial_frames(spatial_gabor_sin, spatial_gabor_cos,
                      stimuli,
                      mask=0.001):
    '''Dot the spatial gabor filters filter with the stimuli

    Parameters
    ----------
    spatial_gabor_sin, spatial_gabor_cos : np.array, (vdim,hdim)
        Spatial gabor quadrature pair
    stimuli : 2D np.array (n, vdim*hdim)
        The movie frames with the spatial dimension collapsed.
    mask : binary mask or float-like
        non-zero filter region or threshold to find the non-zero filter region

    Returns
    -------
    channel_sin, channel_cos : np.ndarray, (n, )
        The filter response to each stimulus
        The quadrature pair can be combined: (x^2 + y^2)^0.5
    '''
    gabors = torch.stack([spatial_gabor_sin.reshape(-1),
                        spatial_gabor_cos.reshape(-1)], 0)

    # dot the gabors with the stimuli
    if isinstance(mask, Number):
        mask = torch.abs(gabors).sum(0) > mask
    else:
        assert mask.dtype == torch.uint8

    gabor_prod = torch.mm(gabors[:,mask].squeeze(),
                          stimuli.t()[mask].squeeze()).t()
    gabor_sin, gabor_cos = gabor_prod[:,0], gabor_prod[:,1]
    return gabor_sin, gabor_cos


def dotdelay_frames(spatial_gabor_sin, spatial_gabor_cos,
                    temporal_gabor_sin, temporal_gabor_cos,
                    stimulus,
                    mask=0.001):
    '''Convolve the motion-energy filter with a stimulus

    Parameters
    ----------
    spatial_gabor_sin, spatial_gabor_cos : np.array, (vdim,hdim)
        Spatial gabor quadrature pair

    temporal_gabor_sin, temporal_gabor_cos : np.array, (tdim)
        Temporal gabor quadrature pair

    stimulus : 2D np.array (n, vdim*hdim)
        The movie frames with the spatial dimension collapsed.

    Returns
    -------
    channel_sin, channel_cos : np.ndarray, (n, )
        The filter response to the stimulus at each time point
        The quadrature pair can be combined: (x^2 + y^2)^0.5
    '''

    if isinstance(mask, Number):
        mask = torch.abs(spatial_gabor_sin) + torch.abs(spatial_gabor_cos) > mask
        mask = mask.reshape(-1)
    else:
        assert mask.dtype == torch.uint8

    gabor_sin, gabor_cos = dotspatial_frames(spatial_gabor_sin, spatial_gabor_cos,
                                             stimulus, mask=mask)
    gabor_prod = torch.stack([gabor_sin, gabor_cos], 1)


    temporal_gabors = torch.stack([temporal_gabor_sin,
                                  temporal_gabor_cos], 0)

    # dot the product with the temporal gabors
    outs = (torch.mm(gabor_prod[:, [0]], temporal_gabors[[1]]) +
            torch.mm(gabor_prod[:, [1]], temporal_gabors[[0]]))
    outc = (torch.mm(-gabor_prod[:, [0]], temporal_gabors[[0]]) +
            torch.mm(gabor_prod[:, [1]], temporal_gabors[[1]]))

    # sum across delays
    nouts = torch.zeros_like(outs)
    noutc = torch.zeros_like(outc)
    tdxc = int(np.ceil(outs.shape[1]/2.0))
    delays = np.arange(outs.shape[1])-tdxc +1
    for ddx, num in enumerate(delays):
        if num == 0:
            nouts[:, ddx] = outs[:,ddx]
            noutc[:, ddx] = outc[:,ddx]
        elif num > 0:
            nouts[num:, ddx] = outs[:-num,ddx]
            noutc[num:, ddx] = outc[:-num,ddx]
        elif num < 0:
            nouts[:num, ddx] = outs[abs(num):,ddx]
            noutc[:num, ddx] = outc[abs(num):,ddx]

    channel_sin = nouts.sum(-1)
    channel_cos = noutc.sum(-1)
    return channel_sin, channel_cos


quadrature_combination = _sqrt_sum_squares
output_nonlinearity = _log_compress

class MotenTransformer(torch.nn.Module):
    def __init__(self, height, width, fps, gabor_temporal_window=None,
                    temporal_frequencies=(0, 2, 4),
                    spatial_frequencies=(0, 2, 4, 8, 16, 32),
                    spatial_directions=(0, 45, 90, 135, 180, 225, 270, 315),
                    sf_gauss_ratio=0.6,
                    max_spatial_env=0.3,
                    gabor_spacing=3.5,
                    tf_gauss_ratio=10.,
                    max_temp_env=0.3,
                    aspect_ratio=1.0,
                    include_edges=False,
                    precompute_filters=True,
                    all_filters_on_device=True,
                    mask_threshold=0.001):
        super(MotenTransformer, self).__init__()

        self.height = height
        self.width = width
        self.fps = fps
        self.gabor_temporal_window = gabor_temporal_window
        self.temporal_frequencies = temporal_frequencies
        self.spatial_frequencies = spatial_frequencies
        self.spatial_directions = spatial_directions
        self.sf_gauss_ratio = sf_gauss_ratio
        self.max_spatial_env = max_spatial_env
        self.gabor_spacing = gabor_spacing
        self.tf_gauss_ratio = tf_gauss_ratio
        self.max_temp_env = max_temp_env
        self.aspect_ratio = aspect_ratio
        self.include_edges = include_edges
        self.precompute_filters = precompute_filters
        self.all_filters_on_device = all_filters_on_device
        self.mask_threshold = mask_threshold

        self.build()

    def build(self):
        if self.gabor_temporal_window is None:
            gabor_temporal_window = int(2./3. * self.fps)
        else:
            gabor_temporal_window = self.gabor_temporal_window
        self.moten_pyramid_params = mk_moten_pyramid_params(
                                self.fps, 
                                gabor_temporal_window,
                                temporal_frequencies=self.temporal_frequencies,
                                spatial_frequencies=self.spatial_frequencies,
                                spatial_directions=self.spatial_directions,
                                sf_gauss_ratio=self.sf_gauss_ratio,
                                max_spatial_env=self.max_spatial_env,
                                gabor_spacing=self.gabor_spacing,
                                tf_gauss_ratio=self.tf_gauss_ratio,
                                max_temp_env=self.max_temp_env,
                                aspect_ratio=self.aspect_ratio,
                                include_edges=self.include_edges)

        if not self.precompute_filters:
            raise NotImplementedError("Please select precompute_filters=True")
        
        self.filters = [
            mk_3d_gabor((self.height, self.width, gabor_temporal_window),
                        *gabor_param,
                        aspect_ratio=self.aspect_ratio)
            for gabor_param in self.moten_pyramid_params
        ]
        
        if not self.all_filters_on_device:
            raise NotImplementedError("Please select "
                                      "all_filters_on_device=True")

        self.gabor0 = BufferList()
        self.gabor90 = BufferList()
        self.tgabor0 = BufferList()
        self.tgabor90 = BufferList()
        self.masks = BufferList()

        
        for gabor0, gabor90, tgabor0, tgabor90 in self.filters:
            self.gabor0.append(torch.from_numpy(gabor0.astype('float32')))
            self.gabor90.append(torch.from_numpy(gabor90.astype('float32')))
            self.tgabor0.append(torch.from_numpy(tgabor0.astype('float32')))
            self.tgabor90.append(torch.from_numpy(tgabor90.astype('float32')))

            mask = (torch.abs(self.gabor0[-1]) + 
                    torch.abs(self.gabor90[-1])) > self.mask_threshold
            self.masks.append(mask)



    def forward(self, x):
        """Transforms a batch of videos to its spatio-temporal gabor responses.

        Parameters
        ==========

        x: torch array, shape = (batch, frames, height, width)

        
        Note: roughly implements what compute_filter_responses does
        """
        
        B, T, H, W = x.shape

        all_samples = []

        for x_ in x:
            all_channels = []
            for g0, g90, tg0, tg90, mask in zip(self.gabor0, self.gabor90,
                                                self.tgabor0, self.tgabor90,
                                                self.masks):
                channel_sin, channel_cos = dotdelay_frames(g0, g90, tg0, tg90,
                                                     stimulus=x_.reshape(T, -1),
                                                     mask=mask.reshape(-1))

                channel = output_nonlinearity(
                          quadrature_combination(channel_sin, channel_cos))

                all_channels.append(channel)
            all_samples.append(torch.stack(all_channels, -1))
        output = torch.stack(all_samples, 0)
        return output
        



if __name__ == '__main__':
    pass
