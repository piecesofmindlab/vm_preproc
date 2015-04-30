function ppSeqs = preprocSeparatePipelines(ppSeq)
% Usage: ppSeqs = preprocSeparatePipelines(ppSeq)
% 
% Split one ppSeq with multiple arguments at one or more stages into
% separte preprocessing pipelines. 
% NOTE: This ONLY splits up cell arrays specifying preprocessing parameters
% into other cell arrays; see also preprocBuildPipeline.m to convert a
% cell array into a struct of actual parameters.
% 

ppFn = ppSeq(1:2:end);
ppArg = ppSeq(2:2:end);
% Create separate pipelines to incorporate all args in ppArg
O = cell(1,length(ppArg)); 
[O{:}] = ndgrid(ppArg{:});
O = cellfun(@(x) x(:),O,'uni',false);
ppArg = cat(2,O{:});

nSeqs = size(ppArg,1);
nElements = length(ppSeq);
ppSeqs = cell(nSeqs,1);
for iSeq = 1:nSeqs;
    ppSeqs{iSeq} = cell(1,nElements);
    ppSeqs{iSeq}(1:2:end) = ppFn;
    ppSeqs{iSeq}(2:2:end) = num2cell(ppArg(iSeq,:));
end

