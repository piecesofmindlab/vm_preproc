function [Spreproc, params] = preprocFFTbins(S, params)
% Usage: [Spreproc, params] = preprocFFTbins(S, params)
dparams.class = 'preprocFFT';
dparams.screen_degrees = 21.32;
dparams.angle_bins = [0;360]; % nan = no filter by angle
dparams.freq_bins = [];
if nargin<1 % just called to set the default set of parameters
	PS = params;
	return;
end

disp('preprocFFT: preprocessing...');
PS = fft2(S);

PS = reshape(PS, [size(S,1)*size(S,2) size(S,3)]);

params.limsize = [size(S,1)  ceil((size(S,2)+1)/2)];
plim = prod(params.limsize);
PS = PS(1:plim,:);

PS = abs(PS)';

disp('done.');
