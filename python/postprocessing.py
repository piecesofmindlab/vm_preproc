"""Postprocessing"""
from __future__ import division


'''
Complexities:
How should each step be specified? 
    A. as a class (with a run method)
    B. as a funtion

How should parameters be stored?
    A. in the database, as sets... 
        ** as a param_set class, with 'function' as a key in the docdict 
           and 'tag' as another
        ** only query by function and tag? 
        ** ...or also to complete a param set?
    B. along with a specific stimulus, as a Thing That Happened
    -> I like B less, because it does not allow for reusable sets of 
        parameters (e.g. for stimuli for multiple runs, to be processsed the same way)
(are **kwargs calls to be avoided, then? )

How should concatenation of multiple parts take place?
    (When multiple parts exist for the sake of not breaking memory)
    A. Store parts as single stimulus ID with multiple paths
    B. Store parts as separate stimulus objects
    C. Store parts as a separate class - a sub-class of Stimulus (?)
    -> B or C seems better than A (which is the current situation)
    -> Concatenation can be a flag for any preproc step; if it exists, and a stimulus
    has multiple parts, then at the end of that step all parts are loaded and concatenated.

How should multi-part stimuli be handled? 
    A. As a separate class: multi-part input/stimulus
        - takes 

How to handle classes that overlap with vm_tools?
    A. Same class definitions as vm_tools, duplicated (obviously suboptimal)
    B. Make this all a part of vm_tools (seems insufficiently modular)
    C. Break out all classes as wrappers/db object storage, 
       make that the primary function of vm_tools
        * this leaves regression in glabtools (or whatever)
        * this leaves preprocessing funtions in vm_preproc (or whatever)
        * probably utils in vm_tools are better left in another package, too
        * database stuff should be in docdb_lite-like thing
        * fMRI preprocessing should be its own thing, but classes there should 
          interact with vm_tools classes - should be the same farking classes.
            --this is a biggie. There should be no hand-off between docdb preprocessing
            and data sets in vm_tools - it should all be the same objects / store.
        * This could make vm_tools the special sauce that I save for my own lab
        * still requires standard inputs for all functions in regression / 


def preproc_pipeline(input, preproc_steps, dbi=None, cluster_args=None):
    """Preprocess a stimulus object
    
    Parameters
    ----------
    input : vm_tools.Stimulus object
        should be a stimulus object
    """
    # Handle calls to process on cluster
    if cluster_args is None:
        cluster_args = {}
    # Parse all preproc_steps
    pp_classes, pp_arguments = parse_steps(preproc_steps)

    for pp_class, pp_args in zip(pp_classes, pp_arguments):
        # Initialize class
        ppstep = pp_class(**pp_args)
        # Run on input
        out = ppstep.run(out, **cluster_args)
        # (this instance should run a query, if dbi is specified)
        # out can be a string (for a database id), an array (for the raw data to be 
        processed) or a dict (of multiple databse ids or multiple arrays for different
        named inputs)

'''

def downsample(input_array, in_hz, out_hz, method='box', **kwargs):
    """Temporally downsamples input array

    Takes frames of a movie presented at 15 Hz and downsamples them to an fMRI sampling
    rate (TR) of .5 Hz (2 seconds / measurement). 
    Parameters
    ----------
    input_array : array
        Array with time as the first dimension
    in_hz : scalar
        Input_array sampling frequency (in hz)
    out_hz : scalar
        Output sampling frequency (in hz)
    method = string 
        Specifies type of downsampling: {'box', 'gauss', 'max', or 'none'}

    Notes
    -----
    TODO: Frameshifts?? From matlab code:
    if isfield(params,'frameshifts') && ~isempty(params.frameshifts)
        print('shifting %d frames...\n'%frameshifts)
        input_array = circshift(input_array, np.hstack([frameshifts, 0]))
    """ 
    fr_per_sample = out_hz / in_hz # should be an integer
    # downsample the preprocessed stimuli
    if method in ('box', 'max'):
        tframes = int(np.floor(input_array.shape[0] / fr_per_sample) * fr_per_sample)
        output_array = input_array[:tframes].reshape((fr_per_sample, -1)+ input_array.shape[1:])
        if method=='box':
            output_array = output_array.mean(0)
        elif method=='max':
            input_array = output_array.max(0)
    elif method=='gauss'
        # There must be some better way to downsample with a guassian kernel
        ksigma = kwargs['ksigma']
        if ksigma~=0:
            ki = np.arange(-ksigma * 2.5, ksigma*2.5, 1/fr_per_sample)
            k = np.exp(-ki**2 / (2 * ksigma**2))
            input_array = conv2(input_array, k.T/sum(k), 'same')
        
        sonset = 7
        if 'sonset' in kwargs:
            sonset = kwargs['sonset']
        output_array = input_array[sonset::fr_per_sample]
    return output_array

def normalize(input_array, **kwargs):
    """Z scoring or other normalization"""
    pass

def elementwise_nonlinearity(input_array, **kwargs):
    """For things like log, sqrt, raise to power, etc)"""
    pass


