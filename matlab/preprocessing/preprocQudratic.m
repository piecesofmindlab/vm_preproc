function [PS, params] = preprocQuadratic(S, params)


if nargin<1
     params.class = 'preprocQuadratic';
end

if ~isfield(params, 'reduceClass')
    params.reduceClass = 'pca';
end

if ~isfield(params, 'numReducedDims')
     params.inputDims = 50;
end

if ~isfield(params, 'normalize')
    params.normalize = 1;
end

if nargin<1
     PS = params;
     return
end

%  get data
res = loadoneresult(params.preproc.cellct, params.preproc.arg);
ws = sum(abs(squeeze(res.strf.w1)),2);
[d wsi] = sort(ws, 'descend');
PP = res.strf.params;
PP.valid_w_index = wsi(1:params.numReducedDims);

PP = rmfield(PP, 'means');
PP = rmfield(PP, 'stds');

[S PP] = cashedPreproc(PP, S);
params.perproc.params = PP;
keyboard;

% expansion



if params.normalize
    if isfield(params, 'means') % Already preprocessed. Use the means and stds
        [PS] = norm_std_mean(PS, params.stds, params.means);
    else
        [PS, stds, means] = norm_std_mean(PS);
        params.means = means;
        params.stds = stds;
    end
end



function out = procSubtractive(rs, params)

k = params.timecourse;
rsa = conv2(rs, k, 'same');

out = rs - rsa;



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

