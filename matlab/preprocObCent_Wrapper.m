function preprocObCent_Wrapper(S,pp,sName)
% Usage: preprocObCent_Wrapper(S,pp,sName)
% 
% Wrapper to allow calls of preprocHoG via slurm

[m.Spreproc m.params] = preprocObCent(S,pp);
save(sName,'-struct','m','-v7.3')
