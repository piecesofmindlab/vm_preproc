function [PS, params] = preprocWaveletsPowerPhase(S, params)


if nargin<1
     params = preprocWavelets;
end

if ~isfield(params, 'nonLinOutExp')
     params.nonLinOutExp = 0.5;
end

if ~isfield(params, 'phaseDivs')
     params.phaseDivs = 4;
end

if ~isfield(params, 'powerWeight')
     params.powerWeight = 0;
end


if ~isfield(params, 'reduceChannels')
     params.reduceChannels = NaN;
end

params.phasemode = 1;
params.phasemode_sfmax = params.sfmax+0.1;
%params.wrap_all = 1;

if nargin<1
     params.class = 'preprocWaveletsPowerPhase';
     PS = params;
     return
end


normalize_orig = params.normalize;
params.normalize = 0;

[PS, params] = preprocWavelets(S, params);

params.normalize = normalize_orig;

PS = reshape(PS, [size(PS,1) 2 size(PS,2)/2]);
f_true = squeeze(abs(PS(:,1,:)+PS(:,2,:)*i));
p_true = squeeze(angle(PS(:,1,:)+PS(:,2,:)*i));
p_true = mod(p_true, 2*pi);

ps = zeros(size(p_true,1), size(p_true,2), params.phaseDivs, 'single');
pbin = 2*pi/params.phaseDivs;
for ii=1:params.phaseDivs
    ps(:,:,ii) = (p_true>pbin*(ii-1) & p_true<=pbin*ii);
    if params.powerWeight
        ps(:,:,ii) = ps(:,:,ii).*f_true;
    end
end
PS = cat(2, f_true, reshape(ps, size(f_true,1), []));

keyboard;

if params.show_or_preprocess
    if params.verbose, fprintf('Processing output nonlinearity...'); end
    for ii=1:size(PS,2)
        PS(:,ii) = abs(PS(:,ii)).^params.nonLinOutExp.*sign(PS(:,ii));
    end
    if params.verbose, fprintf(' done.\n'); end

	if params.normalize
		if isfield(params, 'means') % Already preprocessed. Use the means and stds
			[PS] = norm_std_mean(PS, params.stds, params.means);
		else
			[PS, stds, means] = norm_std_mean(PS);
			params.means = means;
			params.stds = stds;
		end
	end

	if ~isnan(params.reduceChannels)
		orig_nch = size(PS,2);
 	    if isfield(params, 'reduceChannelsValidChannels') % Already preprocessed. Use valid channels.
		    v = params.reduceChannelsValidChannels;
	        PS = PS(:,v);
        else
			if ~isfield(params, 'stds')
				[d, stds, means] = norm_std_mean(PS);
			else
				stds = params.stds;
			end
            if params.reduceChannels < 1
	            maxstd = max(stds);
                v = find(stds >= maxstd*params.reduceChannels);
				PS = PS(:,v);
            else
				[d s] = sort(stds, 'descend');
				v = s(1:min([length(s) params.reduceChannels]));
				v = sort(v);
				PS = PS(:,v);
            end
			params.reduceChannelsValidChannels = v;
        end
		if params.verbose, fprintf('Trucated channels %d -> %d.\n', orig_nch, length(v)); end
        params.nChan = length(v);
    end

end


params.class = 'preprocWaveletsNonLinear';
