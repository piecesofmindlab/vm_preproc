function preprocHoN_Wrapper(S,pp,sName)
% Usage: preprocHoN_Wrapper(S,pp,sName)
% 
% Wrapper to allow calls of preprocHoN via slurm

[m.Spreproc m.params] = preprocHoN(S,pp);
save(sName,'-struct','m','-v7.3')
