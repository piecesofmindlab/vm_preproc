function [filts] = ares_vis2(aresmodel, filters, intonly)


if ndims(filters) ==3
    sz = size(filters);
    filters = reshape(filters, [sqrt(sz(1)) sqrt(sz(1)) sz(2) sz(3)]);
end

sz = size(filters);
delays = sz(end-1);
filters = norm_std_mean(reshape(filters, [prod(sz(1:3)) sz(end)]));
filters = reshape(filters, sz);

cnt = 1;
for ii = 1:size(aresmodel.knotdims,1)
    if size(aresmodel.knotdims{ii},2)==2
        interactions{cnt} = num2str(aresmodel.knotdims{ii});
        cnt=cnt+1;
    end
end

interactions = unique(interactions);

for ii = 1:size(interactions,2)
    interactions{ii} = str2num(interactions{ii});
end

nointeractions = setdiff(unique(cat(2,aresmodel.knotdims{:})), unique(cat(2,interactions{:})));

maxf = max(abs(filters(:)));

% for ff = 1:lines
%     for dd = 1:delays
%         subplot(lines,delays+1,(ff-1)*(delays+1)+dd); imagesc(filters(:,:,dd,ff), [-maxf maxf]); axis image; axis off;  colormap gray;
%     end
% 
%     subplot(lines,delays+1,(ff-1)*(delays+1)+dd+1);
%     % plot([0 1], [0 0])
%     % hold on; plot([.5 .5], [-.5 .5]);
%     hold on; plot(Xtmp(:,ufs(ff)), pred(:,ufs(ff)), 'LineWidth', 3); axis square;
%     
%     % hold on; plot([0 1], [0 w3(wsidx(ff),1)/abs(ws(ff))]);
%     % hold on; plot([0 -1], [0 w3(wsidx(ff),2)/abs(ws(ff))]); axis image;
% 
% end

lines = 2*size(interactions,2);

fc = 1:2:lines;

for ff = 1:size(interactions,2);
    
    figure(1)
    fff = fc(ff);
    for dd = 1:delays
        subplot(lines,delays+1,(fff-1)*(delays+1)+dd); imagesc(filters(:,:,dd,interactions{ff}(1)), [-maxf maxf]); axis image; axis off;  colormap gray;
    end
    
    for dd = 1:delays
        subplot(lines,delays+1,(fff)*(delays+1)+dd); imagesc(filters(:,:,dd,interactions{ff}(2)), [-maxf maxf]); axis image; axis off;  colormap gray;
    end
    
    modelReduced = aresanovareduce(aresmodel, interactions{ff});
    
    ind1 = interactions{ff}(1);
    ind2 = interactions{ff}(2);

    step1 = (aresmodel.maxX(ind1) - aresmodel.minX(ind1)) / 50;
    step2 = (aresmodel.maxX(ind2) - aresmodel.minX(ind2)) / 50;

    [X1,X2] = meshgrid(aresmodel.minX(ind1):step1:aresmodel.maxX(ind1), aresmodel.minX(ind2):step2:aresmodel.maxX(ind2));
    XX1 = reshape(X1, numel(X1), 1);
    XX2 = reshape(X2, numel(X2), 1);

    X = zeros(size(XX1,1), length(aresmodel.minX));
    
    X(:,ind1) = XX1;
    X(:,ind2) = XX2;
    for i = 1 : length(aresmodel.minX)
        if (i ~= ind1) && (i ~= ind2)
            X(:,i) = (aresmodel.maxX(i) - aresmodel.minX(i)) / 2;
        end
    end
     
    if intonly
        for iii = 1:size(modelReduced.knotdims,1)
            if size(modelReduced.knotdims{iii},2)==1
                modelReduced.coefs(iii+1)=0;
            end
        end
    end
    
    YY = arespredict(modelReduced, X);
    Y = reshape(YY, size(X1,1), size(X2,2));

    subplot(lines,delays+1,(fff)*(delays+1)+dd+1);
    % plot([0 1], [0 0])
    % hold on; plot([.5 .5], [-.5 .5]);
    imagesc(Y); axis square; axis off; colorbar
    
    figure(ff+1);
    surfc(X1, X2, Y);
end

% Xtmp = zeros(51,size(aresmodel.minX,2));
% 
% for i = 1:size(aresmodel.minX,2)
%     Xtmp(:,i) = [aresmodel.minX(i):((aresmodel.maxX(i)-aresmodel.minX(i))/50):aresmodel.maxX(i)]';
% end
% 
% ufs = unique(cat(1,aresmodel.knotdims{:}));
% 
% for i = ufs'
%     modelReduced = aresanovareduce(aresmodel, i); 
%     pred(:,i) = arespredict(modelReduced, Xtmp);
% end
% 
% pred = pred - aresmodel.coefs(1);
% 
% minpred = min(pred(:));
% maxpred = max(pred(:));
% 
% 
% f2 = figure;
% set(f2, 'Position', [150 150 1000 500]);
% colormap gray;
% 
% 
% 
% 
% 
% 
% 
% lines = size(ufs,1);
% 
% for ff = 1:lines
%     for dd = 1:delays
%         subplot(lines,delays+1,(ff-1)*(delays+1)+dd); imagesc(filters(:,:,dd,ff), [-maxf maxf]); axis image; axis off;  colormap gray;
%             % if ff == 1
%             %     title(['RTA: ' num2str(-dd+1)]);
%             % else
%             %     title([sprintf('RTC%s', num2str(filtidxs(ff-1))) ': ' num2str(-dd+1)]);
%             % end
%     end
% 
%     subplot(lines,delays+1,(ff-1)*(delays+1)+dd+1);
%     % plot([0 1], [0 0])
%     % hold on; plot([.5 .5], [-.5 .5]);
%     hold on; plot(Xtmp(:,ufs(ff)), pred(:,ufs(ff)), 'LineWidth', 3); axis square;
%     
%     % hold on; plot([0 1], [0 w3(wsidx(ff),1)/abs(ws(ff))]);
%     % hold on; plot([0 -1], [0 w3(wsidx(ff),2)/abs(ws(ff))]); axis image;
% 
% end

