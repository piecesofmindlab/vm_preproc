function valUnwrap = unwrapValData(val,seq,nTRPerBlock)
% Usage: valUnwrap = unwrapValData(val,seq,nTRPerBlock)
% 
% Re-order all validation images to reflect the order in which they were
% presented, based on a sequence variable ("seq"). 
% 
% ML 2012.05.28
% (Modified from ReorderValParams.m)

% Recursive call to deal with multiple data sets, multiple sequences
if iscell(seq)
    % For now (2013.04): divide up evenly
    nParts = length(seq);
    ptDiv = size(val,1)/nParts;
    idx = 1:ptDiv;
    valUnwrap = [];
    for iPart = 1:nParts
        vTmp = unwrapValData(val(idx,:),seq{iPart},nTRPerBlock);
        idx = idx+ptDiv;
        valUnwrap = [valUnwrap;vTmp];
    end
    % Done!
    return
end
nBlocks = length(unique(seq)); %3;
% Re-ordering:
s = reshape(val,[nTRPerBlock,nBlocks,size(val,2)]);
n = s(:,seq,:);
valUnwrap = reshape(n,nTRPerBlock*length(seq),size(n,3));

% % Simpler example:
% ii = reshape(1:90,30,3);
% nidx = ii(:,v.seq);
% nidx = nidx(:);
