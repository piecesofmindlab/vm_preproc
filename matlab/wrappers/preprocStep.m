classdef preprocStep
    properties
        fn
        S
        params
        dbi
        sDir
        tmpDir
    end
    methods
        function self = preprocStep(fn,S,params,dbi,sDir,tmpDir)
            % Usage: ppStep = preprocStep(fn,S,params [,dbi] [,tmpDir])
            %
            % Generalized preprocessing step in preproc pipeline.
            % 
            % Inputs:
            %   fn : preprocessing function function name
            %   S : Stimulus / input, which can be a previous stage of preprocessing)stimulus (S) 
            %   params : parameters for the preproc function. 
            %       **The following params fields affect ppStep directly:**
            %       .dbCache
            %       .concatenatePreprocessedStimulus
            % 
            % Optional Inputs (only necessary if params.dbCache == true):
            %   dbi: mlabSTRFdb object for storing results in database
            %   sDir : directory in which to save output
            %   tmpDir : directory in which to save temporary intermediate
            %       files
            % 
            % Outputs: 
            %   ppStep : ppStep object
            % 
            % ** For additional notes, see code! ** 
            % 
            % ML 2013.03
            
            %%% -- NOTES --- %%%
            % 
            % The most confusing / complex aspects of this code deal with
            % multi-part stimuli. It is necessary to break up large movie
            % stimuli since they are too large to fit in RAM all at once.
            % Once the stimulus is broken up into parts (which are
            % saved/loaded separtely), they must be re-combined at some
            % stage of processing. This functionality is governed by 
            % concatenatePreprocessedStimulus in the params struct, as well
            % as the variable is_concat.
            
            self.fn = fn;
            self.S = S;
            self.params = params;
            if exist('dbi','var')
                self.dbi = dbi;
            end
            if exist('sDir','var')
                self.sDir = sDir;
            end
            if exist('tmpDir','var') && ~isempty(tmpDir)
                self.tmpDir = tmpDir;
            end
        end
        
        function varargout = run(self,clusterOpts)
            % Run the specified preprocessing stream.
            %
            % clusterOpts is an optional struct array; if it exists, it
            %   will call a cluster instance of this function to run this
            %   job. clusterOpts has fields:
            %     .clusterFn = function to call a string of matlab commands
            %       via your cluster. for Gallant lab, 'slurm_sbatch'
            %     .jobParams = parameter argument for (slurm or other
            %       cluster) jobs.
            %
            % ML 2013.03
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%                     Input handling                      %%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if ~exist('clusterOpts','var')
                clusterOpts = [];
            end
            % Process job on cluster
            if ~isempty(clusterOpts)
                % Needs functional dbi to work!
                tmpF = self.dbi.getPath(self.tmpDir);
                save(tmpF,'self')
                % This is all particular to Glab cluster setup. Replace?
                varargout{1} = mlSlurm('self.run',tmpF,clusterOpts.jobParams);
                if nargout>1
                    varargout{2} = 'blarg';
                end
                return
            end
            % Convert stimulus to vm_tools "Stimulus" class
            if ismember(class(self.S),{'Stimulus','FeatureSpace'})
                % kill this? 
                if isempty(self.S(1).n_parts)
                    self.S(1).n_parts = 1;
                end
            elseif isnumeric(self.S)
                % self.S is provided as a numerical matrix; convert to vm_tools class
                self.dbi = []; % no database recording of header-less stimuli
                Opts.stim_class = 'unknown';
                Opts.part = 1;
                Opts.n_parts = 1;
                Opts.hz = 15;
                self.S = Stimulus(self.S,Opts,self.dbi);
            else
                error('S must be a vm_tools class (Stimulus/FeatureSpace) or a numeric matrix')
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%   Query database for cached versions of feature space   %%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if ~isempty(self.dbi)
                % Check the database for previous (cached) run of this preprocessing sequence
                qStr.type = 'FeatureSpace';
                qStr.ppseq = self.params.ppseq;
                qStr.oStimulus = self.get_oStimulus_ids(self.S);
                %if isa(self.S,'Stimulus')
                %    qStr.Stimulus = self.get_stimulus_ids(self.S);
                %elseif isa(self.S,'FeatureSpace')
                %    if ~isfield(self.S.extras,'oStimulus')
                %        disp('WTF kind of Feature Space are you with no oStimulus!')
                %        keyboard;
                %    end
                %    qStr.oStimulus = self.S.extras.oStimulus;
                %end                        
%                 if length(qStr.ppseq)==2
%                     % Only one preprocessing step, thus just search for Stimulus
%                     qStr.Stimulus = sids;
%                 else
%                     qStr.oStimulus = sids;
%                 end
                disp('Searching for completed preprocessing of:')
                disp(qStr.ppseq)
                docdict_check = self.dbi.query(qStr);
                if ~isempty(docdict_check)
                    % Preprocessing has been run on this stimulus with these parameters
                    if iscell(docdict_check)
                        error('Stimuli with different parameters returned from dbi query! please check your stimulus encoding and try again!')
                    end
                    disp('Found preprocessed stim in database!')
                    sfile = fullfile(docdict_check(1).path,docdict_check(1).fname);
                    if ~exist(sfile,'file')
                        % Assume if one part is missing, all are...
                        disp('Found model, but path has been deleted! Re-preprocessing...')
                        % do something to preserve path/id??
                    else
                        if ~(isfield(self.params,'Is_Overwrite') && self.params.Is_Overwrite)
                            % If we're not going to overwrite them, return cached values
                            nS = length(docdict_check);
                            paramtmp = struct;
                            for iPart = 1:nS
                                if iPart==1
                                    % params should be the same for all
                                    % parts; thus only load them for part 1
                                    try
                                        % .mat file 
                                        ftmp = matfile(Spreproc.path,'writable',false);
                                        paramtmp = ftmp.params;
                                    catch % specific error?
                                        try
                                            % .hdf file
                                            paramtmp = h5read(Spreproc(iPart).path,'/params');
                                        catch
                                            % may cause errors! not sure if
                                            % all pp functions have "class"
                                            % field in their params.
                                            paramtmp = struct('class',self.params.class);
                                        end
                                    end
                                end
                                idx = [docdict_check.part]==iPart;
                                % Make sure parts are correctly ordered and
                                % not too many results were returned
                                if sum(idx)==0; 
                                    error(sprintf('Blaaaa! part %d notfound!',iPart)); 
                                elseif sum(idx)>1
                                    error(sprintf('Multiple database documents for part %d found!',iPart));
                                end
                                Spreproc(iPart) = FeatureSpace([],docdict_check(idx));
                            end
                            varargout{1} = Spreproc;
                            if nargout==2
                                % Get params
                                varargout{2} = paramtmp;
                            end
                            return
                        end
                    end
                end
                clear qStr;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%      Preprocess nested parameters w/ recursive call     %%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if isfield(self.params,'PP')
                % if not last stage of preprocessing, save in temporary preprocessing folder
                TempDir = '/auto/k8/tempcache/';
                ppStep = preprocStep(self.params.PP.class,self.S,self.params.PP,self.dbi,TempDir,self.tmpDir);
                [self.S,self.params.PP] = ppStep.run();
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%     Process multiple parts of stimulus if necessary     %%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Concatenation or not
            if isfield(self.params,'concatenatePreprocessedStimulus') && ...
                    self.params.concatenatePreprocessedStimulus
                is_concat = true;
            else
                is_concat = false;
            end
            for iPart = 1:self.S(1).n_parts
                % Load stimulus matrix, if necessary
                if iscell(self.S(iPart).S) || isstruct(self.S(iPart).S) || isempty(self.S(iPart).S)
                    Stmp = self.S(iPart).load;
                else
                    Stmp = self.S(iPart);
                end
                % Use parameters from training data to compute features for
                % validation data, e.g. for zscore or PCA, when you need to
                % use the same transformation you created for the training
                % data:
                if isfield(self.params,'useTrnParams') && self.params.useTrnParams ...
                        && isfield(self.S.extras,'trnval') && strcmp(self.S.extras.trnval,'val')
                    % Get same params from training data. 
                    error('UseTrnParams not tested yet!')
                    % OLD:
                    % q = self.S.get_docdict(true); % All parts = true
                    % % Get trn stimulus that matches val stimulus
                    % mStim = rmfield(q.oStimulus,{'n_frames','n_parts'});
                    % mStim.trnval = 'trn';
                    % NEW:
                    q = self.S.get_docdict();
                    v_ostim = self.dbi.query([self.dbi.prefix '_id'],q.oStimulus); %q.oStimulus{1}?
                    trnq = rmfield(v_ostim,'n_frames','n_parts');
                    t_ostim = self.dbi.query(trnq);
                    t_ostim_ids = {t_ostim.([self.dbi.prefix '_id'])};
                    % OLD: q = struct('type','FeatureSpace','mStim',mStim,'ppseq',{self.params.ppseq},'trnval','trn');
                    % FUCK there is an assumption here that this will be
                    % sufficiently far along that there will be an
                    % oStimulus field. We should really have that
                    % EVERYWHERE.
                    q = struct('type','FeatureSpace','oStimulus',{t_ostim_ids},'ppseq',{self.params.ppseq},'trnval','trn');
                    Trn = self.dbi.query(q);
                    if length(Trn)>1
                        error('Can''t match trn parameters to val parameters!')
                    end
                    TrnIO = matfile(Trn.path);
                    TrnPP = TrnIO.params;
                    % Keep previous steps' params for val, replace this
                    % step w/ trn
                    if isfield(self.params,'PP');
                        TrnPP.PP = self.params.PP;
                    end
                    self.params = TrnPP;
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%  Actually run the function we came to run (WHOO!)   %%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [SppTmp,ppTmp] = feval(self.fn,Stmp.S,self.params);
                
                % Props to save, if necessary (start with retrieved doc)
                if ~is_concat && isfield(ppTmp,'dbCache') && ppTmp.dbCache
                    docdict_part = docdict_check; % start with _id and _rev fields
                end
                docdict_part.Stimulus = self.get_stimulus_ids(self.S(iPart));
                docdict_part.oStimulus = self.get_oStimulus_ids(self.S(iPart));
                sz = size(SppTmp);
                if length(sz)>2
                    docdict_part.n_frames = sz(end);
                    docdict_part.sz = sz(1:2);
                elseif length(sz)==2
                    docdict_part.n_frames = size(SppTmp,1);
                    docdict_part.sz = size(SppTmp,2);
                end
                docdict_part.ppseq = ppTmp.ppseq;
                docdict_part.hz = self.S(iPart).hz;
                docdict_part.exp = self.S(iPart).exp;
                docdict_part.session = self.S(iPart).session;
                docdict_part.part = self.S(iPart).part;
                docdict_part.n_parts = self.S(iPart).n_parts;
                if isfield(self.S(iPart).extras,'trnval')
                    docdict_part.trnval = self.S(iPart).extras.trnval;
                end
                % if not concat, save this unique part
                % Optionally save in database / file
                if ~is_concat && isfield(ppTmp,'dbCache') && ppTmp.dbCache
                    Spreproc(iPart) = FeatureSpace(SppTmp,docdict_part,self.dbi);
                    fprintf('Saving FeatureSpace w/ preproc steps:\n')
                    disp(Spreproc(iPart).ppseq)
                    ID = [self.dbi.prefix '_id'];
                    if ~isfield(Spreproc(iPart).extras,ID)
                        Spreproc(iPart).extras.(ID) = self.dbi.getUUID();
                        Spreproc(iPart).path = self.sDir;
                        Spreproc(iPart).fname = [Spreproc(iPart).extras.(ID) '.mat'];
                    end
                else
                    % Create temp file path with no dbi entry if not saving
                    % individual parts (at this stage) to the database 
                    Spreproc(iPart) = FeatureSpace(SppTmp,docdict_part,[]);
                    Spreproc(iPart).path = '/tmp/';
                    Spreproc(iPart).fname = ['TempPreprocFile_' mlabSTRFdb.getUUID() '.mat'];
                    fprintf('Saving TEMP file of FeatureSpace w/ steps:\n')
                    disp(Spreproc(iPart).ppseq)
                    fprintf('at: %s\n',fullfile(Spreproc(iPart).path,Spreproc(iPart).fname))
                end
                % This will not save to database for concat stim, because
                % dbi field in FeatureSpace object is left blank above; it
                % only saves a temp file, which is deleted below
                Spreproc(iPart).save(ppTmp); % w/ params struct
                % Clear preprocessed stim to save memory
                Spreproc(iPart).S = [];
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%        Re-concatenate all stim parts if desired         %%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if is_concat
                % re-load Spreproc parts
                ND = length(Spreproc(1).sz);
                nFrCum = [0,cumsum([Spreproc(1:end-1).n_frames])];
                nFrTot = sum([Spreproc.n_frames]);
                if ND==1
                    SppAll = zeros(nFrTot,Spreproc(1).sz);
                elseif ND==2
                    SppAll = zeros([Spreproc(1).sz,nFrTot]);
                end
                % Loop over parts to reload all
                for iPart = 1:self.S(1).n_parts
                    idx = 1:Spreproc(iPart).n_frames;
                    idx = idx+nFrCum(iPart);
                    if ND==1
                        dims = {idx,':'};
                    elseif ND==2
                        dims = {':',':',idx};
                    end
                    SppAll(dims{:}) = getfield(Spreproc(iPart).load,'S');
                end
                % Props to save, if necessary. Theres' no harm over-writing
                % these fields. _id, _rev, and path will exist from above
                if isfield(ppTmp,'dbCache') && ppTmp.dbCache
                    docdict_concat = docdict_check; % start with _id and _rev fields, if available
                end                
                docdict_concat.ppseq = ppTmp.ppseq;
                docdict_concat.hz = self.S(1).hz;
                docdict_concat.exp = self.S(1).exp;
                docdict_concat.session = self.S(1).session;
                docdict_concat.part = 1;
                docdict_concat.n_parts = 1;
                docdict_concat.date_run = dbDate;
                if isfield(self.S(1).extras,'trnval')
                    docdict_concat.trnval = self.S(iPart).extras.trnval;
                end
                sz = size(SppAll);
                if numel(sz)==1
                    docdict_concat.n_frames = sz;
                    docdict_concat.sz = 1;
                elseif numel(sz)==2
                    docdict_concat.n_frames = size(SppAll,1);
                    docdict_concat.sz = size(SppAll,2);
                elseif numel(sz)>2
                    docdict_concat.n_frames = sz(end);
                    docdict_concat.sz = sz(1:2);
                end
                % Get stimulus (input to this preprocessing step)
                docdict_concat.Stimulus = self.get_stimulus_ids(self.S);
                % Get original Stimulus (from start of preprocessing)
                docdict_concat.oStimulus = self.get_oStimulus_ids(self.S);
                
                Spreproc = FeatureSpace(SppAll,docdict_concat,self.dbi);
                % Optionally save in database / file (already done for
                % non-concat preprocessed stimuli)
                if isfield(ppTmp,'dbCache') && ppTmp.dbCache
                    fprintf('Saving FeatureSpace w/ preprocessing steps:\n')
                    disp(Spreproc.ppseq)
                    ID = [self.dbi.prefix '_id'];
                    if ~isfield(Spreproc.extras,ID)
                        Spreproc.extras.(ID) = self.dbi.getPath('','');
                        Spreproc.path = self.sDir;
                        Spreproc.fname = [Spreproc.extras.(ID) '.mat'];
                    end
                    Spreproc.save(ppTmp); % w/ params struct
                end
            end
            % Cleanup
            for iP = 1:self.S(1).n_parts
                sfile1 = fullfile(self.S(iP).path,self.S(iP).fname);
                if ~iscell(sfile1)
                    % (If self.S.fname is a cell, then for sure do NOT
                    % delete the files)
                    if exist(sfile1,'file') && any(strfind(sfile1,'TempPreprocFile'))
                        % Get rid of temp files from previous preprocesing steps 
                        delete(sfile1)
                    end
                end
            end
            % Outputs
            varargout{1} = Spreproc;
            if nargout>1
                varargout{2} = ppTmp;
            end
            % DONE
        end
        function ids  = get_oStimulus_ids(self,S)
            % Get ids for original stimulus (oStimulus) from which this
            % FeatureSpace was computed
            ids = {};
            if isa(S,'FeatureSpace')
                for ii = 1:length(S)
                    tmp = S(ii).extras.oStimulus;
                    ids = [ids,tmp];
                end
                return
            elseif isa(S,'Stimulus')
%                 if strcmp(S(1).stim_class,'multi_component')
%                     fnms = fieldnames(S(1).S);
%                     for ifn = 1:length(fnms)
%                         ids.(fnms{ifn}) = {};
%                     end
%                     for iS = 1:length(S)
%                         for ifn = 1:length(fnms)
%                             tmp = self.get_oStimulus_ids(S(iS).S.(fnms{ifn}));
%                             ids.(fnms{ifn}) = [ids.(fnms{ifn}),tmp];
%                         end
%                     end
%                     ids.stim_class = 'multi_component';
%                 end
%                 ids = cell(length(S),1);
%                 for iS = 1:length(S)
%                     tmp = S(iS).get_docdict();
%                     if isfield(tmp,'oStimulus')
%                         ids{iS} = tmp.oStimulus; % need index for cell array?
%                     else
%                         xID = [self.dbi.prefix '_id'];
%                         if isfield(tmp,xID)
%                             ids{iS} = {tmp.(xID)};
%                         else
%                             ids{iS} = {};
%                         end
%                     end
%                 end
%                 ids = [ids{:}];
                ids = get_stimulus_ids(self,S); % not self.get_stimulus_ids(self,S); % ??? 
            end
        end
        function ids  = get_stimulus_ids(self,S)
            % Get Stimulus (or FeatureSpace) from which this FeatureSpace
            % was computed
            if isprop(S(1),'stim_class') && strcmp(S(1).stim_class,'multi_component')
                fnms = fieldnames(S(1).S);
                for ifn = 1:length(fnms)
                    ids.(fnms{ifn}) = {};
                end
                for iS = 1:length(S)
                    for ifn = 1:length(fnms)
                        tmp = self.get_stimulus_ids(S(iS).S.(fnms{ifn}));
                        ids.(fnms{ifn}) = [ids.(fnms{ifn}),tmp];
                    end
                end
                ids.stim_class = 'multi_component';
            else
                ids = cell(length(S),1);
                for iS = 1:length(S)
                    tmp = S(iS).get_docdict();
                    xID = [self.dbi.prefix '_id'];
                    if isfield(tmp,xID)
                        ids{iS} = {tmp.(xID)};
                    else
                        ids{iS} = {};
                    end
                end
                ids = [ids{:}];
            end
        end
    
    end
end