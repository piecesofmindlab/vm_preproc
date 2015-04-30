classdef PreprocessedStimulus
    properties
        S
        type = 'PreprocessedStimulus'
        Stimulus % struct array to query database & find stimulus
        ppseq % Sequence of preprocessing, e.g. {'preprocColorSpace',1,'preprocWavelets_grid',1}
        exp
        sz
        n_frames
        session 
        path
        fname
        hz
        part
        n_parts
        db = mlabSTRFdb;
        extras

    end
    methods 
        
        function self = PreprocessedStimulus(Spreproc,Opts,db)
            % Usage: Spp = PreprocessedStimulus(Spreproc,Opts,db)
            % 
            % Class to hold preprocessed stimuli, potentially in parts
            % Inputs: 
            % Spreproc : 2-,3-,or 4-D stimulus matrix. if 2- or 3-D, last
            %       dimension is assumed to be time; if 2D, 1st dim is time
            % 
            % Opts : params struct array for preprocessing (up to this
            %       point)
            % db : (optional) - defaults to standard call to mlabSTRFdb,
            %       i.e., if you DON'T want a database, put a blank ( []  )
            %       variable into "db"
            
            % Inputs
            % Optionally delay loading S (stimulus matrix)
            if ~exist('Spreproc','var')
                Spreproc = [];
            end            
            if ~exist('Opts','var')
                Opts = struct;
            end
            if exist('db','var')
                self.db = db;
            end
            self.S = Spreproc;
            fn = fieldnames(Opts);
            for i = 1:length(fn)
                if isprop(self,fn{i})
                    self.(fn{i}) = Opts.(fn{i});
                else
                    self.extras.(fn{i}) = Opts.(fn{i});
                end
            end
        end
        
        function qStr = dbStruct(self,AllParts)
            % Usage: qStr = dbStruct(self,AllParts)
            %
            % Combines Stimulus properties and "extras" properties into a
            % struct array suitable for searching couch database via
            % db.query (or whatever). Use this struct array to save param
            % structs.  
            
            if ~exist('AllParts','var')
                AllParts = false;
            end
            props = properties(self);
            % Do not keep "S" as this is data, and will be huge; "db" is
            % re-created each time; "extras" is handled below
            toRm = {'S','db','extras'};
            if AllParts
                % Remove all unique identifiers for separate parts
                if isempty(self(1).db)
                    dbTmp = mlabSTRFdb('dummy','instance');
                    toRm = [{'path',[dbTmp.prefix '_rev'],[dbTmp.prefix '_id'],'part'},toRm];
                else
                    % Allow for potentially different prefix in self.db
                    toRm = [{'path',[self.db.prefix '_rev'],[self.db.prefix '_id'],'part'},toRm];
                end
            end
            qStr = struct;
            for ii = 1:length(props)
                if ~ismember(props{ii},toRm)
                    qStr.(props{ii}) = self.(props{ii});
                end
                if isfield(qStr,props{ii}) && isempty(qStr.(props{ii})); %(strcmp(qStr.(props{ii}),'')
                    qStr = rmfield(qStr,props{ii});
                end
            end
            % Place "extras" props back into top-level struct
            if ~isempty(self(1).extras)
                eprops = fieldnames(self(1).extras);
                for ii = 1:length(eprops)
                    if ~ismember(eprops{ii},toRm)
                        qStr.(eprops{ii}) = self(1).extras.(eprops{ii});
                    end
                    if isfield(qStr,eprops{ii}) && isempty(qStr.(eprops{ii})); %(strcmp(qStr.(props{ii}),'')
                        qStr = rmfield(qStr,eprops{ii});
                    end
                end
            end
            
        end
        
        function self = dbGet(self,AllParts)
            % Fill in blank params from database             
            if ~exist('AllParts','var')
                AllParts = false;
            end
            % Query database for objects matching parameters of this object
            Sdict = self.db.query(self.dbStruct(AllParts));
            n = length(Sdict);
            if iscell(Sdict)
                error([mfilename ':MultipleDBMatch'],'Query returns structs with different fields! not same stimulus!')
            elseif n==0
                error([mfilename ':NoDBobjectFound'],'Query could not find PreprocessedStimulus matching your request!')
            end
            % Check for consistency of part / n_parts
            nP = [Sdict.n_parts];
            order = [Sdict.part];
            if ~all(max(order)==nP)
                error('Problem with number of parts of your stimulus!');
            end
            % duplicate for multi-part stimuli
            self = repmat(self,[n,1]);
            %disp(order)
            for ii = 1:n
                self(ii) = PreprocessedStimulus(self(ii).S,Sdict(ii),self(ii).db);
            end
            self = self(order);
        end
        
        function self = load(self)
            % load stimulus data from files
            try
                tmp = load(self.path);
                self.S = tmp.Spreproc;
            catch ME
                % Get info first? always store as "S"?
                self.S = h5read(self.path,'/Spreproc');
            end
            sz = size(self.S);
            % Fill n_frames, sz;
            if isempty(self.n_frames)
                self.n_frames = sz(end);
            end
            if isempty(self.sz)
                if ndims(self.S)>2
                    self.sz = sz(1:2);
                else
                    warning('assuming 1st dimension is TIME or FRAMES, 2nd is size')
                    self.sz = sz(2);
                end
            end
        end
        
        function save(self,params,sDir)
            % Save preprocessed stimulus to database
            % Inputs: 
            % params : (optional) full preproc param struct. Saved w/
            %       preprocessed stimulus in .mat (-v7.3) file, NOT in
            %       database (too problematic).

            % Separate data from meta-data
            tmp = self.S;
            self.S = [];
            AllParts = false; % always save unique parts only to database
            SppChk = self.dbStruct(AllParts);
            % Save to database if self.db is not empty; to temp file
            % otherwise
            if ~isempty(self.db)
                % Check for preprocessed stimulus in database
                % (this will OVERWRITE previous versions)
                cacheF = self.db.query(SppChk);
                if length(cacheF)==1
                    % Stimulus found; keep _id and _rev
                    SppChk.([self.db.prefix,'_id']) = cacheF.([self.db.prefix,'_id']);
                    SppChk.([self.db.prefix,'_rev']) = cacheF.([self.db.prefix,'_rev']);
                elseif length(cacheF)>1
                    fprintf(['Somehow there are two stimuli matching your description in the db\n'...
                        'This is an unacceptable situation. I have no idea why I did not catch this earlier.\n'...
                        'I fail. Fuck you very much.\n']);
                    error('Attempted to save non-unique stimulus! WTF!')
                    % If you are here, you probably saved a preprocessed
                    % stimulus BEFORE concatenation... maybe?
                end
            end
            % Common to both db save and temp file save:
            % Get ORIGINAL stimulus from base of all stimuli as separate
            % searchable entity
            if isfield(SppChk.Stimulus,'Stimulus') && ~isfield(SppChk,'oStimulus')
                SppChk.oStimulus = SppChk.Stimulus.Stimulus;
                while isfield(SppChk.oStimulus,'Stimulus')
                    % Get to the bottom of the rabbit hole, bring back original stimulus:
                    SppChk.oStimulus = SppChk.oStimulus.Stimulus;
                end
            end
            % HACKY: Get "trnval" field in particular. We should assure
            % that all relevant parameters from original stimulus get
            % passed on to PreprocessedStimulus in the "extras" field...
            if isfield(SppChk,'oStimulus') && isfield(SppChk.oStimulus,'trnval')
                SppChk.trnval = SppChk.oStimulus.trnval;
            elseif isfield(SppChk.Stimulus,'trnval')
                SppChk.trnval = SppChk.Stimulus.trnval;
            end
            % Date run!
            SppChk.DateRun = datestr(now,'yyyy/mm/dd HH:MM'); %time.strftime('%Y/%M/%d %H:%M')
            if ~exist('sDir','var')
                sDir = '/auto/k8/mark/StimDB/';
            end
            
            % Save stimulus to database
            xID = [self.db.prefix '_id'];
            if ~isfield(SppChk,xID)
                SppChk.(xID) = self.db.getUUID;
            end
            
            if ~isfield(SppChk,'path') || isempty(SppChk.path)
                SppChk.path = fullfile(sDir,[SppChk.(xID) '.mat']);
            end

            % Save stimulus to database
            self.db.save(SppChk)

            % Save preproc stimulus to file
            % Save meta-data and params w/ fancy save to conserve memory
            mio = matfile(SppChk.path,'writable',true);
            mio.props = self.dbStruct;
            mio.Spreproc = tmp;
            if exist('params','var') && ~isempty(params)
                % Optionally save whole preproc params struct
                mio.params = params;
            end
        end
    end
end