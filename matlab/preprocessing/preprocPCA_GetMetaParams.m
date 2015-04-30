function params = preprocPCA_GetMetaParams(ArgNum)
% Usage: params = preprocPCA_GetMetaParams(ArgNum)
% 
% Get numbered arguments for preprocPCA
% 
% ML 2013.09.30

params = preprocPCA;
params.class = 'preprocPCA';

% Special computation: 
switch ArgNum
    case 1
        % 95% variance: 
        params.method = 'variance'; % 'nPCs'; % 'fractionPCs'; %
        params.n = .95; % PCs that explain 95% of variance
        params.zScore = true; % re-compute z score (& save means & stds)
        params.useTrnParams = true;
    case 2
        params.method = 'nPCs';
        params.n = 100;
        params.zScore = true;
        params.useTrnParams = true;
    case 3
        % 99.9% variance: 
        params.method = 'variance'; % 'nPCs'; % 'fractionPCs'; %
        params.n = .999; % PCs that explain 95% of variance
        params.zScore = true; % re-compute z score (& save means & stds)
        params.useTrnParams = true;
        
end