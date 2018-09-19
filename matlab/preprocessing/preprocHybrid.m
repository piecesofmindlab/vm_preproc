function [stim, params] = preprocHybrid(rawStim, params)
% function [stim, params] = preprocHybrid(rawStim, params);
%
% A script for processing stimuli using multiple models
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

% processing
stim = [];
fcash = 0;
for ii=1:length(params.PPs)
    tp = params.PPs{ii};
    if isfield(params, 'cellid')
        tp.cellid = params.cellid;
    end
    disp(['preprocHybrid: calling ' tp.class]);
    [tstim, p] = cashedPreproc(tp, rawStim, fcash);
    %[tstim p] = feval(pclass, rawStim, params.PPs{ii});
    params.PPs{ii} = p;
    stim = cat(2,stim,tstim);
end


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

params.class = 'preprocHybrid';

return;

