function mio = getCurvHashFile(S,scale,Is_FillHoles,mergeObjects)
% Usage: mio = getCurvHashFile(S,scale,Is_FillHoles,mergeObjects)
%
% Create matfile object for the hash file for computed curvature for a
% given stimulus (masks) and scale of curvature (You can optionally
% provide 'Is_FillHoles' and 'mergeObjects' arguments too). 
% 
% ML 2013.10.15

if ~exist('mergeObjects','var')
    mergeObjects = 'last';
end
if ~exist('Is_FillHoles','var')
    Is_FillHoles = true;
end
DatChk = struct('scale',scale,'Is_FillHoles',Is_FillHoles,'mergeObjects',mergeObjects); 

ss = matfile(S.path);
getS = @(x) cat(4,x.S(:,:,:,1:30)>0,x.S(:,:,:,size(x,'S',4)-29:size(x,'S',4))>0);
%getS = @(x) ss.S(:,:,:,1:30);
DatChk.Stim = getS(ss);

HashFile = ['/auto/k8/tempcache/' DataHash(DatChk) '.mat'];

if ~exist(HashFile,'file')
    warning('Hash file does not exist! returning DatChk Struct!');
    mio = DatChk;
else
    mio = matfile(HashFile);
end
