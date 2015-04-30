function [s, s_mins, s_maxs] = unit_scale(s, s_mins, s_maxs);


divnum = 20;
snum = size(s,2);
chunksize = ceil(snum/divnum);

if ~exist('s_mins', 'var')
	%% calculate mean
	s_mins = min(s, [], 1);
end

if ~exist('s_maxs', 'var')
	%% calculate mean
	s_maxs = max(s, [], 1) - s_mins;
end




%% offset for min
if prod(size(s)) < 100000 | size(s,2) < 20
    % meanmat = repmat(s_means, [size(s,1) 1]);
    % s = s - meanmat;
    s = bsxfun(@minus, s, s_mins);
else
	st = 1;
	for ii=1:divnum
		ed = min([snum st+chunksize-1]);

        % meanmat = repmat(s_means(st:ed), [size(s,1) 1]);
        % s(:,st:ed) = s(:,st:ed) - meanmat;
        s(:,st:ed) =  bsxfun(@minus, s(:,st:ed), s_mins(st:ed));

		st = st + chunksize;
	end
end


s_maxs(find(s_maxs==0)) = 1; % To avoid zero-division

%% normalize stds
if prod(size(s)) < 100000 | size(s,2) < 20
    % stdmat = repmat(s_stds, [size(s,1) 1]);
    % s = s./stdmat;
    s = bsxfun(@rdivide, s, s_maxs);
else
	st = 1;
	for ii=1:divnum
		ed = min([snum st+chunksize-1]);
        % stdmat = repmat(s_stds(st:ed), [size(s,1) 1]);
        % s(:,st:ed) = s(:,st:ed)./stdmat;
        s(:,st:ed) = bsxfun(@rdivide, s(:,st:ed), s_maxs(st:ed));
		st = st + chunksize;
	end
end
