function [s, s_stds, s_means] = norm_std_mean_bsx(s, s_stds, s_means);


divnum = 20;
snum = size(s,2);
chunksize = ceil(snum/divnum);

if ~exist('s_means', 'var')
	%% calculate mean
	s_means = mean(s, 1);
end

if ~exist('s_stds', 'var')
	%% calculate std
	if prod(size(s)) < 100000 | size(s,2) < 20
		s_stds = std(s, 0, 1);
	else % to avoid out of memory, calculate stds by chunks
		st = 1;
		for ii=1:divnum
			ed = min([snum st+chunksize-1]);
			s_stds(st:ed) = std(s(:,st:ed), 0, 1);
			st = st + chunksize;
		end
	end
end


%% offset for mean
s = bsxfun(@minus, s, s_means);



s_stds(find(s_stds==0)) = 1; % To avoid zero-division

%% normalize stds
s = bsxfun(@divide, s, s_stds);

