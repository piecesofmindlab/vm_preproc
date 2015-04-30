function params = preprocBuildPipeline(ppSeq,dbCache,Is_Overwrite,concat)
% Usage: params = preprocBuildPipeline(ppSeq,dbCache,Is_Overwrite,concat)
%
% Build a struct array of parameters from a cell array sequence of
% preprocessing steps in the form:
%
% {'preproc<X>',argNum,'preproc<Y>,argNum,...}
%
% where 'preproc<X,Y,etc>' are string names for preprocessing functions
% created according to STRFlab conventions, and argNum are pre-set argument
% numbers defined in functions called "preproc<X,Y,etc>_GetMetaParams.m"**
% 
% Other Inputs:
%   dbCache : boolean vector with one entry for each preprocessing stage;
%       whether to cache the result of each stage. A single value is
%       interpreted as whether to save the LAST stage (all others are
%       assumed to be false).
%   concat : boolean vector same as dbCache; whether to concatenate
%       separate stimulus inputs after each processing stage. Only ONE
%       stage should have a true value! ++ 
%
% **NOTE: I (ML) intend to update this so that preprocessing presets (w/
% argNums) are saved in the strfdb as well.
% 
% ++NOTE: Explain concat further.
% 
% ML 2013.03.20

% Inputs
if ~exist('dbCache','var')||isempty(dbCache)
    % Default to no saving
    dbCache = false;
end
nSteps = length(ppSeq)/2;
if length(dbCache) == 1;
    orig = dbCache;
    dbCache = false(nSteps,1);
    dbCache(end) = orig;
end
if ~exist('concat','var')||isempty(concat)
    % Default to no saving
    concat = false;
end
if length(concat) == 1;
    orig = concat;
    concat = false(nSteps,1);
    concat(end) = orig;
end
if ~exist('Is_Overwrite','var')||isempty(Is_Overwrite)
    Is_Overwrite = false;
end
if length(Is_Overwrite) == 1;
    Is_Overwrite = repmat(Is_Overwrite,nSteps,1);
end

% Separate functions from argNums
ppFn = ppSeq(1:2:end);
ppArg = ppSeq(2:2:end);
% Check on length of argNums
argLen = cellfun(@length,ppArg);
if any(argLen>1)
    % label/format this error...
    error([mfilename,':MultipleArgNums'],...
        ['You can only provide ONE argnum per preprocessing step!\n'...
        'Break up multiple options with preprocSeparatePipelines.m'])
end
% Get bottom-level params
params = eval([ppFn{1} '_GetMetaParams(' num2str(ppArg{1}) ');']);
params.ppSeq = ppSeq(1:2);
if dbCache(1)
    % Optionally, cache each stage of processing in database
    params.dbCache = true;
end
if concat(1)
    % Optionally, concatenate results at each stage of processing in database
    params.concatenatePreprocessedStimulus = true;
end
if Is_Overwrite(1)
    % Set whether to overwrite extant database files or not
    params.Is_Overwrite = true;
end    
params.argNum = ppArg{1};
ppTmp = params;
% Get higher-order params
for iArg = 2:length(ppArg)
    params = feval([ppFn{iArg} '_GetMetaParams'], ppArg{iArg});
    % Optionally, cache each stage of processing in database
    params.dbCache = dbCache(iArg);
    % Optionally, concatenate results at each stage of processing in database
    params.concatenatePreprocessedStimulus = concat(iArg);
    % Set whether to overwrite extant database files or not
    params.Is_Overwrite = Is_Overwrite(iArg);
    params.ppSeq = ppSeq(1:iArg*2);
    params.argNum = ppArg{iArg};
    params.PP = ppTmp;
    ppTmp = params;
end


