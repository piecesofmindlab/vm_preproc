function scatter_ridge_noise(data,model,params,dbp,docdict,is_overwrite)
% Usage: scatter_ridge_noise(data,model,params,dbp,docdict,is_overwrite)
% 
% Scatter function for running multiple ridge regressions at once. Loads
% variable w/ path specified in docdict, saves same file once finished. 
%
% THIS IS SPECIFIC TO mlSTRF_FitModel_Noise.m; docdict must have two
% specific fields, "part" and "noise_size". This loads:
% 
% model.trn(:,1:noise_size(part));
% model.val(:,1:noise_size(part));
% 
% Inputs: 
%   data : data struct or file name w/ variable named "data" in it that
%       contains a data struct. data struct should have .trn and .val
%       fields in it.
%   model: model struct or file name w/ variable named "model" in it that
%       contains a model struct. model struct should have .trn and .val
%       fields in it. 
%   params : params struct or file name... blah blah blah. Params are input
%       to ridgeCV. 
%   dbp : database query parameters, for creation of mlabSTRFdb object
%       Creates query item to search database.
%   docdict : dictionary to use to save results to database. 
%       Should specify noise_size, part, nParts, parent (ID of object that
%       will be permanently saved), path, ID (derivative of parent's ID and
%       part number), SaveWeights (T/F)
% ML 2014.08

% Inputs
if ~exist('is_overwrite','var')
    is_overwrite = false;
end
% Get database interface
dbi = mlabSTRFdb(dbp{:});
% Check for existence of this analysis
prev_model = dbi.query(docdict);
if ~isempty(prev_model) && ~is_overwrite
    % contains ID; guaranteed to be match
    fprintf('Found model! Aborting!\n')
    disp(prev_model)
    return
end
% Load variables if necessary
if ischar(data)
    dataf = matfile(data,'Writable',false);
    data = dataf.data;
end
clipsz = docdict.model_size+docdict.noise_size(docdict.part);
if ischar(model)
    modelf = matfile(model,'Writable',false);
    mtmp = modelf.model;
    model = struct; % replace string
    model.trn = mtmp.trn(:,1:clipsz);
    model.val = mtmp.val(:,1:clipsz);
else
    model.trn = model.trn(:,1:clipsz);
    model.val = model.val(:,1:clipsz);
end
if ischar(params)
    paramsf = matfile(params,'Writable',false);
    params = paramsf.params;
end
%TEMP
if docdict.part==2
    keyboard
end
% Run regression
Result = ridgeCV(data,model,params); %#ok<NASGU>
VarsToSave = [params.predMetrics,{'mask','sigThresh','nSigVox_byLambda'}];
if docdict.SaveWeights
    VarsToSave = [VarsToSave,'weights'];
end
% Save header to database
Status = dbSave(docdict,dbp{:});
display(Status)
% Save temp file to database
save(docdict.path,'-struct','Result',VarsToSave{:},'-v7.3') % v7.3 for large matrices. 
disp('--- All done! ---')