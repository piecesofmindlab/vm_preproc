function Out = dbQuery(qParams,STRFdb,dbName,tmpDir,Opts)
% Usage: Out = dbQuery(qParams,STRFdb,dbName,tmpDir,Opts)
% 
% Query a STRFdb (couch db) with a struct array to see if an item with
% paramaters matching the struct array's parameters exist. Note
% that this can be a PARTIAL match, which can return multiple database
% entries. 
% 
% Inputs: 
%   qParams = struct array for of parameters for database item
%   STRFdb = address for couchdb (default = GLab's db: 'http://meth:5984')
%   dbName = name of database within couchdb (default = ML's 'strfdb-ml')
%   tmpDir = where to write temporary file created to do json interface btw
%       matlab and python (default='/tmp/')
%   Opts = a 
%   prefix = string to be added to field names that have '_' as the first
%       character (allowable in python, but not matlab) (default='x0x5f' -
%       probably not a good idea to change this!) 
% 
% Outputs: 
%   Out = a struct array containing all models that match query terms.
%   This will always contain the following fields: 
%   .<prefix>_id % uuid name for db entry
%   .<prefix>_rev % (only present if file already exists) revision number in
%       database
%   .Path % path name to save file (local path only)
% 
% NOTES: 
% This code uses jsonlab to convert matlab struct arrays to json objects
% (and vice versa). Relevant functions are savejson.m and loadjson.m, code
% at http://www.mathworks.com/matlabcentral/fileexchange/33381
% This works, but with a few IMPORTANT caveats: 
% (1) Several variable types cannot be reliably converted to and from json,
% either in python OR in matlab (though there are more problems with
% matlab). There are also some ambiguities. Here's a short list of stuff
% that has come up so far (that I'm basically working around): 
%   - single-element cell arrays of strings are converted to strings
%   - python "None" is converted to ' null' in matlab. (round-trip OK in
%       python? ___ )
% 
% ( ) Big json files (very long strings) take a long time to parse. Thus if
% your query returns many results, it will take a long time to process.
% This is why I use python for the actual database query (which often
% involves very large json objects for large databases); python's database
% querying seems to either avoid long strings entirely or is much faster at
% handling them than matlab.  
% 
% ( ) Couch database objects all have _id and _rev fields; these are not
% allowable field names in matlab struct arrays. jsonlab's savejson.m adds
% a prefix to any fields that start with "_" 
% 
% ( ) This method is NOT great for working with large / complex arrays!
% I don't usually store large objects in the couch db, only meta/ header
% info to identify the objects, including a "path" field to show where the
% bigger data is saved.  
% 
% 
% ML 2013.03.18

if ~exist('STRFdb','var')||isempty(STRFdb)
    STRFdb = 'http://meth:5984';
end
if ~exist('dbName','var')||isempty(dbName)
    dbName = 'strfdb-ml';
end
if ~exist('tmpDir','var')
    tmpDir = '/tmp/';
end
if ~exist('STRFpath','var')
    % Hacky. hard-coded. Must be a better way to do this. 
    STRFpath = '/auto/k1/mark/MyCode/mlPython/';
end
if ~exist('prefix','var')
    % probably don't mess with this
    prefix = 'x0x5F'; % Hex code added to json fields starting with "_"
end

dOpt.ParseLogical = true; % keep t/f as t/f instead of 1/0
dOpt.UnpackHex = true; % convert the 0x[hex code] output by loadjson 
                       % back to the string form
% Other customizable options from savejson!
% dOpt.Inf  = '"$1_Inf_"'; % Or other string! a customized regular
%           %expression pattern to represent +/-Inf. The matched pattern is
%           %'([-+]*)Inf' and $1 represents the sign. For those who want to
%           %use 1e999 to represent Inf, they can set Opts.Inf to '$11e999'
% dOpt.NaN  = '"_NaN_"'; % Or other string! a customized regular expression
%           %pattern to represent NaN

if ~exist('Opts','var')
    Opts = struct;
end
Opts = defaultOpt(Opts,dOpt);

% Get temporary file name
tmpF = fullfile(tmpDir,['tmpCouchQuery_' getUUID '.json']);
% Convert query fields to json object, write to temp file
%jStr = savejson('',qParams,tmpF);
savejson('',qParams,tmpF);

% Query database using python function
system(['python ' STRFpath 'mlabSTRFdb.py query ' tmpF ' ' STRFdb ' ' dbName]);

fid = fopen(tmpF,'r');
S = {};
count = 1;
while(1)
    % Load json file (saved over by mlabSTRFdb.py) line by line
    S{count} = fgetl(fid);
    if ~ischar(S{count}), S=S(1:end-1); break, end
    count = count+1;
end
fclose(fid); 
clear fid;
if length(S)>1
    % Concatenate multi-line json strings
    S = [S{:}];
else
    S = S{1};
end
Out = loadjson(S);
if isfield(Out,'Models')
    Out = Out.Models;
else
    Out = [];
end

function uuid = getUUID
[s,UUID] = system('uuidgen');
uuid = strrep(lower(UUID(1:end-1)),'-',''); % end-1 because the system adds a newline character
end

end