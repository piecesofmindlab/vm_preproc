function B = dbFill(A,Type,AllParts,db)
% Usage: B = dbFill(A,Type,AllParts,db)
% 
% Quick fill-in from database of a partial (but unique!) identifier struct
% array.
% 
% ML 2013.04

% Inputs
if iscell(A)
    A = struct(A{:});
end
switch lower(Type)
    case {'stimulus','s','stim'}
        Type = 'Stimulus';
    case {'preprocessedstimulus','spp'}
        Type = 'PreprocessedStimulus';
end
if ~exist('AllParts','var')||isempty(AllParts)
    AllParts = true;
end
if ~exist('db','var')
    db = mlabSTRFdb;
end
A.Type = Type;
S = feval(Type,[],A,db);
S = S.dbGet();
B = S.dbStruct(AllParts);