function gather_ridge_noise(dbp,docdict,to_concat)
% Usage: scatter_ridge_noise(dbp,docdict)
% 
% Gather function for running multiple ridge regressions at once. docdict
% specifies the parent function of all other 
%
% Do NOT run until other jobs have finished (either by running sequentially
% after scatter functions all finish, or by waiting for previous cluster
% jobs to finish).
%
% THIS IS SPECIFIC TO mlSTRF_FitModel_Noise.m 
% docdict must have field noise_size; this will use the last element of
% noise_size to determine how many other docdb files to concatenate.
% 
% Inputs: 
%   dbp : database query parameters, for creation of mlabSTRFdb database
%       query object to search database.
%   docdict : dictionary to use to save results to database. 
%       Should specify at least fields noise_size and ID
%   to_concat : list of variables to concatenate along last dimension
% 
% ML 2014.08

% Get database interface
dbi = mlabSTRFdb(dbp{:});
% Check for existence of this analysis
Exclude = {'DataDir','ChunkSz','AxLabel','Descr','DateRun','Overwrite'}; % do not match these items; we don't care.
qStr = docdict;
for iE = 1:length(Exclude);
    if isfield(qStr,Exclude{iE})
        qStr = rmfield(qStr,Exclude{iE});
    end
end
mod = dbi.query(qStr);

if isempty(mod)
    error('No parent object found in database! nothing to concatenate!')
    return
end
% Establish writable matfile object for final concatenated variables
if exist(mod.Path,'file')
    disp('DELETING OLDER FILE')
    delete(mod.Path);
end
mio = matfile(mod.Path,'Writable',true);
n = mod.noise_size(end);
idf = [dbi.prefix '_id'];
all_idx = cell(length(to_concat),1);
for iPart = 1:n
    pt = dbi.query(idf,sprintf('%s_%09d',mod.(idf),iPart));
    tmpio = matfile(pt.path); %lower case p?
    for v = 1:length(to_concat)
        f = to_concat{v};
        if strcmp(f,'mask')
            % special case; no need to duplicate...
            if iPart==1
                mio.mask = tmpio.mask;
            end
            continue
        end
        if iPart==1
            % for first part, establish sizes of variables
            %fprintf('Pre-allocating %s\n',f);
            cls = class(tmpio.(f));
            all_idx{v} = repmat({':'},1,length(size(tmpio,f)));
            mio.(f) = zeros([size(tmpio,f),n],cls);
            %disp(size(mio,f));
        end
        % Stupid nan check
        keep = tmpio.(f);
        keep(isnan(keep)) = 0;
        mio.(f)(all_idx{v}{:},iPart) = keep;
    end
end
% Save header to database
docdict.DateRun = datestr(now,'yyyy/mm/dd HH:MM'); %time.strftime('%Y/%M/%d %H:%M')
Status = dbSave(docdict,dbp{:});
display(Status)
% Clean up multiple parts
q = struct('parent_id',mod.(idf));
dbi.delete(q,true);
% Clean up temp file w/ data, mask
tempfile_path = strrep(docdict.Path,'.mat','_TEMPdata.mat');
delete(tempfile_path);
% Fin
disp('--- All done! ---')