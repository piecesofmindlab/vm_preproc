function [stim, params] = preprocCharlesData(rawStim, params)
% function [stim, params] = preprocCharlesData(rawStim, params);
%
% A script for reading and processing Charles' data
%
% SEE ALSO: make3dgabor, preprocSpectra
% ====================


%%% Set up parameters
if ~exist('params','var')
    params = [];
end
params = setDefaultParameters(params);

if nargin<1 % just called to set the default set of parameters
    stim = params;
    return;
end


if ~isfield(params, 'cellid')
    error('preprocCharlesData: need to specify cellid.');
end

basedir = '/auto/data2/shinji/models/';

switch params.modelcode
    case 0
        fext = '_arg0466_D100_1c_20x20_min_weak.mat';
    case 1
        fext = '_arg0466_D100_1e_32x32-20x20_min_weak.mat';
    case 2
        fext = '_arg0466_D100_1c_white-32x32-20x20_min_weak.mat';
    case 3
        fext = '_arg0466_D100_1c_white-64x64-20x20_min_weak.mat';
    case 4
        fext = '_arg0466_D100_1d_32x32-20x20_min_weak.mat';
    case 5
        fext = '_arg0466_D100_1e_20x20_min_weak.mat';
    case 6
        fext = '_arg0466_D100_1e_32x32-20x20_min_weak.mat';
    case 7
        fext = '_arg0466_D100_1e_white-32x32-20x20_min_weak.mat';
    case 8
        fext = '_arg0466_D100_1e_white-64x64-20x20_min_weak.mat';
    case 9
        fext = '_arg0466_D100_1f_white-32x32-20x20_min_weak.mat';
    case 10
        fext = '_arg0466_D400_1f_white-32x32-20x20_min_weak.mat';

    case {11,13,15,17}
        fext = '_arg0466_D100_1c_white-32x32-20x20_min_weak.mat';
    case {12,14,16,18}
        fext = '_arg0466_D100_1e_white-32x32-20x20_min_weak.mat';

end

ctstr = sprintf('ct%04d',id2ct(params.cellid));

fname = [basedir ctstr fext];
params.fname = fname;

disp(['loading ' fname '...']);
load(fname);

disp('processing phase infomation...');
Z_th = get_th_angle(Z, params.amp_th);
Z_ff_th = get_th_angle(Z_ff, params.amp_th);

if params.modelcode<=10 && params.w_HR == 0
    stim = [Z_th Z_ff_th w' w_MAP_ff' w_ff_ff'];
elseif params.modelcode<=10 && params.w_HR == 1
    % half-rectify Ws
    disp('applying half-rectification for Ws...');
    ws = [w' w_MAP_ff' w_ff_ff'];
    ws = [ws -ws];
    ws(ws<0) = 0;
    stim = [Z_th Z_ff_th ws];
elseif params.modelcode>=11 && params.modelcode<=12
    stim = [Z_th Z_ff_th];    
elseif params.modelcode>=13 && params.modelcode<=14
    stim = [w' w_MAP_ff' w_ff_ff'];
elseif params.modelcode>=15 && params.modelcode<=18
    wp = w'; wn=-w';

    wpm = w_MAP_ff'; wnm=-w_MAP_ff';

    wpf = w_ff_ff'; wnf=-w_ff_ff';

    stim = [wp wn wpm wnm wpf wnf];

    stim(stim<0) = 0;
    if params.modelcode==17 || params.modelcode==18
        stim = [Z_th Z_ff_th stim];
    end
end

return


function dtphase = get_th_angle(Z, amp_th)

Z_phase = angle(Z)';
dtphase = [zeros(1,size(Z_phase,2)); diff(Z_phase,1,1)];
dtphase = dtphase+ -2*pi*sign(dtphase).*round(abs(dtphase)./(2*pi));

% set the threshold for low amplitude signals
gstd = std(abs(Z(:)));
mask = abs(Z)'<=amp_th*gstd;

dtphase(mask) = 0;


%---------------------------------------------------------------------
%  Default parameter settings
%---------------------------------------------------------------------

function params = setDefaultParameters(params)


if ~isfield(params, 'modelcode')
    params.modelcode = 0;
end

if ~isfield(params, 'amp_th')
    params.amp_th = 0.2;
end

if ~isfield(params, 'w_HR')
    params.w_HR = 0;
end

params.class = 'preprocCharlesData';

return;

