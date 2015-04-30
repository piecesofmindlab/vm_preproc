function [PS, params] = preprocWaveletsNonLinear2(S, params)

% parameter setup

if nargin<1
    params = preprocWavelets;
end

if ~isfield(params, 'lumNormalization')
    params.lumNormalization = 0;
end

if ~isfield(params, 'nonLinOutExp')
    params.nonLinOutExp = 1.0;
end

if ~isfield(params, 'divisiveNormalization')
    params.divisiveNormalization = NaN;
end


if nargin<1
    params.class = 'preprocWaveletsNonLinear2';
    PS = params;
    return
end


% luminance normalization
if params.show_or_preprocess
    lmode = params.lumNormalization;
    % luminance normalization
    if lmode == 1 || lmode==2
        ssize = size(S);
        S = reshape(S, size(S,1)*size(S,2), []);
        S = single(S);
        Smean = nanmean(S,1);
        if lmode==2
            Smean = [Smean(1) Smean(1:end-1)];
        end
        Smean = ones(size(S,1),1)*Smean;
        S = S - Smean;
        mm = min(Smean(Smean(:)>0));
        Smean(Smean==0)=mm;
        S = S ./ Smean;
        S = reshape(S, ssize); % back to the original shape
    end
    if lmode==3
        if params.verbose
            disp('Normalizing luminance and contrast...');
        end
        ssize = size(S);
        S = reshape(S, size(S,1)*size(S,2), []);
        S = single(S);
        Smean = nanmean(S,1);
        Sstd = nanstd(S,[],1);
        Smat = ones(size(S,1),1)*Smean;
        S = S - Smat;
        Smat = ones(size(S,1),1)*Sstd;
        mm = min(Sstd(Sstd(:)>0));
        Smat(Smat==0)=mm;
        S = S ./ Smat;
        S = reshape(S, ssize); % back to the original shape
    end
    if lmode==4
        if params.verbose
            disp('Normalizing luminance and RMS contrast...');
        end
        ssize = size(S);
        S = reshape(S, size(S,1)*size(S,2), []);
        S = single(S);
        Smean = nanmean(S,1);
        Sstd = nanstd(S,[],1);
        Smat = ones(size(S,1),1)*Smean;
        S = S - Smat;
        Smat = ones(size(S,1),1)*Sstd./Smat;
        mm = min(Sstd(Sstd(:)>0));
        Smat(Smat==0)=mm;
        S = S ./ Smat;
        S = reshape(S, ssize); % back to the original shape
    end
end
 

% wavelet preprocessing

normalize_orig = params.normalize;
params.normalize = 0;

if isfield(params, 'wclass')
  if params.verbose, fprintf('Calling %s...\n', params.wclass);end
  ptmp = params;
  ptmp.class = params.wclass;
  [PS, params] = feval(params.wclass, S, ptmp);

else
  if params.verbose, disp('Calling preprocWavelets...');end
  [PS, params] = preprocWavelets(S, params);
end

params.normalize = normalize_orig;


% nonlinearity
if params.show_or_preprocess


    % static nonlinearity

    if params.nonLinOutExp ~= 1.0
        if params.verbose, fprintf('--static nonlinearity: (%.1f)...', params.nonLinOutExp); end
        PS = sign(PS) .* abs(PS) .^ params.nonLinOutExp;
        if params.verbose, fprintf('done.\n'); end
    end


    % divisive nonlinearity
    if ~isnan(params.divisiveNormalization)
        if params.verbose, fprintf('--divisive normalization: (%.1f)...', params.divisiveNormalization); end
        divsigma = params.divisiveNormalization;

        if isfield(params, 'divsum_matrix')
            divsum_matrix = params.divsum_matrix;
        else
            cs = params.gaborparams(8,:)==0; % only complex type
            wstd = std(PS, [], 1);
            valids = cs & wstd;
            divsum_matrix = zeros(1,size(PS,2), 'single');
            divsum_matrix(valids) = 1./(wstd(valids));
            divsum_matrix = divsum_matrix/length(find(valids));
            params.divsum_matrix = divsum_matrix;
        end
        divsum = sum(PS.* (ones(size(PS,1),1, 'single')*divsum_matrix), 2);

        PS = PS./ (divsigma + divsum * ones(1,size(PS,2), 'single'));
        if params.verbose, fprintf('done.\n'); end
    end

    if params.normalize
        if isfield(params, 'means') % Already preprocessed. Use the means and stds
            [PS] = norm_std_mean(PS, params.stds, params.means);
        else
            [PS, stds, means] = norm_std_mean(PS);
            params.means = means;
            params.stds = stds;
        end
    end

end


params.class = 'preprocWaveletsNonLinear2';


