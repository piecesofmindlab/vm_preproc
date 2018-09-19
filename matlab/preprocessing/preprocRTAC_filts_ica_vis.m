function [filts] = preprocRTAC_filts_ica_vis(strf, filtidxs, maxeig)

%function [out, strf] = preprocRTAC_Vis(strf)
%
%  A visualizer of STRF preprocessed by preprocRTAC
%
% INPUT:
%          [strf] = strf model that was preprocessed by preprocWavelets3d
%
% OUTPUT:
%       [filtRTA] = a matrix of the RTA filter
%      [filtRTC1] = a matrix of the 1st Eigenvector of the RTC (1st RTC filter)
%      [filtRTC1] = a matrix of the 2nd Eigenvector of the RTC (2nd RTC filter)
%


if strf.params.covtime
    delays = (strf.params.covdelays + 1);
else
    delays = length(strf.delays);
end
lines = 0;
covstart = 1;
if strf.params.RTAC(1)
    RTA = strf.w1(1:(strf.params.covdelays + 1)*strf.params.covsz,:);
    lines = 1;
    covstart = (strf.params.covdelays + 1)*strf.params.covsz+1;
else
    RTA = zeros([strf.params.covsz delays]);
end

if strf.params.RTAC(2)
    lines = lines + 2;
    RTCsub = strf.w1(covstart:end,:);

    if strf.params.covtime
        idx2 =sub2ind([strf.params.covsz*(strf.params.covdelays + 1) strf.params.covsz*(strf.params.covdelays + 1)], strf.params.idxr, strf.params.idxc);
        RTC = squeeze(zeros([strf.params.covsz*(strf.params.covdelays + 1) strf.params.covsz*(strf.params.covdelays + 1)]));
        RTC(idx2) = RTCsub;
        if nargin == 1
            [u,s,v] = svd(RTC);
        else
            [u,s,v] = svds(RTC, maxeig);
        end
        delays = (strf.params.covdelays + 1);
    else
        
        idx2 =sub2ind([strf.params.covsz strf.params.covsz], strf.params.idxr, strf.params.idxc);

        for ii = 1:delays
            RTC = squeeze(zeros([strf.params.covsz strf.params.covsz]));
        
            RTC(idx2) = RTCsub(:,ii);

            RTC = RTC + tril(RTC', -1);

            [u(:,:,ii),s(:,:,ii),v(:,:,ii)] = svd(RTC);

        end
    end
else
    u = zeros([strf.params.covsz 2 delays]);
end



icaparams = eigwindowICA;

icasig = eigwindowICA(u, icaparams);

% W=PCF_ica(u');
% icasig = W*u';
% 
% icasig = W*u(:,unmixidxs)'

% W=KDICA(u');
% icasig = W*u';
% xx=u';
% yy = sqrtm(inv(cov(xx')))*(xx-repmat(mean(xx,2),1,size(xx,2)));
% [W,ss,vv] = svd((repmat(sum(yy.*yy,1),size(yy,1),1).*yy)*yy');
% 
% icasig = W*xx;
% [icasig] = fastica(u','verbose', 'off');

plotICs_big(icasig(filtidxs,:), [sqrt(strf.params.covsz) sqrt(strf.params.covsz) delays]);

filts = zeros([sqrt(strf.params.covsz) sqrt(strf.params.covsz) delays size(filtidxs,2)+1]);

filts(:,:,:,1) = reshape(RTA, [sqrt(strf.params.covsz) sqrt(strf.params.covsz) delays]);
cnt=2;
for ii=filtidxs
    filts(:,:,:,cnt) = reshape(icasig(ii,:), [sqrt(strf.params.covsz) sqrt(strf.params.covsz) delays]);
    cnt=cnt+1;
end

