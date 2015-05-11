function [varargout] = preprocSemanticCat(S,params)
% Usage: [Spreproc, params] = preprocSemanticCat(S,params)
% 
% Preprocesses models of N semantic category labels. All this really does
% is concatenate stimulus matrices for different runs as of 2012.12
% 
% Inputs
%   S = frame-by-frame stimulus coding. Can be a matrix (frames x
%     categories) or a string or wildcard string pointing to files that
%     contain (frames x categories) matrices. 
%   params = struct array. Call params = preprocSemanticCat; to get
%     default parameters (this is a useless thing to do; just kept for
%     convention / consistency w/ other preproc functions)
% 
% ML 2012.12.18

% Default parameters
pDefault.nCategories = nan; % set from stimulus below
pDefault.nonLinearOut = 'none'; % Does nothing - not implemented yet! 
pDefault.class = 'preprocSemanticCat';
pDefault.normalize = true;
% pDefault.crop = []; % limits for stimulus values?

if ~nargin
    varargout{1} = pDefault;
    return;
end
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,pDefault);
params.categories = {};

%%% Load stimulus coding per frame
if ischar(S)
    fDir = fileparts(S);
    stimF = dir(S);
    Ss = cellfun(@(x) fullfile(fDir,x),{stimF.name}','uniformoutput',false);
    %Ss = mlAddToCell({stimF.name}',[fDir filesep],true);
    nParts = length(Ss); 
    sAll = [];
    for iPart = 1:nParts
        load(Ss{iPart},'S','Cats');
        if all(~ismember(Cats,params.categories))
            params.categories = Cats;
        elseif any(ismember(Cats,params.categories)) && ~all(ismember(Cats,params.categories))
            % Only SOME categories match between runs; this is a problem!
            % At least COLUMNS for all categories should be present in all
            % runs, else the matrices will (probably) not concatenate
            % correctly.
            error('Category mismatch! You seem to have different categories present in different runs!')
        end            
        % Sub-optimal to not pre-allocate, but it shouldn't matter.
        sAll = [sAll;S];
    end
    Spreproc = sAll;
elseif isnumeric(S)
    Spreproc = S;
else
    error('WTF kind of stimulus did you give me??')
end
if isnan(params.nCategories)
    params.nCategories = size(Spreproc,2);
else
    disp('Why are you trying to set categories??')
end

if params.normalize
    if isfield(params, 'means') % Already preprocessed. Use the means and stds
        global s; s = Spreproc; clear Spreproc; % a trick to modify Spreproc without copying it
        [stds, means] = norm_std_mean_global(params.stds, params.means);
        Spreproc = s; clear s;
    else
        global s; s = Spreproc; clear Spreproc; % a trick to modify Spreproc without copying it
        [stds, means] = norm_std_mean_global();
        Spreproc = s; clear s;
        params.means = means;
        params.stds = stds;
    end
end

% All done!
% (Return Spreproc, save elsewhere)
varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end