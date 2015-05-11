function preprocHoG_Wrapper(S,pp,sName)
% Usage: preprocHoG_Wrapper(S,pp,sName)
% 
% Wrapper to allow calls of preprocHoG via slurm

[m.Spreproc m.params] = preprocHoG(S,pp);
save(sName,'-struct','m','-v7.3')
