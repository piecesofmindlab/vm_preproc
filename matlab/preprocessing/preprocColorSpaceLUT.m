function [stim, params] = preprocColorSpaceLUT(rawStim, params)
% function [stim, params] = preprocHybrid(rawStim, params);
%
% A script for processing stimuli using multiple models
%
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

if isstr(rawStim), rawStim = refmat_recover(rawStim); end

% color-space conversion
disp(['Converting color space ... [' params.colorconv ']']);

% idstr = getIDstimparams(rawStim, params);
% tmpdir = '/auto/data/shinji/preptmp/color/';
% cashedfile = [tmpdir idstr '.mat'];
% if exist(cashedfile, 'file')
%     disp(['loading cashed color data: ' cashedfile]);
%     load(cashedfile, 'cstim');
% else


luts=calcLUT(params);
framenum = size(rawStim,4);
chnum = length(params.colorchannels);
cstim=zeros(size(rawStim,1)*size(rawStim,2),framenum,chnum,'single');
for ii=1:framenum;
    im=double(rawStim(:,:,:,ii));
    imi=im(:,:,1)+im(:,:,2)*256+im(:,:,3)*256^2+1;
    cstim(:,ii,:)=single(luts(imi(:),:));
    progressdot(ii,500,10000,framenum);
end
cstim=reshape(cstim,size(rawStim,1),size(rawStim,2),framenum,chnum);


% cstim = zeros(size(rawStim,1),size(rawStim,2),size(rawStim,4),length(params.colorchannels),'single');
% 
% for ii=1:size(rawStim,4)
%     tim = squeeze(rawStim(:,:,:,ii));
%     tim = gammacorrect(tim, params.gamma);
%     cim = colorspace2(params.colorconv, tim);
%     cstim(:,:,ii,:) = single(cim(:,:,params.colorchannels));
%     if mod(ii,500)==0
%         fprintf('.');
%         if mod(ii,10000)==0
%             fprintf('%d/%d done.\n', ii, size(rawStim,4));
%         end
%     end
% end
%check_and_wait();

%     disp(['saving cashed color data: ' cashedfile]);
%     save(cashedfile, 'cstim');
%
% end
clear rawStim;
disp('done.');


% structural preprocessing
% if numel(cstim)>100*100*100000 % to save memory, store some variables into HDD.
%     stim = [];
%     for ci=1:length(params.colorchannels)
%         sstr{ci} = refmat_store(cstim(:,:,:,ci));
%     end
%     clear cstim;
%     
%     for ci=1:length(params.colorchannels)
%         [tstim p] = feval(params.PP.class, sstr{ci}, params.PP);
%         stim = cat(2,stim, tstim);
%     end
%     for ci=1:length(params.colorchannels)
%         refmat_clear(sstr{ci});
%     end
% else
    if length(params.colorchannels)>=2
        stim = [];
        for ci=1:length(params.colorchannels)
            [tstim p] = feval(params.PP.class, cstim(:,:,:,ci), params.PP);
            stim = cat(2,stim, tstim);
        end
    else
        [stim p] = feval(params.PP.class, cstim, params.PP);
    end
% end

params.PP = p;


% normalize std and mean if requested
if params.normalize
    if isfield(params, 'means') % Already preprocessed. Use the means and stds
%         global s; s = stim; clear stim; % a trick to modify stim without copying it
%         [stds, means] = norm_std_mean_global(params.stds, params.means);
%         stim = s; clear s;
        stim = norm_std_mean(stim, params.stds, params.means);
    else
%         global s; s = stim; clear stim; % a trick to modify stim without copying it
%         [stds, means] = norm_std_mean_global();
%         stim = s; clear s;
        [stim stds means] = norm_std_mean(stim);
        params.means = means;
        params.stds = stds;
    end
end

params.nChan = size(stim,2);

return


function im = gammacorrect(im, g)

im = double(im)/255;
if g~=1.0
    im = im.^g;
end

return

function luts=calcLUT(params)

cdir = '/auto/data/shinji/tmp/';
sid=getIDstring(params);
cfile=[cdir 'lut_' sid '.mat'];
if exist(cfile,'file')
    fprintf('Loading LUT file: %s\n', cfile);
    load(cfile);
    return
end

fprintf('Calculating LUT...');

[gi ri]=meshgrid(0:255,0:255);
bi=zeros(256,256);

luts=zeros(256,256,256,length(params.colorchannels));
for b=1:256;
    rgb=cat(3,ri,gi,bi+b-1);
    rgb = double(rgb)/255;
    if params.gamma~=1.0
        rgb = rgb.^params.gamma;
    end
    lch=colorspace2(params.colorconv,rgb);
    luts(:,:,b,:)=lch(:,:,params.colorchannels);
end
luts=reshape(luts,[],length(params.colorchannels));

save(cfile,'luts');

fprintf('done.\n');

return


function idstr = getIDstimparams(stim, params)

t1=ceil(size(stim(:))/233);
t2=ceil(size(stim(:))/59);

s=stim([1:t1:end 1:t2:end]);

a.s = s;
a.params = params;
a.size = size(stim);

idstr = getIDstring(a);

return

%---------------------------------------------------------------------
%  Default parameter settings
%---------------------------------------------------------------------

function params = setDefaultParameters(params)

if ~isfield(params, 'normalize')
    params.normalize = 1;
end

if ~isfield(params, 'colorconv')
    params.colorconv = 'YUV<-RGB';
end

if ~isfield(params, 'colorchannels')
    params.colorchannels = 1;
end

if ~isfield(params, 'gamma')
    params.gamma = 1.0;
end


params.class = 'preprocColorSpaceLUT';

return;

