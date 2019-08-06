function [filts] = preprocRTAC_filts_ica(strf, filtidxs)

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


lines = length(filtidxs);
covstart = 1;

maxw = max(abs(strf.w1(:)));
w = strf.w1 ./ maxw;

% [ws, wsidx] = sort(abs(w), 'descend');

f2 = figure;
set(f2, 'Position', [150 150 1000 500]);
colormap gray;

if ndims(strf.params.filters) ==3
    sz = size(strf.params.filters);
    strf.params.filters = reshape(strf.params.filters, [sqrt(sz(1)) sqrt(sz(1)) sz(2) sz(3)]);
end

sz = size(strf.params.filters);
delays = sz(end-1);
filters = norm_std_mean(reshape(strf.params.filters, [prod(sz(1:3)) sz(end)]));
filters = reshape(filters, sz);
maxf = max(abs(filters(:)));

if ~isequal(strf.params.nonlins(1), strf.params.nonlins(2))
    filters2(:,:,:,1) = filters(:,:,:,1);
    filters2(:,:,:,2:1+(sz(end)-2)/2) = filters(:,:,:,3:2+(sz(end)-2)/2);
    w2(1,1) = w(1); w2(1,2) = w(2);
    w2(2:1+(sz(end)-2)/2,1) = w(3:2+(sz(end)-2)/2);
    w2(2:1+(sz(end)-2)/2,2) = w(3+(sz(end)-2)/2:end);
else
    filters2 = filters(:,:,:,1:(sz(end))/2);
    w2(1:(sz(end))/2,1) = w(1:(sz(end))/2);
    w2(1:(sz(end))/2,2) = w(1+(sz(end))/2:end);
end


[ws, wsidx] = sort(max(abs(w2), [],2), 'descend');

for ii = 1:size(w2,1)
    if w2(wsidx(ii),1)<0
        w3(wsidx(ii),1) = w2(wsidx(ii),2);
        w3(wsidx(ii),2) = w2(wsidx(ii),1);
        ws(ii) = -ws(ii);
    else
        w3(wsidx(ii),1) = w2(wsidx(ii),1);
        w3(wsidx(ii),2) = w2(wsidx(ii),2);
    end
end

for ff = 1:lines
    for dd = 1:delays
        subplot(lines,delays+1,(ff-1)*(delays+1)+dd); imagesc(ws(ff).*filters2(:,:,dd,wsidx(ff)), [-maxf maxf]); axis image; axis off;  colormap gray;
            % if ff == 1
            %     title(['RTA: ' num2str(-dd+1)]);
            % else
            %     title([sprintf('RTC%s', num2str(filtidxs(ff-1))) ': ' num2str(-dd+1)]);
            % end
    end
    
    subplot(lines,delays+1,(ff-1)*(delays+1)+dd+1); 
    plot([-1 1], [0 0])
    hold on; plot([0 0], [-1 1])
    hold on; plot([0 1], [0 w3(wsidx(ff),1)/abs(ws(ff))]);
    hold on; plot([0 -1], [0 w3(wsidx(ff),2)/abs(ws(ff))]); axis image;
    
end

end
