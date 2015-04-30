function mlSTRF_FitModel_Noise(dataSet,mask,WhichModel,OptsIn,is_slurm)
% Usage: mlSTRF_FitModel_Noise(dataSet,mask,WhichModel,Opts,is_slurm)
%
% Generalized model fitting code. Relies on STRFlab conventions. Fits (n)
% versions of model, with progressively more noise regressors added 
% 
% Inputs: 
%   SubID = string subject id (usually initials, e.g. 'ML')
%   dataSet = query struct to retrieve dataSet (struct) from database using
%       function mlLoadData.m
%   WhichModel = string identifier for model, e.g. 'HoG_128px_Color_02_03'
%   Opts = struct array of regression options, with fields: 
%         .NoisePreds = []; % Noise predictors (e.g., 'RETROICOR_01',
%               'VoxelPCs', etc.) 
%         .ValDat = 'unwrapped'; % 'unwrapped' [default] or 'mean': how to
%               predict validation data
%         .Lags = [2,3,4]; %TRs after stimulus onset
%         .ChunkSz = 5000;
%         .DataDir = '/auto/k6/mark/BVPpilot3_FitModels/';
%         .VoxMask = 'cortex';
%         .Path = []; % string path to file. 
%
% 201X ML
% Updated 2013.08 ML

% ADD PATHS
% If you're not Mark, you'll need these paths:
% addpath(genpath('/auto/k1/mark/MyCode/mlMatlab/'));
% rmpath(genpath('/auto/k1/mark/MyCode/mlMatlab/Experiment_Code/'))

% Inputs
if ~exist('is_slurm','var')
    is_slurm = true;
end
% Misc. params: 
couchServer = 'http://meth:5984';
dbName = 'strfdb-ml';
dbi = mlabSTRFdb(couchServer,dbName);

% INPUTS
if ~exist('OptsIn','var')
    OptsIn = struct;
end

% Specific to this function:
Opts.sparse_exponent = 1; % default = simply noise, not sparse noise
Opts.noise_size = [0,-1,20]; % min, max, n samples; a negative value for max implies to use the size of the model
% Default options:
Opts.ValDat = 'mean'; % 
Opts.collapseVal = []; % 
Opts.Lags = [2,3,4]; %TRs after stimulus onset
Opts.ChunkSz = 5000;
Opts.DataDir = '/auto/k8/mark/fMRIDB/';
Opts.VoxMask = mask.name; %'backhalfcortex';
Opts.Reg = 'RidgeCV';
Opts.ValSeq = []; % order sequence for repeated blocks of validation data
Opts.ValBlockSz = []; % Size (in TRs) for repeaeted blocks of validation data
Opts.Type = 'fMRI_FitModel_wNoise';
Opts.Overwrite = false;
Opts.SaveWeights = false;
Opts.PredMetrics = {'cc','ccCI'}; %,'ccCI','ccFull','valPred'};
% Update Opts struct with input
Opts = defaultOpt(OptsIn,Opts);
Opts.DateRun = 'incomplete'; % for temporary file; changed below once final version is saved
% Add argument fields from other inputs
warning('Hacky bullshit! Figure out what to do with potentially different trn/val sessions!')
if isfield(dataSet,'trn')
    dstmp = dataSet.trn;
else
    dstmp = dataSet;
end
Opts.Session = dstmp.Session;
Opts.SubID = dstmp.SubID;
Opts.Task = dstmp.Task; % Subject task 
Opts.Exp = dstmp.Exp;
Opts.Detrend = dstmp.Detrend; %'Median'; % default to basic median detrending
Opts.xfm = mask.xfm;
% SERIOUSLY UGLY BULLSHIT.
is_trn_only = ~isempty(strfind(Opts.Reg,'_trnOnly')); % or: only {'trn'} in trnval
idf = [dbi.prefix,'_id'];
if isfield(dataSet,'trn')
    if ~isfield(dataSet.trn,[dbi.prefix,'_id'])
        tmp = dbi.query({1,dataSet.trn});
    else
        tmp = dataSet.trn;
    end
    Opts.trn_id = tmp.(idf);
end
if isfield(dataSet,'val') && ~is_trn_only
    if ~isfield(dataSet.trn,[dbi.prefix,'_id'])
        tmp = dbi.query({1,dataSet.val});
    else
        tmp = dataSet.val;
    end
    Opts.val_id = tmp.(idf);
end
if ~isfield(dataSet,'trn') && iscell(dataSet.trnval)
    for iTV = 1:length(dataSet.trnval)
        tmpq = dataSet;
        tv = dataSet.trnval{iTV};
        % More hacky bullshit
        if ismember(tv,{'val','val_Full'}) && is_trn_only
            continue
        end
        tmpq.trnval = tv;
        tmp = dbi.query({1,tmpq});
        Opts.([strrep(tv,'_Full','') '_id']) = tmp.(idf);
    end
end

% Last check that we have IDs incorporated
if ~isfield(Opts,'val_id') && ~is_trn_only
    error('No validation data ID found!')
end
if ~isfield(Opts,'trn_id')
    error('No training data ID found!')
end
%/SERIOUSLY UGLY BULLSHIT

% Later we will set this: Opts.Mod = WhichModel; % convention is to use TRAINING model

if size(Opts.ValSeq,1)>size(Opts.ValSeq,2)
    % Should be a horizontal vector (for consistency in database)
    Opts.ValSeq = Opts.ValSeq';
end

% Get model from database
[qStim,qMod] = WhichModel{:};
fprintf('\n\n--- Loading stimulus model! ---\n\n')
[S,M] = dbGetModels(qStim,qMod,{'trn','val'},dbi);
Opts.Mod = M.trn;

% Check for existence of IDENTICAL model in database:
% *identical except for these fields, which we don't care about: 
Exclude = {'DataDir','ChunkSz','AxLabel','Descr','DateRun','Overwrite'}; % do not match these items
qStr = Opts;
for iE = 1:length(Exclude);
    if isfield(qStr,Exclude{iE})
        qStr = rmfield(qStr,Exclude{iE});
    end
end
fprintf('\n\n--- Checking for existence of fit model! ---\n\n')
OldModels = dbi.query(qStr);
if isempty(OldModels)
    % Create new ID/path
    ID = dbi.getUUID;
    Opts.([dbi.prefix,'_id']) = ID;
    Opts.Path = fullfile(Opts.DataDir,[ID,'.mat']);
elseif length(OldModels)==1
    if ~Opts.Overwrite
        % Check for incomplete run
        if strcmp(OldModels.DateRun,'incomplete')
            Opts = OldModels;
            disp('Finishing incomplete run...')
        else
            fprintf('\nModel has already been run!\n\n')
            return
        end
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

% Save temp files in related file
data_model_path = strrep(Opts.Path,'.mat','_TEMPdata.mat');
if ~exist(data_model_path,'file')


    % Get training / validation responses 
    % TO DO: Change to db-based system!
    if strcmp(dataSet,'FakeData')
        [FD,Wts] = FakeData(dataSet);
        trnResp0 = FD.trn;
        valResp0 = FD.val;
    else
        fprintf('\n\n--- Loading fMRI Data! ---\n\n')
        data = mlLoadData(dataSet,mask,dbi,'single');
    end

    % Build design matrix from model
    % (1) Add lags
    if any(Opts.Lags)
        X = addLags(S.trn,Opts.Lags);
        Xval = addLags(S.val,Opts.Lags);
    else
        X = S.trn;
        Xval = S.val;
    end
    % (2) Add nuisance/noise regressors, one by one
    Opts.nNuisancePreds = 0;
    for iP = 1:length(Opts.NoisePreds)
        % TO DO (maybe): add lags to nuisance preds? 
        % TO DO (For sure): Load as we load other models, from db, as / from
        % PreprocessedStimulus class
        %fin = regexp(dataSet,'_Ses','start')-1;
        %if isempty(fin)
        %    error('What session, bozo?')
        %end
        %ds = dataSet(1:fin);
        %ses = dataSet(fin+1:end);
        tmp = load(['/auto/k6/mark/' dataSet '_ModelParams/' Opts.NoisePreds{iP} '_Trn.mat']);
        X = [X,tmp.Spreproc];
        nNP = size(tmp.Spreproc,2);
        %tmp = load(['/auto/k6/mark/' dataSet '_ModelParams/' Opts.NoisePreds{iP} '_Val.mat']);
        % RespOrd??
        %nValRpt = length(Opts.ValSeq)/length(unique(Opts.ValSeq));
        %if size(tmp.Spreproc,1)==nValRpt*size(Xval,1)
        %    % Unwrap data if required
        %    Xval = unwrapValData(Xval,Opts.ValSeq,Opts.ValBlockSz);
        %end
        %
        %Xval = [Xval,tmp.Spreproc];
        %if size(tmp.Spreproc,2)==nNP % check that trn/val have same number of preds
        %    % Track number of nuisance regressors so we can get rid of them later  
        Opts.nNuisancePreds = Opts.nNuisancePreds + nNP; 
        %else
        %    error(sprintf('Number of nuisance variables for training and validation data is not the same! (%s)',Opts.NoisePreds{iP}));
        %end
    end
    % (3) Add ones as FIRST column 
    X = [ones(size(X,1),1),X];
    Xval = [ones(size(Xval,1),1),Xval];

    % For intelligibility of code:
    nVoxels = size(data.trn,2);
    [nSamples,nParams] = size(X);

    % (4) Prepare NOISE REGRESSORS to add:
    mn_n = Opts.noise_size(1);
    mx_n = Opts.noise_size(2);
    n_n = Opts.noise_size(3);
    if mx_n < 0
        % Negative values for second noise_size element mean scale noise up to
        % abs(mx_n) times the size of the model
        mx_n = nParams*abs(mx_n);
    end
    % General to all regression methods??

    % Create maximum possible noise size, save in v7.3 file
    NoiseT = randn(nSamples,mx_n);
    NoiseV = randn(size(Xval,1),mx_n);
    if Opts.sparse_exponent~=1
        NoiseT = sparsify(NoiseT,Opts.sparse_exponent);
        NoiseV = sparsify(NoiseV,Opts.sparse_exponent);
    end
    % Model
    model.trn = [X,NoiseT];
    model.val = [Xval,NoiseV];
    % Options
    if ~isempty(Opts.collapseVal)
        if Opts.collapseVal.unwrapModel
            % Unwrap data if required
            model.val = unwrapValData(model.val,Opts.ValSeq,Opts.ValBlockSz);
        end
        % Mild legacy stuff here: Opts.ValSeq & Opts.ValBlockSz were
        % originally separate parameters, "collapseVal" was added later
        params.collapseVal = Opts.collapseVal;
        params.collapseVal.seq = Opts.ValSeq;
        params.collapseVal.blockSz = Opts.ValBlockSz;
    end
    params.chunkSz = Opts.ChunkSz;
    params.predMetrics = Opts.PredMetrics; %'valPredFull'
    % Save model and data, save temporary placeholder in database
    status = dbSave(Opts,couchServer,dbName); % in database
    mio = matfile(data_model_path,'writable',true);
    % For fitting
    mio.model = model;
    mio.data = data;
    mio.params = params;
    mio.nParams = nParams;
    mio.nSamples = nSamples;
    mio.nVoxels = nVoxels;
else
    mio = matfile(data_model_path,'writable',false);
    nParams = mio.nParams;
    model = data_model_path;
    data = data_model_path;
    params = data_model_path;
    % Prepare NOISE REGRESSORS to add:
    mn_n = Opts.noise_size(1);
    mx_n = Opts.noise_size(2);
    n_n = Opts.noise_size(3);
    if mx_n < 0
        % Negative values for second noise_size element mean scale noise up to
        % abs(mx_n) times the size of the model
        mx_n = nParams*abs(mx_n);
    end
    
end

noise_size = round(linspace(mn_n,mx_n,n_n));
n_noise = length(noise_size);

% Regress @ each added-noise level!
switch Opts.Reg % choose regression function to use
    case 'OLS'
        error('Need to update with predMetrics field / addition of noise regressors; SHIT IS BROKEN !')
        % Run loop 
        
    case 'RidgeCV'
        % Cache full matrix of stim / data for each repeat
        job_ids = zeros(n_noise,1)*nan;
        dbp = {couchServer,dbName};
        for ii = 1:n_noise
            % Define docdict unique to this section
            ID = Opts.([dbi.prefix,'_id']);
            path_base = strrep(Opts.Path,'.mat','');
            docdict = struct('Type','fMRI_FitModel_wNoise_TEMP','parent_id',ID,[dbi.prefix '_id'],sprintf('%s_%09d',ID,ii),...
                'part',ii,'nParts',n_noise,'path',sprintf('%s_%09d.mat',path_base,ii),...
                'SaveWeights',Opts.SaveWeights,'noise_size',noise_size,'model_size',nParams);
            % Regression
            if is_slurm
                % Slurm
                jp = struct('cpus',2,'partition','all','memory',15450,'out',...
                    ['/auto/k1/mark/SlurmLog/ridge_scatter_%j_' datestr(now,'mm_dd_HHMM') '.out']);
                tmpF = strrep(docdict.path,'.mat','fuckypoodeleteme.mat');
                save(tmpF,'docdict','dbp');
                job_ids(ii) = mlSlurm('scatter_ridge_noise',tmpF,jp,data_model_path,data_model_path,data_model_path,'$dbp','$docdict');
            else
                %No slurm
                scatter_ridge_noise(data,model,params,dbp,docdict);
            end
        end
    case 'RidgeCV_trnOnly'
        error('NOT YET FINISHED. USE RIDGECV TRN ONLY FOR NOW.')
        % Model
        model.trn = X;
        model.val = Xval;
        % Options
        params.chunkSz = Opts.ChunkSz;
        % Too many cv splits! Too much computation time! => switched to 3,5
        % on 2012.07.16
        params.nResamps = 3; % number of times to run cross-validation for lambdas
        params.nPartitions = 5; % determines size of train/validate chunks for Cross-validation. 10 = 90% train / 10% val
        %params.Efficient = false; % Use eig rather than SVD for big models.
        % Fewer cv splits for overall accuracy:
        pp.PP = params;
        pp.nResamps = 3;
        pp.nPartitions = 5;
        % Regression
        Result = ridgeCV_trnOnly(data,model,pp);
        fn = fieldnames(Result);
        for iFn = 1:length(fn);
            eval([fn{iFn} ' = Result.' fn{iFn} ';']);
        end
        VarsToSave = {'cc','ccCI','mask','sigThresh','nSigVox_byLambda','Opts'};
end

VarsToSave = [Opts.PredMetrics,{'mask','sigThresh','nSigVox_byLambda'}];
% Run slurm job to gather all responses
if is_slurm
    jp = struct('cpus',2,'partition','all','memory',15450,'out',...
                    ['/auto/k1/mark/SlurmLog/ridge_gather_%j_' datestr(now,'mm_dd_HHMM') '.out'],...
                    'depends', [sprintf('%d:',job_ids(1:end-1)),num2str(job_ids(end))]);
    tmpF = strrep(Opts.Path,'.mat','fuckypoodeleteme.mat');
    save(tmpF,'Opts','dbp','VarsToSave');
    mlSlurm('gather_ridge_noise',tmpF,jp,'$dbp','$Opts','$VarsToSave');
else
    gather_ridge_noise(dbp,Opts,VarsToSave);
end
% gather_ridge_noise does cleanup of .mat files / temporary database
% headers. So we're done!
fprintf(' --- All done! --- \n\n')