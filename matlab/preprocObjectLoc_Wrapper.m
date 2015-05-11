function preprocObjectLoc_Wrapper(S,pp,sName)
% Usage: preprocObjectLoc_Wrapper(S,pp,sName)
% 
% Wrapper to allow calls of preprocObjectLoc via slurm

[m.Spreproc m.params] = preprocObjectLoc(S,pp);
save(sName,'-struct','m','-v7.3')
