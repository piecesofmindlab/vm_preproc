function varargout = preprocTF(S,params)
% Usage: [Spreproc,params] = preprocTF(S,params)
% 
% Filters a stimulus (presumably at a higher framerate than the sampling
%   frequency) at temporal frequencies defined by "params" struct array,
%   and returns the concatenated filtered channels. e.g., if the original
%   stimulus matrix S was [t x ch], the matrix Spreproc is [t x ntfs*ch]
% 
% Inputs: 
%   S : Stimulus, 2D matrix of time x channels
%   params : struct array of parameters, with fields: 
%       .tfmin : min TF; [default 1.333333] (@15fps,.tsize=10, this is 2Hz)
%       .tfmax : max TF; [default 2.666666] (@15fps,.tsize=10, this is 4Hz)
%       .tsize : window size, in frames, over which to compute temporal
%               frequencies [default 10]
%       .tfdivisions : number of temporal frequencies to include. ** for
%               now, these will be LOG SPACED between .tfmin and .tfmax
%       .zerotf : T/F, whether to include zero TF [default true]
%  
% NOTE: tfmin and tfmax are temporal frequencies PER .tsize!! To convert
% them to Hz, you need to know your stimulus presentation rate, which is
% (deliberately and reasonably) outside the scope of this function
% 
% ML 2012.11.16
% Updated 2013.03.21

% Defaults
dParams.tfmin = 1.333333; % This is 2 hz @ stim framerate of 15 hz
dParams.tfmax = 2.666666; % This is 4 hz @ stim framerate of 15 hz
dParams.tsize = 10; % Number of frames to use in computation
dParams.zerotf = true; % include 0 hz freq as well
dParams.tfdivisions = 3;
% Fill params w/ defaults
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);
% Return params if no input
if ~nargin
    varargout{1} = dParams;
    return
end

% Collapse across time to shrink whole matrix with temporal wavelets
if params.zerotf
    % logspace w/ 0 as last argument returns empty matrix.
    tf_array = logspace(log10(params.tfmin), log10(params.tfmax), params.tfdivisions-1);
    tf_array = [0 tf_array]; 
else
    tf_array = logspace(log10(params.tfmin), log10(params.tfmax), params.tfdivisions);
end
ntf = length(tf_array);
% Preallocate variable to store different temporal frequencies:
Stf = zeros([size(S),ntf]);
for itf = 1:ntf
    % Create filters
    % NOTE: wtf is this 3.5 value??
    gc = normpdf(linspace(-3.5,3.5,params.tsize)) .* cos(linspace(0,2*pi*tf_array(itf),params.tsize));
    gs = normpdf(linspace(-3.5,3.5,params.tsize)) .* sin(linspace(0,2*pi*tf_array(itf),params.tsize));
    % Convolve
    sc = conv2(gc,1,S,'same'); % Is "Same" safe to use here?? CHECK!!
    ss = conv2(gs,1,S,'same');
    % Square and sum
    Stf(:,:,itf) = sc.^2 + ss.^2;
end
% Concatenate temporal channels onto the end
Spreproc = reshape(Stf,[size(Stf,1),size(Stf,2)*size(Stf,3)]);

% Outputs
varargout{1} = Spreproc;
if nargout>1
    varargout{2} = params;
end