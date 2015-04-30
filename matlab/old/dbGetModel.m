function varargout = dbGetModel(qStim,qMod,TrnVal,db)
% Usage: [model,mObj] = dbGetModel(qStim,qMod,TrnVal,db)
% 
% Get a model design matrix from a STRF database
% 
% Inputs: 
%   qStim : struct array (or cell array to form struct array) with which to
%       query database for stimulus. Type='Stimulus' is set for you.
%   qMod : same, for model (qStim is used to search for the model, too).
%       Type='PreprocessedStimulus' is set for you.
%   TrnVal : string or cell array of strings {'trn','val'} for whether to
%       return trn, val, or both (if they exist). leave blank to avoid
%       searching for trn/val field. ( {} )
%   db : mlabSTRFdb instance
% Outputs: 
%   model : design matrix (matrices) for model; if TrnVal is specified,
%       model is a struct (model.trn, model.val)
%   mObj : (optional) also a struct (or not) like model, returns
%       PreprocessedStimulus objects instead of just raw matrices
% 
% ML 2012.04.09

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
% Allow cell array inputs instead of structs
if iscell(qStim)
    qStim = struct(qStim{:});
end
if iscell(qMod)
    qMod = struct(qMod{:});
end
% For assured faster search
qStim.Type = 'Stimulus';
% Loop over trn / val (or not)
if ~isempty(TrnVal)
    for iTV = 1:length(TrnVal)
        % Get trn/val stimulus
        qStim.trnval = TrnVal{iTV};
        % Get model
        %AllParts = true; % Vary this??
        qMod.Type = 'PreprocessedStimulus';
        qMod.mStim = qStim; %% S(1).dbStruct(AllParts);
        mTmp = PreprocessedStimulus([],qMod,db);
        mTmp = mTmp.dbGet();
        if nargout==2
            mObj.(TrnVal{iTV}) = mTmp.dbStruct(false);
        end
        mTmp = mTmp.load();
        model.(TrnVal{iTV}) = mTmp.S;
    end
else
    % Get model
    %AllParts = true; % Vary this??
    qMod.Type = 'PreprocessedStimulus';
    qMod.mStim = qStim;
    mTmp = PreprocessedStimulus([],qMod);
    mTmp = mTmp.dbGet();
    if nargout==2
        mObj = mTmp;
    end
    mTmp = mTmp.load();
    model = mTmp.S;
end
varargout{1} = model;
if nargout>1
    varargout{2} = mObj;
end