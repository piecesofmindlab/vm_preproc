function simDat = simulateResponse(Model,Stim,Opts,db)
% Usage: simDat = simulateResponse(Model,Stim,Opts,db)
% 
% Simulate the response to a stimulus with a particular fit model. 
% Inputs: 
%   Model : the fit he preprocessed
% stimulus is multiplied by the model weights to get predictions of
% activity for each epoch of the stimulus (in silico stimuli are
% essentially block design experiments as of 2012.06.25). The responses to
% each stimulus epoch are stored in "simDat" variable, and all options
% associated with the stimulus / models used are stored in a STRFdb as type
% "InSilicoSimulation"
% 
% Inputs:
%   Model : struct array from strfdb specifying saved fit model
%   Stim : PreprocessedStimulus object (not loaded) for preprocessed
%       stimulus for which you want to simulate responses. Stim should
%       match up with Model.Mod (at least in the number of parameters)
%   Opts : a struct that specifies 
%       .VoxSelect : a cell array of string ROI names, or a t/f vector
%         (the same size as the full 3D data) for which voxels to model
%       .TR : (necessary??)
%       .LagOpt : 'CollapseLagsMean'|'CollapseLagsMax'|'KeepLag<1-2-3>'|
%         'AddLags', whether to add lags to preprocessed stimulus or
%         somehow remove (or collapse across) lags from weights  
%   db : an mlabSTRFdb instance 
%
% ML 2012.06.15
% Updated by ML 2013.04.24


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ---                  Default options:                       --- %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('db','var')
    db = mlabSTRFdb;
end
% Simulation options
dOpts.TR = 2;
dOpts.VoxSelect = [];
dOpts.LagOpt = 'CollapseLagsMean'; %'AddLags'; 
dOpts.DataDir = '/auto/k8/mark/SimulatedResponseDB/';
dOpts.Overwrite = false;
dOpts.Session = 1;
dOpts.postProcSeq = [];
% Fill structs w/ defaults
if ~exist('Opts','var')
    Opts = struct;
end
Opts = defaultOpt(Opts,dOpts);
% Misc. startup stuff:
Opts.Type = 'InSilicoSimulation';
Opts.DateRun = datestr(now,'yyyy/mm/dd HH:MM'); %time.strftime('%Y/%M/%d %H:%M')
% Regression + Stim preproc for fit fMRI model
Opts.SubID = Model.SubID;
Opts.RegOpts = Model;
Opts.Mod = Model.Mod;
Opts.oStimulus = [Model.Mod.oStimulus];
% Stimulus + Stim preproc for simulation
Opts.sMod = Stim.dbStruct(true);
Opts.sStimulus = Stim.extra.oStimulus;

if isfield(Stim.extra.oStimulus,'sDim')
    Opts.sDim = Stim.extra.oStimulus.sDim;
end

nLags = length(Model.Lags);

% Check for existence of IDENTICAL model in database:
% *identical except for these fields, which we don't care about: 
Exclude = {'DataDir','DateRun','Overwrite'}; % do not match these items
qStr = Opts;
for iE = 1:length(Exclude);
    if isfield(qStr,Exclude{iE})
        qStr = rmfield(qStr,Exclude{iE});
    end
end
OldModels = db.query(qStr);
if isempty(OldModels)
    fprintf('New model created!\n')
    % Create new ID/path
    ID = db.getUUID;
    Opts.([db.prefix,'_id']) = ID;
    Opts.Path = fullfile(Opts.DataDir,[ID,'.mat']);
elseif length(OldModels)==1
    if ~Opts.Overwrite
        fprintf('\nModel response has already been simulated!\n\n')
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ---                      Load files                         --- %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mio = matfile(Model.Path);
modcc = mio.cc;
mask = mio.mask;
% (Optional) voxel selection 
if ~isempty(Opts.VoxSelect)
    if iscell(Opts.VoxSelect)
        % This should return a logical array EITHER the same size as "mask"
        % OR of size (sum(mask(:)),1)
        vSel = selectVoxels(Opts.VoxSelect{:});
        if all(size(vSel)==size(mask))
            vSel = vSel(mask);
        elseif all(size(vSel)==size(permute(mask,[3,2,1])))
            vSel = permute(vSel,[3,2,1]);
            vSel = vSel(mask);
        end
        if ~length(vSel)==sum(mask(:))
            error('Voxel selection not compatible with loaded mask from model!')
        end
    elseif ischar(Opts.VoxSelect)
        % an ID for a mask database object is provided; retrieve it!
        mskq.([db.prefix,'_id']) = Opts.VoxSelect;
        msk = db.query({1,mskq});
        msk = hf52struct(msk.path);
        vSel = msk.mask(mask)>0;
    elseif islogical(Opts.VoxSelect)||isnumeric(Opts.VoxSelect)
        error('No longer supported! don''t want huge masks in database!')
        %vSel = logical(Opts.VoxSelect(mask));
    end
else
    vSel = true(sum(mask(:)),1);
end
if ~islogical(vSel)
    vSel = vSel>0;
end
mask(mask) = vSel;
modcc = modcc(vSel);
fprintf('Loading model weights ...\n');
maxVarElements = 2^27; % max acceptable numel for memory constraints
%fI = whos('-file',Model.Path,'weights');
wSz = size(mio,'weights');
nVoxTot = sum(vSel);
nWtParts = ceil((wSz(1)-1)*nVoxTot/maxVarElements);
% remove 1st weight (this is the "cocktail mean" - DC predictor) and
% perform voxel selection 
w = mio.weights(2:wSz(1),:);
w = w(:,vSel);
% May have to load weights in groups, depending on how big the matrix is: 
if nWtParts > 1
    warning('Untested code follows!')
    fprintf('Splitting model weights into %d voxel groups...\n',nWtParts);
    chunkSz = ceil(nVoxTot/nWtParts);
    st = 1;
    for iWt = 1:nWtParts
        fin = min([nVoxTot st+chunkSz-1]);
        weights = w(:,st:fin);
        uuid = db.getUUID;
        wtName{iWt} = sprintf('DebugVars_TmpWts%d_%s_%s.mat',iWt,datestr(now,'mm_dd_HHMM'),uuid);
        save(wtName{iWt},'weights','-v7.3');
        st = st + chunkSz;
    end
    clear weights w
    UseWtChunks = true;
else
    UseWtChunks = false;
end

%%% Run through each part of stimulus matrix separately:
%%% *** NOTE! This is not optimal, in that there will be breaks in the
%%% stimulus matrix and thus gaps where temporal model properties (e.g.
%%% temporal frequency selectivity) are not computed correctly. But this is
%%% a minor problem as of 2012.06.15, because the only thing we will be
%%% computing is a mean across whole blocks of stimulation - which should
%%% negate any minor differences at the begining / end of a couple blocks.
simResp = [];
for iP = 1:Stim(1).nParts
    fprintf('\n--- Running stimulus part %d of %d... ---\n\n',iP,Stim(1).nParts);

    S = Stim(iP).load();
    Spreproc = S.S;
    clear S;
    % To make the dimensions of the response weight matrix and the
    % preprocessed stimulus matrix match up, we either have to get rid of
    % the lag predictors from the  weights (and the mean predictor??), or
    % we have to replicate the preprocessed stimulus so it matches the
    % shape of the weights (i.e., we have to put lags in it). 
    if strcmp(Opts.LagOpt,'AddLags')
        X = [];
        if any(Model.Lags)
            for iLag = Model.Lags
                xt = [zeros(iLag-1,size(Spreproc,2));Spreproc(1:end-iLag+1,:,iCW)];
                X = [X,xt];
            end
        else
            X = Spreproc;
        end
        Spreproc=X;
    end
    
    % Load weights, if not already loaded
    if UseWtChunks
        clear d w
        simRespTmp = [];
        for iW = 1:nWtParts
            d = load(wtName{iW});
            w = collapseWeights(d.weights,Opts.LagOpt,nLags);
            simRespTmp = [simRespTmp,Spreproc*w]; % calculate response per stim
        end
    else
        w = collapseWeights(w,Opts.LagOpt,nLags);
        simRespTmp=Spreproc*w; % calculate response per stim
    end
    % Concatenate simulated responses
    simResp = [simResp;simRespTmp];
end
simDat.simDat = simResp;
simDat.modcc = modcc;
simDat.mask = mask;
simDat.Opts = Opts;
% Post-processing! 
for iPP = 1:length(Opts.postProcSeq)
    ppStep = Opts.postProcSeq{iPP};
    ppParams = Opts.(ppStep);
    dTmp = feval(ppStep,simDat.simDat,ppParams);
    fn = fieldnames(dTmp);
    for iFN = 1:length(fn)
        simDat.(fn{iFN}) = dTmp.(fn{iFN});
    end
end

% Save in STRFdb
Status = dbSave(Opts,'http://meth:5984','strfdb-ml') %#ok<NOPRT,NASGU>
% Save .mat file
save(Opts.Path,'-struct','simDat','-v7.3');

function w = collapseWeights(w,LagOpt,nLags)
    ww = reshape(w,[],nLags,size(w,2));
    switch LagOpt
        case 'CollapseLagsMean'
            % Take the mean of all lags
            w = squeeze(nanmean(ww,2)); 
        case 'CollapseLagsMax'
            % Take the max of all 3 lags
            w = squeeze(nanmax(ww,2)); % Use MAX weight from the 3 delays...
        case {'KeepLag1','KeepLag2','KeepLag3'}
            lNum = eval(LagOpt(end));
            w = squeeze(ww(:,lNum,:));
        case 'AddLags'
            0; % do nothing
        otherwise 
            error('Unknown lag option!')
    end
end
end