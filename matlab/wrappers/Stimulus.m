classdef Stimulus
    properties
        S
        type = 'Stimulus';
        stim_class
        exp % BVP, NaturalMoviesSN, InSilico, etc
        session
        sz
        n_frames
        path
        hz
        part
        n_parts
        dbi = mlabSTRFdb;
        extras
    end
    
    methods
        
        function self = Stimulus(S,Opts,dbi)
            % Usage: Stim = Stimulus([S] [,Opts][,dbi])
            % 
            % Class to store stimulus / stimulus meta-info 
            % 
            % Inputs:
            %   S : Stimulus matrix (m x n image, m x n x 3 x nIms color
            %       movie, etc.). Can be left blank [] to defer loading to
            %       save memory.
            %   Opts : Stimulus identifying info. These fields are written
            %       to the stimulus object's basic properties, which are:
            %       .type = 'Stimulus'; [No other option]
            %       .stim_class = string; e.g. 'Gratings','RGB','Normals',
            %         etc
            %       .exp = string experiment identifier, e.g. 'BVP'
            %       .session = scalar session number, e.g. 1
            %       .sz = [m,n] size of stimulus. This is most often
            %         [height, width] for an image, but it can be [time,1]
            %       .n_frames = length of stimulus in frames
            %       .hz = presentation rate of stimulus in frames / sec
            %       .part = part number of potentially multiple parts (use
            %           1 for 1-part stim)
            %       .n_parts = total number of parts for this whole stimulus
            %       .dbi = mlabSTRFdb instance
            %       < Other parameters for the stimulus (e.g. orientation
            %       of gratings, etc) may be included in Opts, too.
            %       HOWEVER, remember that floating-point numbers are a
            %       COLOSSAL pain in the ass to deal with as keys in a
            %       database, so do NOT plan on being able to search your
            %       database for floats. Other parameters will be stored in
            %       the field ".extras"
            % Methods: 
            %   .get_docdict(AllParts) - Creates a struct array from the
            %       Stimulus object, suitable for storing in a STRF
            %       database. Setting AllParts to true removes unique part
            %       identifiers (.part, ._id, ._rev, .path)
            %   .dbGet - if only partial (but unique!) identifying
            %       information for a stimulus in the database is provided
            %       in Opts, this fills in the blanks from the database
            %   .load - load stimulus from database
            %   .save(sDir) - save stimulus to databse, with stimulus
            %       matrix saved in sDir (which defaults to
            %       '/auto/k7/mark/StimDB/')
            % 
            % ML 2013.03
            
            % Optionally delay loading S (stimulus matrix)
            if ~exist('S','var')
                S = [];
            end
            self.S = S; clear S;
            if ~isempty(self.S)
                SzTmp = size(self.S);
                % Fill n_frames, sz;
                if ndims(self.S)>2
                    disp('Setting size')
                    self.sz = SzTmp(1:2);
                    self.n_frames = SzTmp(end);
                elseif ismatrix(self.S)
                    if SzTmp(1)==SzTmp(2)
                        warning('Ambiguous Stimulus! Assuming image, 1 time frame.');
                        self.sz = SzTmp;
                        self.n_frames = 1;
                    else
                        warning('Ambiguous Stimulus! Assuming 1st dimension is TIME or FRAMES, 2nd is size')
                        self.sz = SzTmp(2);
                        self.n_frames = SzTmp(1);
                    end
                end
            end            
            if ~exist('Opts','var')
                Opts = struct;
            end
            if exist('dbi','var')
                self.dbi = dbi;
            end
            fn = fieldnames(Opts);
            for i = 1:length(fn)
                if isprop(self,fn{i})
                    self.(fn{i}) = Opts.(fn{i});
                else
                    self.extras.(fn{i}) = Opts.(fn{i});
                end
            end
        end
        
        function qStr = get_docdict(self,AllParts)
            % Usage: qStr = get_docdict(self,AllParts)
            %
            % Combines Stimulus properties and "extras" properties into a
            % struct array suitable for searching couch database via
            % dbi.query (or whatever). Use this struct array to save param
            % structs.  
            
            if ~exist('AllParts','var')
                AllParts = false;
            end
            props = properties(self);
            toRm = {'S','dbi','extras'};
            if AllParts
                if isempty(self(1).dbi)
                    dbTmp = mlabSTRFdb('dummy','instance');
                    toRm = [{'path',[dbTmp.prefix '_rev'],[dbTmp.prefix '_id'],'part'},toRm];
                else
                    % Allow for potentially different prefix in self.dbi
                    toRm = [{'path',[self(1).dbi.prefix '_rev'],[self(1).dbi.prefix '_id'],'part'},toRm];
                end
            end
            % This should loop over all parts of the stimulus...
            qStr = struct;
            for ii = 1:length(props)
                if ~ismember(props{ii},toRm)
                    qStr.(props{ii}) = self(1).(props{ii});
                end
                if isfield(qStr,props{ii}) && isempty(qStr.(props{ii})); %(strcmp(qStr.(props{ii}),'')
                    qStr = rmfield(qStr,props{ii});
                end
            end
            if ~isempty(self(1).extras)
                eprops = fieldnames(self(1).extras);
                for ii = 1:length(eprops)
                    if ~ismember(eprops{ii},toRm) && ~isempty(self(1).extras.(eprops{ii}))
                        qStr.(eprops{ii}) = self(1).extras.(eprops{ii});
                    end
                end
            end
            
        end
        
        function self = dbGet(self,AllParts)
            % Fill in blank params from database             
            if ~exist('AllParts','var')
                AllParts = false;
            end
            if strcmp(self.stim_class,'MultiComponent')
                % Multi-component stimulus!
                for iC = 1:length(self.extras.Components)
                    qS = self.get_docdict(AllParts);
                    qS = rmfield(qS,'Components');
                    qS.stim_class = self.extras.Components{iC};
                    if isfield(qS,'sz')
                        %  Always provide sz as a cell w/ 1 entry for each
                        %  component!
                        qS.sz = self.sz{iC};
                    end
                    tmpS{iC} = Stimulus([],qS,self.dbi); %#ok<AGROW>
                    tmpS{iC} = tmpS{iC}.dbGet(AllParts); %#ok<AGROW>
                end
                % Double-checks for consistency
                L = cellfun(@length,tmpS);
                if ~all(L==L(1))
                    error('Can''t handle different components with different numbers of parts yet!')
                end
                n = L(1);
                % Split multiple parts 
                self = repmat(self,[n,1]); 
                for ii = 1:n
                    self(ii).S = cellfun(@(x) x(ii),tmpS,'uni',false);
                    self(ii).n_parts = n;
                    self(ii).part = ii;
                end
                return
            end
            % Query database for objects matching parameters of this object
            Sdict = self.dbi.query(self.get_docdict(AllParts));
            n = length(Sdict);
            if iscell(Sdict)
                error('Query returns structs with different fields! not same stimulus!')
            end
            if isempty(Sdict)
                error('Specified stimulus not found in database!')
            end
            % Check for consistency of part / n_parts
            nP = [Sdict.n_parts];
            order = [Sdict.part];
            [~,idx] = sort(order);
            if ~all(max(order)==nP)
                error('Problem with number of parts of your stimulus!');
            end
            if n>1 && ~all(nP(1)==nP(2:end))
                warning('Different stimuli present!')
                % Give up and don't sort - all are different
                idx = 1:n;
            end
            % duplicate for multi-part stimuli
            self = repmat(self,[n,1]);
            %disp(order)
            for ii = 1:n
                % Use [] for all to avoid memory problems
                self(ii) = Stimulus([],Sdict(ii),self(ii).dbi);
            end
            self = self(idx);
        end
        
        function self = load(self)
%                 if strcmp(self.S(iPart).stim_class,'MultiComponent')
%                     Stmp = self.S(iPart);
%                     StmpOrig = Stmp;
%                     Stmp.S = struct;
%                     for iComp = 1:length(Stmp.extras.Components);
%                         s = StmpOrig.S{iComp}.load();
%                         Stmp.S.(Stmp.extras.Components{iComp}) = s.S;
%                         clear s;
%                     end
            if strcmp(self.stim_class,'MultiComponent')
                Stmp = struct;
                for iComp = 1:length(self.extras.Components);
                    s = self.S{iComp}.load();
                    Stmp.(self.extras.Components{iComp}) = s.S;
                    clear s;
                end
                self.S = Stmp;
                return
            end
            % load stimulus data from files
            if isempty(self.path)
                error([mfilename ':PathEmpty'],'Can''t load due to empty path field!')
            end
            if ~exist(self.path,'file')
                error([mfilename ':BadPath'], 'Specified load path does not exist!')
            end
            try
                tmp = load(self.path);
                self.S = tmp.S;
            catch ME %#ok<NASGU>
                % Check ME error?
                % Get info first? always store as "S"?
                self.S = h5read(self.path,'/S');
                if ndims(self.S)==2
                    % Transpose from hf5 orientation (python/matlab
                    % difference)
                    disp('Transposing 2D stimulus...')
                    self.S = self.S';
                    disp(size(self.S))
                end
            end
            SzTmp = size(self.S);
            % Fill n_frames, sz;
            if ndims(self.S)>2 %#ok<*ISMAT>
                self.n_frames = SzTmp(end);
                self.sz = SzTmp(1:2);
            else
                warning('assuming 1st dimension is TIME or FRAMES, 2nd is size')
                self.n_frames = SzTmp(1);
                self.sz = SzTmp(2);
            end
        end
        
        function save(self,sDir)
            % Usage: Stimulus.save(sDir)
            %
            % Saves Stimulus object in specified directory (sDir), with a
            % UUID file name (generated by Stimulus.save)
            if ~exist('sDir','var')
                sDir = '/auto/k8/mark/StimDB/';
            end
            % Save stimulus to database
            AllParts = false; % always save unique parts only to database
            % Separate data from meta-data
            tmp = self.S;
            self.S = [];
            xID = [self.dbi.prefix '_id'];
            if ~isfield(self.extras,xID)
                self.extras.(xID) = self.dbi.getUUID;
            end
            if isempty(self.path)
                self.path = fullfile(sDir,[self.extras.(xID) '.mat']);
            end
            self.dbi.save(self.get_docdict(AllParts));
            if ~isempty(tmp)
                % Save meta-data and params w/ fancy save to conserve memory
                mio = matfile(self.path,'writable',true);
                mio.props = self.get_docdict(AllParts);
                mio.S = tmp;
            end
        end
    end
end