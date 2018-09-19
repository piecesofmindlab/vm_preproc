function [stim, params] = preprocSFA(rawStim, params)
% function [stim, params] = preprocSFA(rawStim, params);
%  Preprocessing by pre-learned basis using Slow Feature Analysis


% Settings for parameters

if nargin<2
    params.class = 'preprocSFA';
end


if ~isfield(params, 'numUnits')
    params.numUnits = 50;
end

if ~isfield(params, 'divs')
    params.divs = [1 3 6];
end

if ~isfield(params, 'modelcode')
    params.modelcode = NaN;
end

if ~isfield(params, 'overlap')
    params.overlap = 1;
end

if ~isfield(params, 'normalize')
    params.normalize = 1;
end

if nargin<2
    stim = params;
    return;
end

ssize = size(rawStim);

rects = getPyramidRects(ssize(1:2), params.divs, params.overlap);

params.rects = rects;
params.nChan = size(rects,2)*params.numUnits;


% load a sfa model
[hdl sfamodel] = sfa_load(params.modelcode);
params.sfamodel = sfamodel;

% calculate sfa outputs
stim = zeros(size(rawStim,3), params.nChan, 'single');
for ri=1:size(rects,2);
    fprintf('calculating region %d/%d...\n', ri, size(rects, 2));
    thismov = rawStim(rects(3,ri):rects(4,ri),rects(1,ri):rects(2,ri),:);
    thismov = imresize(thismov, [sfamodel.params.h sfamodel.params.w]);
    thismov = reshape(thismov, [], size(thismov,3))';
    if sfamodel.params.t == 2
        thismov = cat(2, thismov, thismov([2:end end],:));
    end
    if sfamodel.params.t == 3
        thismov = cat(2, thismov([1 1:end-1],:), thismov, thismov([2:end end],:));
    end
    thismov = single(thismov)/255;
    ss = sfa_execute(hdl, thismov, 0, params.numUnits);
    stim(:,(1:params.numUnits)+(ri-1)*params.numUnits) = ss;
end



if params.normalize
    if isfield(params, 'means') % Already preprocessed. Use the means and stds
        global s; s = stim; clear stim; % a trick to modify stim without copying it
        norm_std_mean_global(params.stds, params.means);
        stim = s; clear s;
    else
        global s; s = stim; clear stim; % a trick to modify stim without copying it
        [stds, means] = norm_std_mean_global();
        stim = s; clear s;
        params.means = means;
        params.stds = stds;
    end
end

