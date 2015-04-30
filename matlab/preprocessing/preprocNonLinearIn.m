function varargout = preprocNonLinearIn(S,params)
% Usage: [Spreproc,params] = preprocNonLinearIn(S,params)
%
% Preprocess luminance / color gain control. This is a disaster. There are
% several undocumented / absent functions referenced. Also SN says this did
% not help w/ fMRI OR neurons based on 2011 papers. So fuck it.  Abandoned
% 2013.03.20 for possible resurrection in the future.
%
% preprocWaveletsNonLinear by SN 200X?
% Separated in to In/Out and (incompletely) modified by ML 2013.03.20

error('Unfinished!')

% Default parameters
dParams.class = 'preprocNonLinearIn';
dParams.verbose = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dParams.gainControl = []; % Options? Examples?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% call nested parameters
if isfield(params,'PP')
    % Change to Spp for standard variable naming
    [S,params] = feval(params.PP.class,S,params.PP);
end

if ~isempty(params.gainControl)
    if params.verbose
        fprintf('Processing gain controls...\n'); 
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% WTF does this do?
    if ifstr(S)
        S = refmat_recover(S); 
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S = single(S);
    [lums cons] = getLumCon(S, params.gainControl); % No idea what this does
    ssize = size(S);
    S = reshape(S, prod(ssize(1:2)), []);
    params.gainControl.lums = lums;
    params.gainControl.cons = cons;
    means = mean(S(:));
    S = S - means;
    for ii=1:size(S,1)
        rs = S(ii,:);
        if isfield(params.gainControl, 'lumSimpleGC')
            rs = rs/255;
            if ~isnan(params.gainControl.lumSimpleGC)
                rs = procSimpleGC(rs, rs, params.gainControl.lumSimpleGC);
            end
            if isfield(params.gainControl, 'subtr') && ~isempty(params.gainControl.subtr)
                rs = procSubtractive(rs, params.gainControl.subtr);
            end
            if ~isnan(params.gainControl.conSimpleGC)
                rs = procSimpleGC(rs, cons, params.gainControl.conSimpleGC);
            end
            rs = rs*255;
        else
            if ~isnan(params.gainControl.lumCapacitance)
                rs = procRCcircuit(rs, lums, params.gainControl.lumCapacitance);
            end
            if isfield(params.gainControl, 'subtr') && ~isnan(params.gainControl.subtr)
                rs = procSubtractive(rs, params.gainControl.subtr);
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
    S = S + means;
    if params.verbose, fprintf(' done.\n'); end
    S = reshape(S, ssize);
end

varargout{1} = S;
if nargout>1
    varargout{2} = params;
end

function out = procSimpleGC(rs, lums, params)
%
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

