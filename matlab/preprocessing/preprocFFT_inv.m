function [PS, params] = preprocFFT_inv(S, phases, params);

S = reshape(S, params.limsize);
phases = reshape(phases, params.limsize);

S = cat(2, S, fliplr(flipud( S(:,1:end-1) )) );
phases = cat(2, phases, fliplr(flipud( phases(:,1:end-1) )) );



params.class = 'preprocFFT';

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
