function varargout = dbSave(ModStruct,STRFdb,dbName)
% Usage: Status = dbSave(ModStruct,STRFdb,dbName)
% 
% Saves a struct array as a json object to a couchdb database. Intended for
% use with STRFdb models, but this should be general enough to use for any
% couch database.
% 
% Relies on a slightly modified couch4mat* library, that uses jsonlab**
% instead of json4mat***. 
% 
% * http://code.google.com/p/couch4mat/
% ** http://www.mathworks.com/matlabcentral/fileexchange/33381
% *** http://www.mathworks.com/matlabcentral/fileexchange/27169-json4mat
% 
% Inputs: 
%   ModStruct = struct to insert into db. Should have a ".id" field, and a
%       ".rev" field if this is an update to an existing db entry. 
%   STRFdb = database location (by default, GLab db: 'http://meth:5984')
%   dbName = database name (by default, 'strfdb-ml');
%   
% See also dbCheck.m
%
% NOTE! All conversions from matlab struct array to json object run the
% risk of screwed-up field or file names, or other imperfect conversions.
% Preliminary tests find this to be minor, but you should always check up
% on stuff to make sure you're not storing data in inaccurate /
% unpredictable ways!
% 
% Note 2: I added code to couch.m to make sure the _id and _rev fields are
% correctly re-set to "_id" and "_rev" after (necessarily) being changed by
% loadjson (to "x_id" and "x_rev"). 
% 
% ML 2012.05.25

if ~exist('STRFdb','var')||isempty(STRFdb)
    STRFdb = 'http://meth:5984';
end
if ~exist('dbName','var')||isempty(dbName)
    dbName = 'strfdb-ml';
end

c = couch(STRFdb,'db',dbName);
status = couch(c,'insert doc',ModStruct);

if nargout
    varargout{1} = status;
end