function [stim, params] = preprocTexture(stim, params)
% function [stim, params] = preprocTexture(rawStim, params);
%
% A script for processing texture Gabor channels
%
% ====================

%%% Set up parameters
if ~exist('params','var')
    params = [];
end
params = setDefaultParameters(params);

if nargin<1 % just called to set the default set of parameters
    stim = params;
    return;
end

% get texture map (high-pass)
disp('high-pass filtering...');
stim = calchighpass2d(stim, [params.freq params.slope]);
disp('done.');

% % take absokute values if needed
if isfield(params,'abs') && params.abs
    disp('calculating abs...');
    stim = abs(stim);
    disp('done.');
end

% % gamma correct if needed
if isfield(params,'gamma') && params.gamma ~= 1.0
    disp(['gamma-correction...' sprintf('[%.2f]',params.gamma)]);
    stim = abs(stim).^params.gamma;
    disp('done.');
end

% structural preprocessing
[stim p] = feval(params.PP.class, stim, params.PP);
params.PP = p;


% normalize std and mean if requested
if params.normalize
    if isfield(params, 'means') % Already preprocessed. Use the means and stds
        global s; s = stim; clear stim; % a trick to modify stim without copying it
        norm_std_mean_global(params.stds, params.means);
        stim = s; clear s;
    else
        global s; s = stim; clear stim; % a trick to modify stim without copying it
        [stds, means] = norm_std_mean_global();
        stim = s; clear s;
        params.means = means;
        params.stds = stds;
    end
end

params.nChan = size(stim,2);

return


%---------------------------------------------------------------------
%  Default parameter settings
%---------------------------------------------------------------------

function params = setDefaultParameters(params)

if ~isfield(params, 'normalize')
    params.normalize = 1;
end

if ~isfield(params, 'freq')
    params.freq = 20;
end

if ~isfield(params, 'slope')
    params.slope = 30;
end

% if ~isfield(params, 'gamma')
%     params.gamma = 1.0;
% end

% if ~isfield(params, 'abs')
%     params.abs = 0;
% end

params.class = 'preprocTexture';

return;

