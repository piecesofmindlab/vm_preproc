function simulateResponseByVox(Model,Stim,ppSeq,VoxRFs,Opts,db)
% Usage: simulateResponseByVox(Model,Stim,params,VoxRFs,Opts,db)
%
% Simulates the response to a a stimulus *presented in the center of each
% voxel's receptive field*. Takes the stimulus ("Stim") and shrinks it to
% be centered in each of the "VoxRFs" (centering is subject to some of the
% options defined in "Opts"), then preprocesses the stimulus according to 
% "ppSeq". Stores the result in the STRF database "db".
% 
% This is principally a wrapper function; calls a bunch of slurm jobs (one
% for each voxel, and thus each different preprocessing sequence). The main
% work is done by preprocRFResize. 
% 
% Parameters for each voxel are NOT stored as of 2013.07.16
% 
% Inputs: 
%   Model : ** FOR NOW ** struct array for fit regression model, as stored
%       in STRFdb ** FUTURE: STRFmodel class? ** 
%   Stim : Stimulus class object for (full-filed) stim to be presented
%       within each voxel's RF
%   VoxRFs : struct array for STRFsim stored in STRFdb. Path will give info
%       on Gaussian RF center / size. 
%   *** NEED TO THINK ABOUT DIFFERENT SIZED SIM / MODELS ***
%   

% Inputs
if ~exist('db','var')
    db = mlabSTRFdb;
end
if ~exist('Opts','var')
    Opts = struct;
end

% Options
dOpts.ppConcat = [];
dOpts.TR = 2;
dOpts.VoxSelect = [];
dOpts.LagOpt = 'CollapseLagsMean'; %'AddLags'; 
dOpts.DataDir = '/auto/k8/mark/SimulatedResponseDB/';
dOpts.Overwrite = false;
dOpts.Session = 1; % Why?
dOpts.postProcSeq = [];
% Fill structs w/ defaults
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

% Load model w/out using memory: 
mio = matfile(Model.path);

% Get size of model
if ~isempty(Opts.VoxSelect)
    VoxMask = 0;
    nVox = sum(VoxMask(:));
else
    [nVox,nChanFull] = size(mio,'weights')
end

% Switcheroo for different sizes of voxels

% For slurm:
Jobs = []; % {}?
for iVox = 1:nVox
    % Proceed only if the voxel is in the desired mask
    if ~VoxMask(iVox)
        continue
    end
    % Load Model weights for THIS VOXEL
    w = mio.weights(iVox,2:nChanFull); % Skip 1st weight (mean)
    % Save to a hash of the weights
    
    % (Delete when done)
    
    % Set up resizing of stimulus as a preprocessing step: get RF center
    p = VoxRFs(v,:); % !!! FIX ME !!! 
    % Define a grid of possible RF locations (same as used by preprocRFResize) 
    nLoc = 17;
    nSz = 10;
    t = linspace(0,1,nLoc+2);
    [x,y] = meshgrid(t,t);
    % Discard edges
    x = x(2:end-1,2:end-1); x = x(:);
    y = y(2:end-1,2:end-1); y = y(:);
    % Find min distance to RF center
    dstTmp = squareform(pdist([p;[x,y]]));
    [dst,ptNum] = min(dstTmp(1,2:end));
    % ptNum is location; now find SIZE
    szPoss = linspace(.1,1,nSz);
    [rfSz,szNum] = min(
    
    rf = zeros(17,17,10);
    % More factors here: how much 
    ppOpts.concat = [false;Opts.ppConcat(:);false]';
    % No searching of DB / storing in DB; no need to crowd the database w/
    % every voxel from every subject 
    ppOpts.dbCache = false;
    ppOpts.Is_Overwrite = false;
    ppOpts.db = []; 
    ppOpts.sDir = '/tmp/'; % Because result will be deleted
    ppOpts.tmpDir = '/tmp/'; % (So will this)
    ppOpts.clusterOpts = []; % Need slurm info here

    
    ppSequence = [{'preprocRFResize',rf},ppSeq,{'preprocVoxWt',fNm}];
    jID = preprocPipeline(Stim,ppSequence,ppOpts);
    
    Jobs = [Jobs;jID];
    
end

% one last slurm job to stitch it all together