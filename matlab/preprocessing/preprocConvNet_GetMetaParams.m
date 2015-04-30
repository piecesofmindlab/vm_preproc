function params = preprocDownsample_GetMetaParams(Arg)
% Usage: params = preprocConvNet_GetMetaParams(Arg)
% 
% Dummy placeholder; all ConvNet preprocessing thus far has been done by Pulkit Agarwal
% 
% ML 2014.02.19

params.class = 'preprocConvNet';

% switch Arg
%     case 1
%         % Simple box average
%         params.dsType = 'box';
%         params.imHz = 15;     % These two values will be overwritten by stimulus 
%         params.sampleSec = 2; % parameters in Stimulus class input to preprocDownsample
%         params.frameshifts = []; % empty = no shift
%         params.gaussParams = []; %[1,2]; % sigma,mean
%     case 2
%         % Gaussian downsampling
%         params.dsType = 'gauss';
%         params.imHz = 15;
%         params.sampleSec = 2;
%         params.frameshifts = []; % empty = no shift
%         params.gaussParams = [1,2]; % mean, standard deviation
%     case 3
%         % Max downsampling 
%         params.dsType = 'max';
%         params.imHz = 15;
%         params.sampleSec = 2;
%         params.frameshifts = []; % empty = no shift
%         params.gaussParams = []; %[1,2]; % sigma,mean
%     otherwise
%         error('Unknown parameter configuration!');
% end
