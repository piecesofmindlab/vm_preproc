function [lums cons] = getLumCon(S, params)

% Usage: [lums cons] = getLumCon(S, params)
% 
% 

S = reshape(S, size(S,1)*size(S,2), []);
rawLum = single(mean(S,1));
lumArray = ones(size(S,1),1,'single')*rawLum;
rawCon = mean((single(S)-lumArray).^2,1).^0.5./rawLum;

lums = getWsum(rawLum, params.lumTimeCourse);
cons = getWsum(rawCon, params.conTimeCourse);


function out = getWsum(r, timecourse)

out = r*0;
tmax = length(timecourse);
mean_pad = mean(r)*mean(timecourse);
for t=1:tmax
    out(t:end) = out(t:end) + timecourse(t)*r(1:end-t+1);
    out(1:t-1) = out(1:t-1) + mean_pad;
end

% normalizing
out = out-mean(out);
out = out/std(out);

% sigmoid
out = 1./(1+exp(-out));

