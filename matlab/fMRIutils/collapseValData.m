function dataOut = collapseValData(dataIn,seq,blockSz)
% Usage: dataOut = collapseValData(dataIn,seq,blockSz)
% 
% Averages validation data across repeats
% 
% ML 2013.04

% TO DO: Check for dimensionality of data

nParts = length(unique(seq));
dataOut = zeros(nParts*blockSz,size(dataIn,2),class(dataIn));
ii = reshape(1:nParts*blockSz,blockSz,nParts);
nidx = ii(:,seq);
nidx = nidx(:);
for iG = 1:nParts*blockSz;
    dataOut(iG,:) = mean(dataIn(nidx==iG,:));
end
