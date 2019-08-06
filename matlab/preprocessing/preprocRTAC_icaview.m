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

[ws, wsidx] = sort(abs(w), 'descend');

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

for ff = 1:lines
    for dd = 1:delays
        subplot(lines,delays,(ff-1)*delays+dd); imagesc(w(wsidx(ff)).*filters(:,:,dd,wsidx(ff)), [-5 5]); axis image; axis off; 
            % if ff == 1
            %     title(['RTA: ' num2str(-dd+1)]);
            % else
            %     title([sprintf('RTC%s', num2str(filtidxs(ff-1))) ': ' num2str(-dd+1)]);
            % end
    end
end

end