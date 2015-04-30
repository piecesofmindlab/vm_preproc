function [filts] = ares_vis1(aresmodel, filters)

Xtmp = zeros(51,size(aresmodel.minX,2));

for i = 1:size(aresmodel.minX,2)
    Xtmp(:,i) = [aresmodel.minX(i):((aresmodel.maxX(i)-aresmodel.minX(i))/50):aresmodel.maxX(i)]';
end

ufs = unique(cat(1,aresmodel.knotdims{:}));

for i = ufs'
    modelReduced = aresanovareduce(aresmodel, i); 
    pred(:,i) = arespredict(modelReduced, Xtmp);
end

pred = pred - aresmodel.coefs(1);

minpred = min(pred(:));
maxpred = max(pred(:));


f2 = figure;
set(f2, 'Position', [150 150 1000 500]);
colormap gray;

if ndims(filters) ==3
    sz = size(filters);
    filters = reshape(filters, [sqrt(sz(1)) sqrt(sz(1)) sz(2) sz(3)]);
end

sz = size(filters);
delays = sz(end-1);
filters = norm_std_mean(reshape(filters, [prod(sz(1:3)) sz(end)]));
filters = reshape(filters, sz);



filters = filters(:,:,:,ufs);

maxf = max(abs(filters(:)));

lines = size(ufs,1);

for ff = 1:lines
    for dd = 1:delays
        subplot(lines,delays+1,(ff-1)*(delays+1)+dd); imagesc(filters(:,:,dd,ff), [-maxf maxf]); axis image; axis off;  colormap gray;
            % if ff == 1
            %     title(['RTA: ' num2str(-dd+1)]);
            % else
            %     title([sprintf('RTC%s', num2str(filtidxs(ff-1))) ': ' num2str(-dd+1)]);
            % end
    end

    subplot(lines,delays+1,(ff-1)*(delays+1)+dd+1);
    % plot([0 1], [0 0])
    % hold on; plot([.5 .5], [-.5 .5]);
    hold on; plot(Xtmp(:,ufs(ff)), pred(:,ufs(ff)), 'LineWidth', 3); axis square;
    
    % hold on; plot([0 1], [0 w3(wsidx(ff),1)/abs(ws(ff))]);
    % hold on; plot([0 -1], [0 w3(wsidx(ff),2)/abs(ws(ff))]); axis image;

end

