function MaskStack = preprocStackMasks(S,params,db)
% Usage: MaskStack = preprocStackMasks(S,params,db)
%
% Takes object masks rendered by BVP (Blender Vision Project) and creates a
% [MaxImSz x MaxImSz x nMasksMax x nFrames] matrix. Masks are stacked along
% the 3rd dimension of this matrix in depth order wrt the camera (far ->
% near).  I.e., the LAST mask (MaskStack(:,:,end,fr)) is the closest to the
% camera for that frame. NOTE that which object is closest to the camera
% for a given scene might change if the camera or any of the objects moves!
%
% Relies on BVP conventions for directory structure for mask and z depth
% images (see below).
%
% Inputs:
%  S = a cell array of strings for each image file (usually each
%      frame) in a stimulus set, or a string file name for a .txt file that
%      specifies file names for all images (frames). List should NOT
%      include blank frames (for GLab exps, blanks are often Sc0000_00.png)
%  params = a parameter struct array, with fields: 
%	.MaxImSz = max [x,y] size of images. Scalar quantity assumes square
%       images.
%	.nMasksMax = max # of object per image default = 4 
%	.ChunkSz = number of frames per chunk (memory saving - these matrices
%       can be large for 40 min movies) default = 5000
%   .mThresh = threshold for converting bw image to logical mask. 
%         default = 5 (/255) 
%   .parallel = true/false, whether to parallelize w/ cluster (requires
%       GLab slurm code to be on path!!)
%   (.chunkN) = set for recursive slurm calls only; see code (do not set!)
%   .session = 1; % Experiment session
% 	.sDir = '/auto/k7/mark/StimDB/'; % Where to save this file
% 	.sHz = 15; % Stim presentation rate
% 	.exp = 'dummy'; % Experiment identifier string
%  db = mlabSTRFdb instance, for saving concatenated mask files to
%         database. If omitted, nothing is stored.
% 
% Assumes standard Blender Vision Project directory structure, which is:
% <BaseDir>/Scenes/ScXXXX_XX.png
% <BaseDir>/Masks/ScXXXX_XX_mXX.png
% <BaseDir>/Zdepth/ScXXXX_XX_z.png
%
% ML 2011.08
% Updated 2013.06.03

% Options

% Inputs
if ischar(S) && strcmp(S(end-3:end),'.txt')
    % Read file into cell array
    InptFile = S;
    fid = fopen(InptFile);
    count = 1;
    while(1)
        CC{count} = fgetl(fid);
        if ~ischar(CC{count}), CC=CC(1:end-1); break, end
        count = count+1;
    end
    fclose(fid); clear fid;
    S = CC;
elseif ischar(S) && ~strcmp(S(end-3:end),'.txt')
    S = {S};
end

% Get image size
tmp = imread(S{1});
ImSz = size(tmp);
ImSz = ImSz(1:2);
clear tmp;

dParams.sz = ImSz;
dParams.nMasksMax = 4;
dParams.ChunkSz = 5000; % n frames per chunk of stimulus
dParams.parallel = true; % slurm call to parallelize 
dParams.mThresh = 5;
dParams.session = 1; % Experiment session
dParams.sDir = '/auto/k7/mark/StimDB/'; % Where to save this file
dParams.sHz = 15; % Stim presentation rate
dParams.exp = 'dummy'; % Experiment identifier string
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);

if ~exist('db','var') || (exist('db','var') && isempty(db))
    db = [];
    Is_Save = false;
else
    Is_Save = true;
end

% Frame count
nFrames = length(S);
% Divide into chunks to save memory
if nFrames < params.ChunkSz
    nChunks = 1;
    params.ChunkSz = nFrames;
else
    nChunks = ceil(nFrames / params.ChunkSz);
end

% To handle recursive calls:
if isfield(params,'chunkN')
    procChunks = params.chunkN;
    params = rmfield(params,'chunkN');
else
    procChunks = 1:nChunks;
end

% Loop over chunks, frames
for iChunk = procChunks
    % Create recursive call (via Slurm) if requested:
    if params.parallel
        % Warning: lots of hard-coded BS this section, specific to ML /
        % GLab slurm setup. ML is one lazy-ass SOB.
        slurmDir = '/auto/k1/mark/SlurmLog/'; 
        if ~Is_Save
            error('I''m pretty sure you want to save mask stack to db if you''re running this on slurm...')
        end
        pp = params;
        pp.chunkN = iChunk;
        pp.parallel = false;
        % Set up for slurm call
        jp.cpus = 1;
        jp.memory = 7700; 
        jp.out = ['/auto/k1/mark/SlurmLog/preprocStackMasks_%j_' datestr(now,'mm_dd_HHMM') '.out']; 
        tmpF = [db.getUUID() '.mat'];
        save(tmpF,'S','pp','db');
        catchStr = ['fid = fopen(''',sprintf('%sErrorFile_%s_%s_%s.txt',...
            slurmDir,mfilename,datestr(now,'mm_dd_HHMM'),db.getUUID) ''',''w'');'...
            'fprintf(fid,''Slurm job failed! Details:\n%s'','...
            'getReport(ME)' ');'];
        addpath('/auto/k1/queued/');
        % Make sure this directory has a copy of "SetSlurmPath"
        if ~exist('./SetSlurmPath.m','file')
            copyfile('/auto/k1/mark/MyCode/mlMatlab/Utilities/Miscellaneous/SetSlurmPath.m');
        end
        slurmCmd = ['SetSlurmPath; try; load(''' tmpF '''); preprocStackMasks(S,pp,db); delete(''' tmpF '''); catch ME;' catchStr ' end;'];
        %preprocStackMasks(S,pp,db);
        jID = slurm_sbatch(slurmCmd,jp);
        if iChunk == 1
            MaskStack = {jID};
        else
            MaskStack = [MaskStack,{jID}];
        end
        continue
    end
    fprintf('Processing chunk %d\n',iChunk)
    % (potentially) smaller chunk for last chunk:
    if iChunk==nChunks
        ThisChunkSz = nFrames-(params.ChunkSz*(nChunks-1));
    else
        ThisChunkSz = params.ChunkSz;
    end
    % Preallocation for this chunk (this is the expensive memory step)
    MaskStack = zeros([params.sz(1),params.sz(1),params.nMasksMax,ThisChunkSz],'uint8');
    for iFr = 1:ThisChunkSz
        % Track progress
        progressdot(iFr,50,1000,ThisChunkSz)
        % Get image file, and corresponding z and mask files
        iIm = iFr + (iChunk-1)*params.ChunkSz;
        [tmpDir,ScBase,Ext] = fileparts(S{iIm});
        BaseDir = fileparts(tmpDir);
        MaskF = dir(fullfile(BaseDir,'Masks',[ScBase '*']));
        % Exclude "mAll", mask for display that shows all objects together
        MaskF = grep({MaskF.name}','-v','mAll'); % Replace with "ismember" for more generality
        MaskF = grep(MaskF,'-v','.mat'); % Replace with "ismember" for more generality
        zF = dir(fullfile(BaseDir,'Zdepth',[ScBase '*']));
        zF = fullfile(BaseDir,'Zdepth',{zF.name}');
        zF = grep(zF,'-v','.mat');
        zF = zF{1};
        % Load masks
        mTmp = zeros([params.sz(1),params.sz(1),params.nMasksMax],'uint8');
        for iM = 1:length(MaskF);
            mIm = imread(fullfile(BaseDir,'Masks',MaskF{iM}));
            mIm = imresize(mIm,[params.sz(1),params.sz(1)]);
            mTmp(:,:,iM) = mIm(:,:,1);
        end
        % load z image
        p.Type = 'realdepth';
        p.ImSz = params.sz(1);
        if any(strfind(zF,'exr'))
            zIm = exr2zDepth(zF,p);
        elseif any(strfind(zF,'hdr'))
            zIm = hdr2zDepth(zF,p);
        else
            error('Unknown depth file type!')
        end
        % Get depth ordering of masks
        for iM = 1:params.nMasksMax
            NotThisMask = ~ismember(1:params.nMasksMax,iM);
            OnlyThisMask = mTmp(:,:,iM) > params.mThresh & ~(any(mTmp(:,:,NotThisMask) > params.mThresh,3));
            ZD(iM) = mean(zIm(OnlyThisMask));% Z depth of whole mask
        end
        [~,DepthOrd] = sort(ZD,'descend');
        % Re-order all mask variables by depth
        MaskStack(:,:,:,iFr) = mTmp(:,:,DepthOrd);
    end
    %keyboard
    if Is_Save
        %Ss = Stimulus([],struct('StimClass','Masks',...
        Ss = Stimulus(MaskStack,struct('StimClass','Masks',...
            'part',iChunk,'nParts',nChunks,'nFrames',ThisChunkSz,...
            'sz',[params.sz,params.nMasksMax],'session',params.session,'sHz',params.sHz,...
            'exp',params.exp,'sDir',params.sDir),db);
        if isfield(params,'trnval')
            Ss.extra.trnval = params.trnval;
        end
        Ss.save(Ss.extra.sDir);
        clear Ss;
    end
end

