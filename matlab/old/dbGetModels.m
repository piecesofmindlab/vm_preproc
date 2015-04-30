function varargout = dbGetModels(qStim,qMod,TrnVal,db)
% Usage: [model,[mObj]] = dbGetModels(qStim,qMod,TrnVal,db)
% 
% Get multiple models from a STRF database. Calls dbGetModel for each
% pair of items in qStim and qMod for trn/val separately as determined by
% TrnVal (see below). Returns design matrices ONLY (no
% PreprocessedStimulus objects).
% 
% Inputs: 
%   qStim : a cell array of structs (or cell array of cells to form struct
%       arrays) with which to query database for stimulus. 
%   qMod : same, for model (qStim is used to search for the model, too).
%       Type='PreprocessedStimulus' is set for you.
%   TrnVal : string or cell array of strings {'trn','val'} for whether to
%       return trn, val, or both (if they exist). leave blank to avoid
%       searching for trn/val field. ( {} )
%   db : mlabSTRFdb instance
% 
% Example: 
% qStim = {{'exp','BVP','StimClass','RGB'},{'exp','BVPpilot3','StimClass','RGB'}};
% ppSeq = {'preprocColorSpace',1,'preprocWavelets_grid',1,'preprocNonLinearOut',1,'preprocDownsample',1,'preprocNormalize',1};  
% qMod = {{'ppSeq',{ppSeq}}};
% db = mlabSTRFdb;
% [Model,mObj] = dbGetModels(qStim,qMod,{'trn','val'},db);
% 
% ML 2012.04.04

% Inputs
if ~exist('TrnVal','var') % empty is meaningful!
    TrnVal = {'trn','val'};
end
if ~exist('db','var')
    db = mlabSTRFdb;
end
if ~iscell(TrnVal)
    TrnVal = {TrnVal};
end
if ~iscell(qStim)
    qStim = {qStim};
end
if ~iscell(qMod)
    qMod = {qMod};
end
lenS = length(qStim);
lenM = length(qMod);
[x,y] = meshgrid(1:lenS,1:lenM);
qPairs = cellfun(@(x,y) {qStim{x},qMod{y}},num2cell(x(:)),num2cell(y(:)),'uni',false);

% Loop over trn / val (or not)
if ~isempty(TrnVal)
    % Note: trn/val will need to be concatenated separately
    model.trn = [];
    model.val = [];
    for iTV = 1:length(TrnVal)
        for iPr = 1:length(qPairs)
            qS = qPairs{iPr}{1};
            qM = qPairs{iPr}{2};
            [mTmp,mObjTmp] = dbGetModel(qS,qM,TrnVal{iTV},db);
            model.(TrnVal{iTV}) = [model.(TrnVal{iTV});mTmp.(TrnVal{iTV})];
            mObj.(TrnVal{iTV}){iPr} = mObjTmp.(TrnVal{iTV});
        end
    end
else
    model= [];
    mObj = {};
    for iPr = 1:length(qPairs)
        qS = qPairs{iPr}{1};
        qM = qPairs{iPr}{2};
        [mTmp,mObjTmp] = dbGetModel(qS,qM,{},db);
        model = [model;mTmp];
        mObj = [mObj;mObjTmp];
    end    
end
% Output
varargout{1} = model;
if nargout>1
    varargout{2} = mObj;
end