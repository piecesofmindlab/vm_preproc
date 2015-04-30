function varargout = preprocWaveletContrast(S,params)
% Usage: [Spreproc,params] = preprocWaveletContrast(S,params)
% 
% Computes contrast at each spatial location & scale in an already-computed
% Gabor wavelet model.
% 
% Inputs: 
%   S : preprocessed stimulus
%   params : struct array of parameters, with fields: 
%       .combineMethod : string, either: 'sum','mean','var','std', 'prod',
%           'std','max','min'
%       .PP : previous preprocessing steps' nested parameters. MUST be
%           called in a preprocPipeline after a preprocWavelet<x> function.
% 
% ML 2013.03.28

% TO DO:
% Other options for WHICH channels to combine? Currently, only channels w/
% same (x,y) position, spatial frequency, and size...

% Define the method to compute contrast. For now (2013.04), these are all
% WITHIN channels at a particular location and size, not across locations /
% sizes 
dParams.combineMethod = 'sum'; % 'var'; 'prod'; 'std';'max';'min';
% [1pos_x 2pos_y 3direction 4s_freq 5t_freq 6s_size 7t_size 8phasevalue]
dParams.avgOver = [1,2,4,6]; % so: KEEP pos x,y, sfreq,size
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);
params.class = 'preprocWaveletContrast';
% Return params if no inputs
if ~nargin
    warning([mfilename ':NeedPP'],['NOTE! %s can only be processed if params contains a .PP sub-field\n'...
        'for a previously-processed call to preprocWavelets_grid.m!']);
    varargout{1} = params;
    return
end
% Extra error catch:
if ~isfield(params,'PP')
    error([mfilename ':BadParams'],['The parameters you feed to %s MUST have params.PP, so that\n'...
        '%s knows how to compute contrast across Gabor channels!'],mfilename,mfilename);
end
% Get gabor parameters
gPP = params.PP;
while ~ismember(gPP.class,{'preprocWavelets_grid'}) % More?
    gPP = params.PP;
    if ~isfield(gPP,'PP')
        error('Could not find "preprocWavelets<variant>" in any params.PP...PP field!')
    end
end
% gaborparams matrix has rows:
% [1pos_x 2pos_y 3direction 4s_freq 5t_freq 6s_size 7t_size 8phasevalue]
gp = gPP.gaborparams(params.avgOver,:)';
ugp = unique(gp,'rows');
% dim 1 = time, dim 2 = unique posX,posY,sFreq,sSize
Spreproc = zeros(size(S,1),size(ugp,1));
for iG = 1:size(ugp,1)
    idx = all(repmat(ugp(iG,:),[size(gp,1),1])==gp,2);
    if ismember(params.combineMethod,{'var','std','max','min'});
        Spreproc(:,iG) = feval(params.combineMethod,S(:,idx),[],2);
    elseif ismember(params.combineMethod,{'mean','sum'})
        Spreproc(:,iG) = feval(params.combineMethod,S(:,idx),2);
    else
        error('not yet!')
    end
end
params.gaborparams = ugp';
% Output
varargout{1} = Spreproc;
if nargout >1
    varargout{2} = params;
end

function softMax(S,params)
