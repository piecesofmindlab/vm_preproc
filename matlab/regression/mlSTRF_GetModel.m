function varargout = mlSTRF_GetModel(WhichModel,ModelParamDir)
% Usage: [S,P] = mlSTRF_GetModel(WhichModel,ModelParamDir)
% 
% Gets model parameters for models. 
% Inputs: 
% WhichModel is a string that contains a unique identifier for a model,
%   often composed of a readable string, numbered parameters, and sometimes
%   other itelligible fields (e.g. the number of pixels to which a model
%   was resized before preprocessing it further). 
% 
% ModelParamDir is a string file directory name; defaults to 
%   '/auto/k6/mark/BVP_ModelParams/'
% RespOrder is string ('mean' or 'unwrapped') that determines whether to
%   predict whole (unwrapped) validation data and then average or not 
% 
% Outputs:
% S = stimulus design matrix 
% P = struct array of preprocessing parameters
%
% ML 2012.12
% Updated 2012.12.17 from mlSTRF_GetModel_BVPpilot3

if ~exist('ModelParamDir','var')
    ModelParamDir = '/auto/k6/mark/BVP_ModelParams/';
end

if any(strfind(WhichModel,'+'))
    % Split string at "+"
    WhichModel = regexp(WhichModel,'[^+]*','match');
    % Recursive call to concatenate models
    S.trn = [];
    S.val = [];
    P = cell(1,length(WhichModel));
    for iM = 1:length(WhichModel)
        [Stmp,Ptmp] = mlSTRF_GetModel(WhichModel{iM},ModelParamDir);
        S.trn = [S.trn,Stmp.trn];
        S.val = [S.val,Stmp.val];
        P{iM} = Ptmp;
    end
else
    switch WhichModel
        % TO DO: Generalize storage of parameters in models, such that all
        % have a variable of a given name that is to be used as the regression
        % design matrix (X), as well as any necessary meta-data.
        % As of 2012.04.16: All models should store "Spreproc" (design matrix)
        % and "params" (struct array with
        case 'PhysOnly'
            S.trn = []; %zeros(1200,1);
            S.val = []; %zeros(900,1);
            P.Descr = 'Physiological noise only';
            P.fTit = 'PhysNoise';
            P.AxLabel = Descr;
            P.ExtraSave = {'Descr','fTit','AxLabel'};
        otherwise
            try
                fprintf('Attempting default load!\n');
                S.trn = load([ModelParamDir WhichModel '_Trn.mat'],'Spreproc');
                S.trn = S.trn.Spreproc;
                %S.val = load([ModelParamDir WhichModel '_Val' RespOrderStr '.mat'],'Spreproc');
                S.val = load([ModelParamDir WhichModel '_Val.mat'],'Spreproc');
                S.val = S.val.Spreproc;
                try
                    % Parameters (assumed to be constant btw. Trn & Val
                    P = load([ModelParamDir WhichModel '_Trn.mat'],'params');
                    P = P.params;
                catch
                    P = struct;
                    disp('No parameters loaded!')
                end
            catch
                error('Failed! Model not found / not ready yet!');
            end
    end
end
% Output
varargout{1} = S;
if nargout==2
    varargout{2} = P;
end