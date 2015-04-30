function preprocInSilicoStim(SubID,Model,Stim,Exp,Task,OptsIn)
% Usage: preprocInSilicoStim(SubID,Model,Stim [,Exp][,Task][,Opts])
% 
% Preprocess a stimulus (saved in stimF) with a particular model (specified
% in "Model" and potentially other options in "Opts"). The preprocessed
% stimulus is multiplied by the model weights to get predictions of
% activity for each epoch of the stimulus (in silico stimuli are
% essentially block design experiments as of 2012.06.25). The responses to
% each stimulus epoch are stored in "simDat" variable, and all options
% associated with the stimulus / models used are stored in a STRFdb as type
% "InSilicoSimulation"
% 
% Inputs:
%   SubID = string subject ID
%   Model = string model name 
%   Stim = struct array for stimulus identification; used to query STRFdb
%   Exp = string exp name (default = 'BVPpilot3_Ses1' [or current experiment for ML])
%     ** NOTE that the default is subject to change!! **
%   Task = string task for exp (default = 'ObjCount' or 'Scene1back');
%   OptsIn is a struct that specifies 
%       .VoxSelect can be a cell array of string ROI names, or a t/f vector
%       (the same size as the full 3D data) for which voxels to model)
%       [[See code for other [all optional] fields in Opt struct!]]
% 
% NOTE: There are a number of special-case snippets below for Gabor wavelet
% preprocessing, since it does not work exactly the same way as the other
% (mostly HoG) functions, particularly with regard to saving intermediate
% files. This is not great for intelligibility / bug risk - change / update
% Gabor code??  
% 
% ML 2012.06.15

if ~exist('Exp','var')||isempty(Exp)
    Exp = 'BVPpilot3_Ses1';
end
if ~exist('Task','var')||isempty(Task)
    Task = 'ObjCount';
end
if ~exist('OptsIn','var')
    OptsIn = struct;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ---                  Default options:                       --- %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Inputs:
Opt.SubID = SubID;
Opt.Exp = Exp; %'BVPpilot3_Ses1';
Opt.TR = 2;
Opt.Task = Task;
Opt.Stim = Stim;
Opt.Mod = Model; %'Gabor_128px_02_Ses1'; %'HoG_128px_ObNormals_02_03_Ses1';% 'HoG_128px_Color_02_03_Ses1'; % 
Opt.VoxSelect = [];
% Simulation options
Opt.Type = 'InSilicoSimulation';
Opt.LagOpt = 'RemoveLags'; %'AddLags'; % whether to add lags to preprocessed stimulus or remove lags from weights
Opt.DateRun = datestr(now,'yyyy/mm/dd HH:MM'); %time.strftime('%Y/%M/%d %H:%M')
StimDef.Type = 'InSilicoStimulus';

% Fill structs w/ defaults
Opt = mlFillStruct(OptsIn,Opt,true);
Stim = mlFillStruct(Stim,StimDef,true);
% Misc. startup stuff:
if any(strfind(Model,'Gabor')) && ~isfield(Opt,'preprocFn')
    Opt.preprocFn = 'preproc_downsample'; % 
    IsGabor = true;
elseif any(strfind(Model,'HoG')) && ~isfield(Opt,'preprocFn')
    Opt.preprocFn = 'preprocHoG'; % 
    IsGabor = false;
else
    error('unknown model! need to specify Opt.preprocFn!');
end
% File directories and names 
stIdx = regexp(Opt.Exp,'_Ses','start');
WhichExpShort = Opt.Exp(1:stIdx-1);
fMRIDir= ['/auto/k6/mark/' WhichExpShort '_fMRI/'];
modDir = ['/auto/k6/mark/' WhichExpShort '_ModelParams/'];
ROIF = [fMRIDir 'Sub' Opt.SubID '_' WhichExpShort '_roiVox2.mat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ---     Get model and stimulus from STRFdb database         --- %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% --- First: get model weights for this subject --- %%%
% Regression options:
if ~isfield(Opt,'ModelID')
    % Go with defaults
    ModStruct.ValDat = 'unwrapped';
    ModStruct.Reg = 'RidgeCV';
    %ModStruct.NoisePreds = [];
    ModStruct.SubID = Opt.SubID;
    ModStruct.Mod = Opt.Mod;
    ModStruct.Exp = Opt.Exp;
    ModStruct.Task = Opt.Task;
else
    ModStruct.x_id = Opt.ModelID;
end
[~,IsNew,ModStruct] = dbCheck(ModStruct);
if IsNew
    error('Could not find model!')
elseif length(ModStruct)>1
    error('More than one model found!')
end
ModStruct = ModStruct{1};
Opt.ModelID = ModStruct.x_id;
%%% --- Second: get stimulus from database --- %%%
[~,IsNew,StimStructs] = dbCheck(Stim,[],[],[],{'ModelType','ModelType'});
if IsNew
    error('Stimulus not found!')
end
if length(StimStructs)~=StimStructs{1}.nParts
    error('Multiple possible stimuli found in db! please make your search for stim more specific!')
end
% This is stupid, but functional:
for ii = 1:StimStructs{1}.nParts; 
    pNum(ii) = [StimStructs{ii}.Part]; 
end
Opt.Stim = StimStructs{pNum==1};
Opt.StimID = Opt.Stim.x_id;
Opt.WhichStim = Opt.Stim.StimClass;
Opt.sDim = Opt.Stim.sDim;
%%% --- Last: Check database for identical simulation, get db ID for model  --- %%%
[Opt,IsNew,OptOld] = dbCheck(Opt,'http://meth:5984','strfdb-ml',{'ModelType','ModelType'});
if length(OptOld)>1
    error('multiple possible models in the database coincide with the parameters you have supplied! Gaaa!')
end
if IsNew
    Opt.Path = fullfile(modDir,Opt.Path);
end

nDim = length(Opt.sDim);
sDim = num2cell(Opt.sDim);
sDimIdx = repmat({':'},1,nDim); 
sDimIdx2 = num2cell(ones(1,nDim));
sDimIdx2{end+1} = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ---                      Load files                         --- %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


d = load(ModStruct.Path,'mask','cc');
modcc = d.cc;
mask = d.mask;
% (Optional) voxel selection 
if ~isempty(Opt.VoxSelect)
    if iscell(Opt.VoxSelect)
        ROInm = Opt.LimitToROIs; % for now...
        m = load(ROIF); % ROIF
        vSel = ismember(abs(m.roiMask),find(ismember(m.roiNames,ROInm)));
        vSel = vSel(d.mask);
    elseif islogical(Opt.VoxSelect)||isnumeric(Opt.VoxSelect)
        vSel = Opt.VoxSelect(d.mask);
    end
else
    vSel = true(sum(d.mask(:)),1);
end
fprintf('Loading model weights ...\n');
maxVarElements = 2^27; % max acceptable numel for memory constraints
fI = whos('-file',ModStruct.Path,'weights');
nVoxTot = sum(vSel);
nWtParts = ceil((fI.size(1)-1)*nVoxTot/maxVarElements);
d = load(ModStruct.Path,'weights');
% remove 1st weight (this is the "cocktail mean" - DC predictor) and
% perform voxel selection 
d.weights = d.weights(2:end,vSel);
% May have to load weights in groups, depending on how big the matrix is: 
if nWtParts > 1
    fprintf('Splitting model weights into %d voxel groups...\n',nWtParts);
    chunkSz = ceil(nVoxTot/nWtParts);
    st = 1;
    for iWt = 1:nWtParts
        fin = min([nVoxTot st+chunkSz-1]);
        weights = d.weights(:,st:fin);
        [~,UUID] = system('uuidgen');
        uuid = strrep(lower(UUID(1:end-1)),'-',''); % end-1 because the system adds a newline character
        wtName{iWt} = sprintf('DebugVars_TmpWts%d_%s_%s.mat',iWt,datestr(now,'mm_dd_HHMM'),uuid);
        save(wtName{iWt},'weights','-v7.3');
        st = st + chunkSz;
    end
    clear weights 
    UseWtChunks = true;
end
    
fprintf('Loading preprocessing parameters ...\n');
p = load(fullfile(modDir,[Opt.Mod '_Val.mat']),'params');
params = p.params;
% Special instructions for Gabor preprocessing:
if IsGabor
    params = rmfield(params,{'means','stds'});
    expinfo.TRsec = Opt.TR;
    expinfo.imhz = StimStructs{1}.sHz;
    StimParams.downsampleparams.class = 'box'; 
    ppArg = {StimParams,expinfo};
else
    ppArg = {};
end

%%% Run through each part of stimulus matrix separately:
%%% *** NOTE! This is not optimal, in that there will be breaks in the
%%% stimulus matrix and thus gaps where temporal model properties (e.g.
%%% temporal frequency selectivity) are not computed correctly. But this is
%%% a minor problem as of 2012.06.15, because the only thing we will be
%%% computing is a mean across whole blocks of stimulation - which should
%%% negate any minor differences at the begining / end of a couple blocks.
simResp = [];
for iP = 1:StimStructs{1}.nParts
    fprintf('\n--- Running stimulus part %d of %d... ---\n\n',iP,StimStructs{1}.nParts);
    params.fInfo.iDir = ['/auto/k6/mark/InSilicoStim_ModelParams_Int/' StimStructs{pNum==iP}.StimClass '_' StimStructs{pNum==iP}.x_id];
    S = load(StimStructs{pNum==iP}.Path); % 'ssec','sdim','shz','tr',
    %%% Preprocess stimulus
    if IsGabor
        SppF = strrep(StimStructs{pNum==iP}.Path,'.mat',sprintf('_SppPt%d.mat',iP));
        if exist(SppF,'file')
            % no built-in saving of intermediate files for Gabor preproc,
            % so do it here (& below)
            fprintf('Loading preproc file: %s\n',SppF);
            load(SppF,'Spreproc','s_mean','s_stds'); % loads Spreproc
        else
            [Spreproc,paramsFin] = feval(Opt.preprocFn,S.S,params,ppArg{:});
        end
    else
        [Spreproc,paramsFin] = feval(Opt.preprocFn,S.S,params,ppArg{:});
    end
    
    if IsGabor
        if ~exist('s_mean','var')
            s_mean = paramsFin.means;
            s_stds = paramsFin.stds;
        end
        save(SppF,'Spreproc','s_mean','s_stds')
    end
    % To make the dimensions of the response weight matrix and the preprocessed
    % stimulus matrix match up, we either have to get rid of the lag predictors
    % from the  weights (and the mean predictor??), or we have to replicate the
    % preprocessed stimulus so it matches the shape of the weights (i.e., we
    % have to put lags in it). 
    if strcmp(Opt.LagOpt,'AddLags')
        X = [];
        if any(ModStruct.Lags)
            for iLag = ModStruct.Lags
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
        clear d
        simRespTmp = [];
        for iW = 1:nWtParts
            d = load(wtName{iW});
            if strcmp(Opt.LagOpt,'RemoveLags')
                % Take the mean of all 3 lags
                ww = reshape(d.weights,[size(d.weights,1)/3,3,size(d.weights,2)]);
                d.weights = squeeze(nanmean(ww,2)); % Use MAX weight from the 3 delays...
                clear ww;
            end
            simRespTmp = [simRespTmp,Spreproc*d.weights]; % calculate response per stim
        end
    else
        simRespTmp=Spreproc*d.weights; % calculate response per stim
    end
    % Concatenate simulated responses
    simResp = [simResp;simRespTmp];
end
blockLength_TR = S.Opts.sSec/Opt.TR;
stimRespR=reshape(simResp(1:end-blockLength_TR,:),blockLength_TR,sDim{:},[]);
nToCut = 1; % TRs to cut from beginning / end of blocks. Modify? Incorporate into stim / model struct?
simDat=squeeze(sum(stimRespR((1+nToCut):(end-nToCut),sDimIdx{:},:),1)); % mask out the first and last trs
simDat0=sum(simResp(end-S.Opts.sSec/Opt.TR+2:end-1,:),1);
simDat0=reshape(simDat0,sDimIdx2{:});
simDat=bsxfun(@minus,simDat,simDat0);

% Save in STRFdb
Status = dbSave(Opt,'http://meth:5984','strfdb-ml') %#ok<NOPRT,NASGU>
% Save .mat file
save(Opt.Path,'simDat','Opt','modcc','mask','-v7.3');

