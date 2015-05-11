function varargout = dbCheck2(ModStruct,STRFdb,dbName,Exclude)
% Usage: [ModStruct [,IsNewModel][,OldModel]] = dbCheck(ModStruct,STRFdb,dbName,Exclude)
% 
% Query a STRFdb (couch db) with a struct array to see if an item with
% paramaters matching the struct array's parameters already exists. Note
% that this can be a PARTIAL match, which can return multiple database
% entries. 
% 
% Inputs: 
%   ModStruct = struct array for model / whatever, to be inserted in to
%       strfdb
%   STRFdb = address for couchdb (default = GLab's db: 'http://meth:5984')
%   dbName = name of database within couchdb (default = ML's 'strfdb-ml')
%   Exclude = names of fields in ModStruct to exclude from comparison
% 
% Outputs: 
%   ModStruct = a struct array identical to the input, but with the fields
%       below added. If multiple matching entries are found, this returns
%       an empty array.
%   .id % uuid name for db entry
%   .rev % (only present if file already exists) revision number in
%       database
%   .Path % path name to save file (local path only)
%   [Optional: ]
%   IsNewModel = T/F - whether a matching struct was found in the database
%   OldModel = full struct array for entries that were found in the
%      database 
% 
% If the following fields are present in ModStruct, they will be added to
% the Path variable (this keeps the path from being pure UUID gibberish)
%   .Mod % model identifier string
%   .SubID % subject identifier string 
% 
% NOTE: potentially dangerous - in that if a model with FEWER specifiers
% than an older (but different) model is inserted, it could return an ID
% for a different model, and that ID could then be used to over-write that
% (different) older model. This is unlikely to happen, since model
% development usually ADDS parameters / variations to models rather than
% subtracting them (or: even if they are subtracted, the absence of a
% parameter will be noted as distinct from its presence). 
% 
% THE POINT IS: be careful, and use the NewModel output judiciously. 
% 
% NOTE 2: This can run slowly for large databases. The bottleneck isn't the
% actual query of the couch database; it's parsing the resulting json file.
% AFAIK, there is no really good matlab parser for long json strings. The
% one this currently uses is from jsonlab
% (http://www.mathworks.com/matlabcentral/fileexchange/33381), which seems
% to be the best around (as of 2013.02.27)
% 
% ML 2012.05.25

if ~exist('STRFdb','var')||isempty(STRFdb)
    STRFdb = 'http://meth:5984';
end
if ~exist('dbName','var')||isempty(dbName)
    dbName = 'strfdb-ml';
end
if ~exist('Exclude','var')||isempty(Exclude)
    Exclude = {};
end
if ~exist('tmpDir','var')
    tmpDir = '/tmp/';
end
prefix = 'x0x5F'; % Hex code for "_"; added to json fields starting with _
% Add potentially problematic fields to "Exclude":
% (These are descriptive text strings attached to the model, and are not
% necessary to determine if a model has been run)

ToExclude = {'AxLabel','Descr','DateRun'};
for iE = 1:length(ToExclude);
    if ~ismember(ToExclude{iE},Exclude)
        Exclude = [Exclude,ToExclude{iE}];
    end
end
qStr = ModStruct;
for iE = 1:length(Exclude);
    if isfield(qStr,Exclude{iE})
        qStr = rmfield(qStr,Exclude{iE});
    end
end
% Query database w/ python function
Models = dbQuery(qStr,STRFdb,dbName); % leave default opts...?

% If new model, get ID & Path
if isempty(Models)
    NewModel = true;
    fprintf('Model not found - creating new model id/path!\n\n')
    uuid = getUUID;
    % add SubID & Mod to save path, if available, for intelligibility
%     if isfield(ModStruct,'SubID') && isfield(ModStruct,'Mod')
%         if iscell(ModStruct.Mod)
%             ModStr = sprintf('%s_',ModStruct.Mod{:});
%             ModStr = ModStr(1:end-1);
%         else
%             ModStr = ModStruct.Mod;
%         end
%         if length(ModStr)>128
%             % Clip too-long model names
%             ModStr = [ModStr(1:20) '_BlahBlahBlah'];
%         end
%         ModStruct.Path = sprintf('Sub%s_%s_%s.mat',ModStruct.SubID,ModStr,uuid);
%     elseif isfield(ModStruct,'ModelX') && isfield(ModStruct,'ModelY')
%         ModStruct.Path = sprintf('%s_pred_%s_%s.mat',ModStruct.ModelX,ModStruct.ModelY,uuid);
%     else
    ModStruct.Path = sprintf('%s.mat',uuid);
%     end
    ModStruct.([prefix '_id']) = uuid; % prefix is removed by savejson before being uploaded
    ModOut = [];
elseif length(Models)==1
    NewModel = false;
    fprintf('Model found: \n%10s : %s\n%10s : %s\n%10s : %s\n',...
        'id',Models.([prefix '_id']),'rev',Models.([prefix '_rev']),'path',Models.Path);
    try
        % A little more info, if available:
        fprintf('%10s : %s\n%10s : %s\n',...
            'ValDat',Models.value.ValDat,'NoisePreds',Models.value.NoisePreds{:});
    catch ME
        disp('Model info not available:')
        fprintf(ME.message)
    end
    fprintf('\n\n')
    ModStruct = Models;
    ModOut = Models;
elseif length(Models)>1
    NewModel = false;
    ModStruct = [];
    ModOut = Models;
end

% Outputs
varargout{1} = ModStruct;
if nargout == 2
    varargout{2} = NewModel;
elseif nargout == 3
    varargout{2} = NewModel;
    varargout{3} = ModOut;
end
% Done! 
function uuid = getUUID
[s,UUID] = system('uuidgen');
uuid = strrep(lower(UUID(1:end-1)),'-',''); % end-1 because the system adds a newline character
end

end

