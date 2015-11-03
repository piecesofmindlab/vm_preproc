function varargout = preprocPipeline(S,ppSeq,Opts)
% Usage: [ppAll,params] = preprocPipeline(S,ppSeq,Opts)
% 
% Preprocess a pipeline of preproc<X> functions. 
% 
% Inputs: 
%     S : the stimulus to be preprocessed, provided as a STRFlab "Stimulus"
%         or "PreprocessedStimulus" class 
% ppSeq : cell array, sequence of preprocessing steps, with alternate
%         entries naming the function to be called and the preset argument
%         number for the parameters to use. For example: 
%           {'preprocWavelets_grid',1,'preprocDownsample',1}
%  Opts : Option parameter array. fields are: 
%   .dbCache : vector of logical T/F, with one entry for each step in
%       ppSeq. Determines whether to store the result of each preprocessing
%       stage. A single true value stores only the last stage. [default:
%       false]
%   .concat : vector of logical T/F values, as .dbCache, which determines
%       whether to combine multi-part stimuli after each preprocessing
%       stage (movie stimuli must often be processed in parts to save
%       memory, until preprocessing steps sufficiently reduce the
%       dimensionality from pixel space to <whatever space>). [default:
%       false]
%   .Is_Overwrite : T/F, whether to overwrite extant preprocessed stimuli
%       in the database
%   .db : mlabSTRFdb instance; the database in which to store / look for
%       stimuli & preprocessed stimuli [default: blank call to mlabSTRFdb]
%   .sDir : directory in which to store stages of preprocessing [default:
%       current directory (pwd)] 
%   .tmpDir : directory in which to store temporary files for running on
%       the cluster [default '.'] 
%   .clusterOpts : parameters to send job to cluster. Not at all
%       general,kind of a mess. Needs work to be general. For GLab slurm
%       cluster, provide this as a struct, with fields:
%         .clusterFn = 'slurm_sbatch';
%         .jobParams = (normal slurm job params struct: .out,.err,.memory)
%       See preprocStep.m for how this actually sends jobs to slurm.
% 
% ML 2013.03.19

% TO DO: 
%   .preprocBoundaryCurvature
%   .preprocSceneDepthNormals
% 

% Default options
dOpts.dbCache = false;
dOpts.concat = false;
dOpts.Is_Overwrite = false;
dOpts.db = [];
dOpts.sDir = pwd; % Issue a warning about this? 
dOpts.tmpDir = '.';
dOpts.clusterOpts = []; % optional cluster parameters
% Fill default options
if ~exist('Opts','var')
    Opts = struct;
end
% Check on stimulus
if ischar(S)
    % Stimulus provided as .mat file w/ stimulus params saved
    % Stim params MUST be in variable "sParams"!
    tmp = load(S);
    S = Stimulus([],tmp.sParams);
    % S = S.dbGet; %(?)
end
Opts = defaultOpt(Opts,dOpts);
% Check on saving / overwriting / concatenation options
nSteps = length(ppSeq)/2;
if length(Opts.dbCache) == 1;
    orig = Opts.dbCache;
    Opts.dbCache = false(1,nSteps);
    Opts.dbCache(end) = orig;
end
if length(Opts.concat) == 1;
    orig = Opts.concat;
    Opts.concat = false(1,nSteps);
    Opts.concat(end) = orig;
end
if length(Opts.Is_Overwrite) == 1;
    Opts.Is_Overwrite = repmat(Opts.Is_Overwrite,1,nSteps);
end

% Separate parameter inputs to nSeqs different pipelines
ppSeqs = preprocSeparatePipelines(ppSeq);
nSeqs = length(ppSeqs);
% Run each param sequence 
ppAll = cell(nSeqs,1);
params = cell(nSeqs,1);
for iPP = 1:nSeqs
    %fprintf('%s :: %s :: %s\n',S.exp,S.StimClass,S.extra.trnval)
    %disp(ppSeqs{iPP})
    % Create param struct for this pipeline
    params = preprocBuildPipeline(ppSeqs{iPP},Opts.dbCache,Opts.Is_Overwrite,Opts.concat);
    % Create preprocStep for first set, let it loose
    ppStep = preprocStep(params.class,S,params,Opts.db,Opts.sDir,Opts.tmpDir);
    [ppAll{iPP},pp{iPP}] = ppStep.run(Opts.clusterOpts);
end

if length(ppAll)==1
    ppAll = ppAll{1};
    params = pp{1};
end
varargout{1} = ppAll;
if nargout>1
    varargout{2} = pp;
end
% Done! Easy as pie!