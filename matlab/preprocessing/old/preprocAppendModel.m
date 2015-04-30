function varargout = preprocAppendModel(S,params)
% Usage: varargout = preprocAppendModel(S,params)
% 
% Append (add channels from) another preprocessed model to S
% 
% NOTE: This is a different kind of preprocessing from other steps! S must
% be a PreprocessedStimulus object, and it must have meta-information
% present about the experiment and whether this is a training/validation
% run (S.oStimulus or S.Stimulus, and S.extra.trnval)
% 
% 
% ML 2013.05

% Defaults:
dParams.class = 'preprocAppendModel';
% (NOTE! there can't really be any defaults for this, you have to specify 
dParams.LeftRight = 'Right'; % Which side of the matrix S to append the new model to
dParams.stimToAdd = [];
dParams.ppSeqToAdd = [];
dParams.db = mlabSTRFdb;
if ~exist('params','var')
    params = struct;
end    
params = defaultOpt(params,dParams);
if ~nargin
    varargout{1} = params;
    return
end
%keyboard;
% Set up search for other model!
q.Type = 'PreprocessedStimulus';
q.mStim = params.stimToAdd;
q.ppSeq = params.ppSeqToAdd;
% Add info from S object
if isfield(S.extra,'trnval')
    q.mStim.trnval = S.extra.trnval;
end
if isfield(S.extra,'oStimulus')
    q.mStim.exp = S.extra.oStimulus.exp;
    q.mStim.session = S.extra.oStimulus.session;
else
    q.mStim.exp = S.Stimulus.exp;
    q.mStim.session = S.Stimulus.session;
end

% Query database
ToAdd = params.db.query(q);
if length(ToAdd)>1
    error('Multiple models found!')
elseif isempty(ToAdd)
    error('Model to be appended not found!')
end
% Get Spreproc,params model to be appended
mio = matfile(ToAdd.path);
% Size check. Because fuckups happen.
if isfield(S.extra,'oStimulus') && ~isempty(strfind(S.extra.oStimulus.StimClass,'short'))
    % If any stimuli are accidentally curtailed, they should have "short"
    % in the oStimulus "StimClass" field. This will make S.S shorter in the
    % first dimension than mio.Spreproc. Thus this index. Lame, but
    % necessary.
    eIdx = S.nFrames;
else
    eIdx = size(mio,'Spreproc',1);
end
    
switch params.LeftRight
    case 'Left'
        Spreproc = [mio.Spreproc(1:eIdx,:),S.S];
    case 'Right'
        Spreproc = [S.S,mio.Spreproc(1:eIdx,:)];
end
params.appendedParams = mio.params;
% Output
varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end