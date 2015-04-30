function [PS, params] = preprocWaveletsNonLinear(S, params)


if nargin<1
     params = preprocWavelets;
end

if ~isfield(params, 'nonLinOutExp')
     params.nonLinOutExp = 0.5;
end


if ~isfield(params, 'reduceChannels')
     params.reduceChannels = NaN;
end


if ~isfield(params, 'gainControl')
     params.gainControl = [];
end


if nargin<1
     params.class = 'preprocWaveletsNonLinear';
     PS = params;
     return
end


normalize_orig = params.normalize;
params.normalize = 0;

if params.show_or_preprocess
    if ~isempty(params.gainControl)
        if params.verbose, fprintf('Processing gain controls...\n'); end
        S = single(S);
        [lums cons] = getLumCon(S, params.gainControl);
        ssize = size(S);
        S = reshape(S, prod(ssize(1:2)), []);
        params.gainControl.lums = lums;
        params.gainControl.cons = cons;
        for ii=1:size(S,1)
            rs = S(ii,:);
            if isfield(params.gainControl, 'lumSimpleGC')
                rs = rs/255;
                if ~isnan(params.gainControl.lumSimpleGC)
                    rs = procSimpleGC(rs, lums, params.gainControl.lumSimpleGC);
                end
                if ~isnan(params.gainControl.conSimpleGC)
                    rs = procSimpleGC(rs, cons, params.gainControl.conSimpleGC);
                end
                rs = rs*255;
            else
                if ~isnan(params.gainControl.lumCapacitance)
                    rs = procRCcircuit(rs, lums, params.gainControl.lumCapacitance);
                end
                if ~isnan(params.gainControl.conCapacitance)
                    rs = procRCcircuit(rs, cons, params.gainControl.conCapacitance);
                end
            end
            S(ii,:) = rs;
            if params.verbose
                if mod(ii,50)==0, fprintf('.'); end
                if mod(ii,1000)==0, fprintf('%d/%d done.\n', ii, size(S,1)); end
            end
        end
        if params.verbose, fprintf(' done.\n'); end
        S = reshape(S, ssize);
    end
    
end

keyboard;
[PS, params] = preprocWavelets(S, params);

params.normalize = normalize_orig;

if params.show_or_preprocess    
    if params.verbose, fprintf('Processing static output nonlinearity...'); end
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



function out = procSimpleGC(rs, lums, params)

cmax = (1+params(2));

out = cmax*rs.^params(1)./(lums.^params(1)+params(2));

% normalizing
out = out-mean(out);
out = out/std(out);

% sigmoid
out = 1./(1+exp(-out));


function rr = procRCcircuit(ins, gs, capacitance)
global gCap gInput gConductance gNumSamples

gInput = ins;
gConductance = gs;
gNumSamples = length(gs);
gCap = capacitance;

[rr] = ode4(@RCcircuit, single(1:gNumSamples), single(0));


function dy = RCcircuit(t,y)
global gCap gInput gConductance gNumSamples

ti = floor(t)+1;
if ti>gNumSamples
    ti = gNumSamples;
end

dy(1) = 1/gCap*(gInput(ti) - gConductance(ti)*y(1));

