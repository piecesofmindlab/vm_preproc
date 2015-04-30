function [stim PP] = preproc_downsample(stim, PP, StimParams, expinfo)

if isfield(PP, 'normalize') % override mean-std normalizations
    PPnormalize = PP.normalize;
    PP.normalize = 0;
end

if ~isfield(StimParams, 'downsampleparams')
    dsparams.class = 'box';
else
    dsparams = StimParams.downsampleparams;
end

im_per_tr = expinfo.TRsec*expinfo.imhz;


% preprocess stimuli
[stim, PP] = feval(PP.class, stim, PP);


% downsample the preprocessed stimuli
switch dsparams.class
    case 'box'
        fs=1;
        if isfield(dsparams,'frameshifts')
          fprintf('shifting %d frames...\n', dsparams.frameshifts);
          stim=circshift(stim,[dsparams.frameshifts 0]);
        end
        tframes = floor(size(stim,1)/im_per_tr)*im_per_tr;
        stim = stim(1:tframes,:);
        stim = reshape(stim, im_per_tr, [], size(stim,2));
        stim = reshape(mean(stim,1), [], size(stim,3));
    case 'non'
        % do nothing
    case 'max'
        tframes = floor(size(stim,1)/im_per_tr)*im_per_tr;
        stim = stim(1:tframes,:);
        stim = reshape(stim, im_per_tr, [], size(stim,2));
        stim = reshape(max(stim,[],1), [], size(stim,3));
    case 'gauss'
        ksigma = dsparams.params(1);
        if ksigma~=0
            ki = -ksigma*2.5:1/im_per_tr:ksigma*2.5;
            k = exp(-ki.^2/(2*ksigma^2));
            stim = conv2(stim, k'/sum(k), 'same');
        end
        sonset = 7;
        if length(dsparams.params)>=2
            sonset = dsparams.params(2);
        end
        stim = stim(sonset:im_per_tr:end,:);
end


if isfield(PP, 'normalize') && PPnormalize
    if isfield(PP, 'means') % Already preprocessed. Use the means and stds
        [stim] = norm_std_mean(stim, PP.stds, PP.means);
    else
        [stim, stds, means] = norm_std_mean(stim);
        PP.means = means;
        PP.stds = stds;
    end
    
    PP.normalize = PPnormalize;
end

