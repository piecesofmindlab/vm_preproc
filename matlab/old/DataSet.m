classdef DataSet
    properties
        Type = 'DataSet';
        data
        mask
        exp % BVP, NaturalMoviesSN, InSilico, etc
        task
        session
        path
        sz
        db = mlabSTRFdb;
        extra
%       Task % e.g. 'ObjCount'
%     x0x5F_rev: '5-849d428367a7181b8f26029c44abc285'
%         SubID: 'ML'
%          mpwc: '/auto/k8/mark/docdb/17268601222860621223.nii.gz'
%           Exp: 'BVP'
%          path: '/auto/k6/mark/BVP_fMRI/SubML_BVP_Ses1a-val.hf5'
%     docdbName: 'docdb-ml'
%        Magnet: 'BIC 3T'
%       docdbID: [1x128 char]
%            r2: '/auto/k6/mark/docdb/7091849370645250900.nii.gz'
%        trnval: 'val'
%          Type: 'fMRI_DataSet'
%       xfm_btw: 'automatic'
%       Detrend: 'Median'
%       Session: 1
%      x0x5F_id: '4a87adac3ba7453a95310186cf91db4c'

    end
    
    methods
        
        function self = DataSet(data,meta,mask,db)
            % Usage: Stim = Stimulus([data], meta [,mask][,db])
            % 
            % Class to store a data set
            % 
            % Inputs:
            %   data : data, time x channels or [x,y,z,t] for fMRI 3D
            %       volumes. Can be left blank [] to defer loading to save
            %       memory.
            %   meta : data set identifying info. These fields are written
            %           to the DataSet's basic properties, which are:
            %       .Type = 'DataSet'; [No other option]
            %       .DataClass = string; e.g. 'fMRI','Spikes', etc
            %       .exp = string experiment identifier, e.g. 'BVP'
            %       .session = session number, scalar or vector e.g. 1 or
            %           [1,2] 
            %       .sz = size of stimulus. This is most often [time,
            %           channels] e.g. for masked fMRI data, but it can be
            %           [x,y,z,t] (or whatever else)
            %   mask : mask for data %?? SEPARATE CLASS??%%
            %   db : mlabSTRFdb instance
            %       <Other parameters will be stored in the field ".extra">
            % 
            % Methods: 
            %   .dbStruct(AllParts) - Creates a struct array from the
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
            
            % Re-incorporate parts??
            
            % Optionally delay loading data 
            if ~exist('data','var')
                data = [];
            end
            if ~exist('meta','var')
                meta = struct;
            end
            if exist('db','var')
                self.db = db;
            end
            self.data = data; clear data;
            if ~isempty(self.data)
                self.sz = size(self.data);
            end
            fn = fieldnames(meta);
            for i = 1:length(fn)
                if isprop(self,fn{i})
                    self.(fn{i}) = meta.(fn{i});
                else
                    self.extra.(fn{i}) = meta.(fn{i});
                end
            end
        end
        
        function qStr = dbStruct(self,AllParts)
            error('unfinished!')
            % Usage: qStr = dbStruct(self,AllParts)
            %
            % Combines Stimulus properties and "extra" properties into a
            % struct array suitable for searching couch database via
            % db.query (or whatever). Use this struct array to save param
            % structs.  
            
            if ~exist('AllParts','var')
                AllParts = false;
            end
            props = properties(self);
            toRm = {'S','db','extra'};
            if AllParts
                if isempty(self(1).db)
                    dbTmp = mlabSTRFdb('dummy','instance');
                    toRm = [{'path',[dbTmp.prefix '_rev'],[dbTmp.prefix '_id'],'part'},toRm];
                else
                    % Allow for potentially different prefix in self.db
                    toRm = [{'path',[self(1).db.prefix '_rev'],[self(1).db.prefix '_id'],'part'},toRm];
                end
            end
            qStr = struct;
            for ii = 1:length(props)
                if ~ismember(props{ii},toRm)
                    qStr.(props{ii}) = self(1).(props{ii});
                end
                if isfield(qStr,props{ii}) && isempty(qStr.(props{ii})); %(strcmp(qStr.(props{ii}),'')
                    qStr = rmfield(qStr,props{ii});
                end
            end
            if ~isempty(self(1).extra)
                eprops = fieldnames(self(1).extra);
                for ii = 1:length(eprops)
                    if ~ismember(eprops{ii},toRm)
                        qStr.(eprops{ii}) = self(1).extra.(eprops{ii});
                    end
                    if isfield(qStr,eprops{ii}) && isempty(qStr.(eprops{ii})); %(strcmp(qStr.(props{ii}),'')
                        qStr = rmfield(qStr,eprops{ii});
                    end
                end
            end
            
        end
        
        function self = dbGet(self,AllParts)
            error('unfinished!')
            % Fill in blank params from database             
            if ~exist('AllParts','var')
                AllParts = false;
            end
            if strcmp(self.StimClass,'MultiComponent')
                % Multi-component stimulus!
                for iC = 1:length(self.extra.Components)
                    qS = self.dbStruct(AllParts);
                    qS = rmfield(qS,'Components');
                    qS.StimClass = self.extra.Components{iC};
                    if isfield(qS,'sz')
                        %  Always provide sz as a cell w/ 1 entry for each
                        %  component!
                        qS.sz = self.sz{iC};
                    end
                    tmpS{iC} = Stimulus([],qS,self.db);
                    tmpS{iC} = tmpS{iC}.dbGet(AllParts);
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
                    self(ii).nParts = n;
                    self(ii).part = ii;
                end
                return
            end
            % Query database for objects matching parameters of this object
            Sdict = self.db.query(self.dbStruct(AllParts));
            n = length(Sdict);
            if iscell(Sdict)
                error('Query returns structs with different fields! not same stimulus!')
            end
            if isempty(Sdict)
                error('Specified stimulus not found in database!')
            end
            % Check for consistency of part / nParts
            nP = [Sdict.nParts];
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
                self(ii) = Stimulus([],Sdict(ii),self(ii).db);
            end
            self = self(idx);
        end
        
        function self = load(self)
            error('unfinished!')
%                 if strcmp(self.S(iPart).StimClass,'MultiComponent')
%                     Stmp = self.S(iPart);
%                     StmpOrig = Stmp;
%                     Stmp.S = struct;
%                     for iComp = 1:length(Stmp.extra.Components);
%                         s = StmpOrig.S{iComp}.load();
%                         Stmp.S.(Stmp.extra.Components{iComp}) = s.S;
%                         clear s;
%                     end
            if strcmp(self.StimClass,'MultiComponent')
                Stmp = struct;
                for iComp = 1:length(self.extra.Components);
                    s = self.S{iComp}.load();
                    Stmp.(self.extra.Components{iComp}) = s.S;
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
                error([mfileame ':BadPath'], 'Specified load path does not exist!')
            end
            try
                tmp = load(self.path);
                self.S = tmp.S;
            catch ME
                % Get info first? always store as "S"?
                self.S = h5read(self.path,'/S');
            end
            SzTmp = size(self.S);
            % Fill nFrames, sz;
            self.nFrames = SzTmp(end);
            if ndims(self.S)>2
                self.sz = SzTmp(1:2);
            else
                warning('assuming 1st dimension is TIME or FRAMES, 2nd is size')
                self.sz = SzTmp(2);
            end
        end
        
        function save(self,sDir)
            error('unfinished!')
            if ~exist('sDir','var')
                sDir = '/auto/k8/mark/StimDB/';
            end
            % Save stimulus to database
            AllParts = false; % always save unique parts only to database
            % Separate data from meta-data
            tmp = self.S;
            self.S = [];
            xID = [self.db.prefix '_id'];
            if ~isfield(self.extra,xID)
                self.extra.(xID) = self.db.getUUID;
            end
            if isempty(self.path)
                self.path = fullfile(sDir,[self.extra.(xID) '.mat']);
            end
            self.db.save(self.dbStruct(AllParts));
            if ~isempty(tmp)
                % Save meta-data and params w/ fancy save to conserve memory
                mio = matfile(self.path,'writable',true);
                mio.props = self.dbStruct(AllParts);
                mio.S = tmp;
            end
        end
    end
end