function preprocHoGoON_Easy(HoGoN,ObLoc,params)
% Usage: preprocHoGoON_Easy(HoGoN,ObLoc,params)
% 
% Combination of Histogram of Gradients of Normals model with object
% locations to yeild Histogram of Gradients of Object Normals model. 
%
% Feed this function file names for HoGoN models and ObLoc (mask) files
% 
% NOTE: Due to the HoG bins being placed slightly away from the edge of the
% images, the alignment between mask & HoG channels will not be perfect. 
% 
% Abandoned in favor of doing it the hard way, 2012.05.07

if ischar(HoGoN)
    HoGoN = load(HoGoN);
end
if ischar(ObLoc)
    ObLoc = {ObLoc};
end

nSz = length(HoGoN.params.nSpatBins);
% preallocate object mask
obLoc = zeros([size(HoGoN.Spreproc,1),nSz);
for iM = 1:length(ObLoc)
    for iSz = 1:nSz
        m = load(ObLoc{iSz});
        Sz = HoGoN.params.nSpatBins(iSz);
        tmp = imresize(m.S,[Sz,Sz]);
        r(:,:,iSz) = tmp(:);
    end
end
