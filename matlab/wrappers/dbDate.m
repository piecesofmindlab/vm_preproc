function s = dbDate(d)
% Some lazy-ass shit for people who don't like to remember datestr
% formatting strings
% Returns s = datestr(d,'yyyy/mm/dd HH:MM');
% Example: DateRange = {dbDate(now-5), dbDate(now-2)}
if ~exist('d','var')
    d = now;
end

s = datestr(d,'yyyy/mm/dd HH:MM');