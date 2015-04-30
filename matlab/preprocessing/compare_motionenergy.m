% Script to compare to motion energy filters (using Shinji's code)
addpath('shinji')

param = preprocWavelets_phase;
param.phasemode = 6;
param.fdivisions = 2;
param.vdivisions = 2;
param.normalize = 0;

data_root = '../data/BBCmotion/whiteframes';
num_chunks = 80;
cons_chunks=1;

% size of each movie chunk
imsz=360;
imszt=48;
BUFF=4;

sz = 32;
batch_size = 10;

[out, out_params] = preprocWavelets_phase(randn(sz,sz,imszt),param);
channels = out_params.nChan;

OUT = zeros(channels,imszt*batch_size*num_chunks);

ind = 0;
for chunk = 1:num_chunks
    F=load_movie(chunk,cons_chunks,imszt,data_root,imsz);
    for batch = 1:batch_size
        row=BUFF+ceil((imsz-sz-(2*BUFF))*rand);
        col=BUFF+ceil((imsz-sz-2*BUFF)*rand);
        X=F(row:row+sz-1,col:col+sz-1,:);
    	OUT(:,1+ind*imszt:(ind+1)*imszt) = transpose(preprocWavelets_phase(X,param));
        ind = ind + 1;
    end
end

save data/compare_motionenergy.mat OUT param data_root sz imszt channels

%%

a_thresh = .1;

channels = size(OUT,1);
avalind = OUT(1:2:end,:)>a_thresh;
avalind = and(avalind, [false(size(avalind,1),1) avalind(:,1:end-1)]);
dtphase = [OUT(2:2:end,1) diff(OUT(2:2:end,:),1,2)];
dtphase = dtphase+ -2*pi*sign(dtphase).*round(abs(dtphase)./(2*pi));
%%
%chan_inds = 601:700;
rinds = randperm(712);
chan_inds = rinds(1:100);
% plot a bunch of 2d histograms

phase_edge = linspace(-pi,pi,32);

figure(1)
k=0;
for ind = chan_inds
    k = k+1;
    subplot(10,10,k)
    hist(dtphase(ind,avalind(ind,:)),31)
end

figure(2)
k=0;
for ind = chan_inds
    k = k+1;
    subplot(10,10,k)
    hist(OUT(2*(ind-1)+1,avalind(ind,:)),31)
end

figure(3)
k=0;
for ind = chan_inds
    k=k+1;
    % amplitude vs. dphase
    subplot(10,10,k)
    log_amp = log(OUT(2*(ind-1)+1,avalind(ind,:)));
    amp_edge = linspace(0,.7*max(log_amp),32);
    H = hist2d([log_amp.', dtphase(ind,avalind(ind,:)).'],amp_edge,phase_edge);
    imagesc(flipud(H)), colormap(gray)
    axis off
    %set(gca,'YScale','log','YTick', .5*[5 10 20 30]);
    %set(gca,'XTick', [5 10 20 30]);
end


figure(4)
ind = 32;
subplot(1,3,1)
hist(OUT(2*(ind-1)+1,avalind(ind,:)),31)
title('amplitude distribution')
subplot(1,3,2)
hist(dtphase(ind,avalind(ind,:)),31)
title('phase deriviative distribution')
subplot(1,3,3)
log_amp = log(OUT(2*(ind-1)+1,avalind(ind,:)));
amp_edge = linspace(0,.7*max(log_amp),32);
H = hist2d([log_amp.', dtphase(ind,avalind(ind,:)).'],amp_edge,phase_edge);
imagesc(flipud(log(H))), colormap(gray)
axis off
title('joint amp vs. dphasedt')
xlabel('dphasedt')
ylabel('log amp')
%%
C = zeros(712,712);
for i = 1:712
    for j = i:712
        cc = corrcoef(dtphase(i,avalind(i,:)&avalind(j,:)),OUT(2*(j-1)+1,avalind(i,:)&avalind(j,:)));
        C(i,j) = cc(1,2);
        cc = corrcoef(dtphase(j,avalind(i,:)&avalind(j,:)),OUT(2*(i-1)+1,avalind(i,:)&avalind(j,:)));
        C(j,i) = cc(1,2);
    end
end

figure(5)
imagesc(C,[-1, 1])
colorbar()

%%
figure(6)
Hnorm = diag(1./max(H,[],2))*H;
imagesc(flipud(log(Hnorm))), colormap(gray)