function varargout = preprocPCA(S,params)
% Usage: varargout = preprocPCA(S,params)
% 
% Take PCs of model.
% 
% Inputs: 
%   S : Model (time x channels)
%   params : struct array with fields: 
%       .method : 'variance' | 'fractionPCs' | 'nPCs'
%       .n : if 'variance', keep the number of PCs required to reach n
%           proportion of the variance (0<n<1)
%           if 'fractionPCs', keep that n * size(S,2) PCs (0<n<1)
%           if 'nPCs', keep n PCs
%           Code will keep all PCs if n > size(S,2)
%       .zScore : re-compute zscore on each column after reducing data
%           dimensionality. Default = true
%   
% Outputs: 
%   Spreproc : reduced-dimensionality version of S (t x nPCs)
%   params: same struct, but with the following fields added:
%       .means,.stds : new means/stds from optional zscoring
%       .V : principal components, V from [U,S,V] = svd(S))
%       .varPerPC,.varExp : variance & cumulative variance per PC
% 
% ML 2013.09.10

% Inputs
if ~exist('params','var')
    params = struct;
end
% Defaults
dParams.method = 'variance'; % 'nPCs'; % 'fractionPCs'; %
dParams.n = .95; % PCs that explain 95% of variance
dParams.zScore = true; % re-compute z score (& save means & stds)
% Fill defaults
params = defaultOpt(params,dParams);
if ~nargin
    varargout{1} = params;
    return
end
% Optimization?? is eig(C) faster than svd(S)?
% Check for model size
% [m,n] = size(S);
% % Compute covariance matrix
% if m>n
%     C = S'*S;
% else
%     C = S*S';
% end

if ~isfield(params,'V')
    % Compute SVD
    [~,s,v] = svd(S,0); % Use LANsvd??
    % Compute variance explained by each PC
    params.varPerPC = diag(s).^2/sum(diag(s).^2);
    params.varExp = cumsum(params.varPerPC);
    
    switch params.method
        case 'variance'
            n = find(params.varExp>=params.n);
            n = n(1);
        case 'fractionPCs'
            n = round(size(S,2)*params.n);
        case 'nPCs'
            n = params.n;
    end
    % Allow for "nPCs" to exceed number of columns in matrix
    n = min(n,size(v,2));
    params.V = v(:,1:n);
    params.varPerPC = params.varPerPC(1:n);
    params.varExp = params.varExp(1:n);
else
    params.varExp = zeros(size(params.V,2),1);
    for iPC = 1:size(params.V,2)
        % Reconstitute stimulus
        sApprox = S*params.V(:,1:iPC)*params.V(:,1:iPC)';
        params.varExp(iPC) = 1-(var(S(:)-sApprox(:))/var(S(:)));
    end
    params.varPerPC = [params.varExp(1);diff(params.varExp)];
end
% Re-constitute stimulus
Spreproc = S*params.V; % == params.U*params.S; 
if params.zScore
    [Spreproc,params.means,params.stds] = norm_std_mean(Spreproc);
end
% Output
varargout{1} = Spreproc;
if nargout>1
    varargout{2} = params;
end
% Done!