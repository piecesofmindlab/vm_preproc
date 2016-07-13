function pp = preprocUpsampleImageTime_GetMetaParams(Arg)
% Usage: params = preprocWavelets_grid_GetMetaParams(Arg)
% 
% Returns params for numbered preprocWavelets_grid presets. 1 and 2 are
% SN's parameters of choice for the natural movie stimuli in Nishimoto et
% al 2011

pp = preprocUpsampleImageTime;
pp.argNum = Arg;
pp.class = 'preprocUpsampleImageTime';
switch Arg
    case 1
        pp = pp; % This is just a dumb placeholder.
end