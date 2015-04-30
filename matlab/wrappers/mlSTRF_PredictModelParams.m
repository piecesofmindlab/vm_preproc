function mlSTRF_PredictModelParams(modelX,modelY,OptsIn)
% Usage: mlSTRF_PredictModelParams(modelX,modelY,Opts)
% 
% Code to test whether parameters for one model (modelY) can be predicted
% by a weighted sum of parameters from another model (modelX). 
% 
% Inputs:
%   modelX = cell array with {qStim,qMod} for independent model (X). 
%       qStim,qMod are identifiers for stimulus set / model ppSeq, etc) -
%       see dbGetModels for help.
%   modelY = same for y model (model to be predicted)
%   Opts = struct array of options, with fields: 
%       .
%
% Created by ML 2011.08
% Revised by ML 2012.05.30

% ADD PATHS
% If you're not Mark, you'll need these paths:
% addpath(genpath('/auto/k1/mark/MyCode/mlMatlab/'));
% rmpath(genpath('/auto/k1/mark/MyCode/mlMatlab/Experiment_Code/'))

% Misc. params: 
dbServer = 'http://meth:5984';
dbName = 'strfdb-ml';
db = mlabSTRFdb(dbServer,dbName);
% INPUTS

% Default options:
Opts.Type = 'ModelToModelPrediction';
Opts.DateRun = datestr(now,'yyyy/mm/dd HH:MM'); %time.strftime('%Y/%M/%d %H:%M')
Opts.ChunkSz = 10000;
Opts.DataDir = '/auto/k6/mark/BVPpilot3_FitModels/';
Opts.Reg = 'RidgeCV';
Opts.Exp = [];
% Update Opts struct with input
if ~exist('OptsIn','var')
    OptsIn = struct;
end
Opts = defaultOpt(OptsIn,Opts);

% Get model from database!
[qStim,qMod] = modelX{:};
[Sx,Mx] = dbGetModels(qStim,qMod,{'trn','val'},db);

[qStim,qMod] = modelY{:};
[Sy,My] = dbGetModels(qStim,qMod,{'trn','val'},db);

Opts.Mod = Mx.trn{1};
Opts.ModelY = My.trn{1};

% Check for existence of IDENTICAL model in database:
% *identical except for these fields, which we don't care about: 
Exclude = {'DataDir','ChunkSz','AxLabel','Descr','DateRun','Overwrite'}; % do not match these items
qStr = Opts;
for iE = 1:length(Exclude);
    if isfield(qStr,Exclude{iE})
        qStr = rmfield(qStr,Exclude{iE});
    end
end
OldModels = db.query(qStr);
if isempty(OldModels)
    % Create new ID/path
    ID = db.getUUID;
    Opts.([db.prefix,'_id']) = ID;
    Opts.Path = fullfile(Opts.DataDir,[ID,'.mat']);
elseif length(OldModels)==1
    if ~Opts.Overwrite
        fprintf('\nModel has already been run!\n\n')
        return    
    else
        fprintf('Replacing file %s\n',OldModels.Path);
        for iE = 1:length(Exclude)
            if isfield(Opts,Exclude{iE})
                OldModels.(Exclude{iE}) = Opts.(Exclude{iE});
            end
        end
        Opts = OldModels;
    end
elseif length(OldModels)>1
    error('Multiple models match this model''s parameters!')
end

% Check that path is correct
[pChk,fNm,ext] = fileparts(Opts.Path);
if ~strcmp(pChk,Opts.DataDir)
    Opts.Path = fullfile(Opts.DataDir,[fNm ext]);
end

% Get significance threshold for corr. coef. based on T-dist and validation
% sample degrees of freedom
sigThresh = pval2r(.005,size(Sx.val,1));

% For intelligibility of code:
% nParamsPredicted = size(Sy.trn,2);
% nParams = size(Sx.trn,2);
% nSamples = size(Sx.trn,1);

% Regress!
switch Opts.Reg % choose regression function to use
    case 'OLS'
        % Model
        params.ChunkSz = Opts.ChunkSz;
        % Regression
        Result = ols(Sy,Sx,params);
        fn = fieldnames(Result);
        for iFn = 1:length(fn);
            eval([fn{iFn} ' = Result.' fn{iFn} ';']);
        end
        VarsToSave = {'weights','valPred','cc','ccCI','sigThresh','Opts'};
    case 'RidgeCV'
        % Model
        params.chunkSz = Opts.ChunkSz;        
        % Regression
        Result = ridgeCV(Sy,Sx,params);
        fn = fieldnames(Result);
        for iFn = 1:length(fn);
            eval([fn{iFn} ' = Result.' fn{iFn} ';']);
        end
        VarsToSave = {'cc','ccCI','weights','valPred','sigThresh','nSigVox_byLambda','Opts'};
end
%clear trnResp_RS valResp_RS Wt Ychunk

% Create db entry:
status = dbSave(Opts,dbServer,dbName); % in database
% Check if entered in db correctly:
display(status)
% Save Results
save(Opts.Path,VarsToSave{:},'-v7.3') % v7.3 for large matrices. 

fprintf(' --- All done! --- \n\n')


