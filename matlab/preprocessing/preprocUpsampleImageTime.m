function varargout = preprocUpsampleImageTime(S, params)
% Usage: [S params] = preprocUpsample(S, params)
% 
% Upsamples stimuli to (Electrophys or other) sampling rate; e.g., takes 
% frames of a movie presented at 30 Hz and upsamples them to 60 Hz bins for
% ephys spike rates. 
% 
% Inputs: 
%   S = preprocessed stimulus matrix, [time x channels]
%   params = nested preprocessing parameter struct array, with fields:
%       .dsType = string specifying type of downsampling: 'box' [default],
%           'gauss', 'max', or 'none'
%       .gaussParams = 2-element array specifying [,] (??). Only necessary
%           if params.dsType = 'gauss'
%   params = struct array with fields:  
%       ** NOTE: no defaults! you must provide this argument! **
%       .imHz = frame rate of stimulus in Hz 
%       .SampleSec = length in seconds of 1 sample of data (for fMRI, this
%           is the TR or repetition time)
%           


% Default parameters
dParams.usType = 'double';
dParams.from_hz = 30;
dParams.to_hz = 60;
dParams.frameshifts = []; % empty = no shift
dParams.gaussParams = []; %[1,2]; % sigma,mean
% Fill in default params
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);
% Return params if no inputs
if ~nargin
    varargout{1} = params;
    return
end

% downsample the preprocessed stimuli
switch params.usType
    case 'double'
        if ndims(S)==4
            [x,y,c,t] = size(S);
            Sx2 = zeros(x,y,c,t*2);
            Sx2(:,:,:,1:2:end) = S;
            Sx2(:,:,:,2:2:end) = S;
        elseif ndims(S)==3
            [x,y,t] = size(S);
            Sx2 = zeros(x,y,t*2);
            Sx2(:,:,1:2:end) = S;
            Sx2(:,:,2:2:end) = S;
        end
end

% Output
varargout{1} = Sx2;
if nargout>1
    varargout{2} = params;
end
