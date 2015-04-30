function dataOut = separateValRepeats(dataIn,seq,blockSz)
% Usage: dataOut = separateValRepeats(dataIn,seq,blockSz)
% 


nParts = length(unique(seq));
nRpts = length(seq)/nParts;
if ~nRpts==floor(nRpts)
    error('I can''t deal with unequal numbers of repeats of parts!')
end
[nTPorig,nVox] = size(dataIn); %data['val'].shape
% Order repeats
da = reshape(dataIn,[],blockSz,nVox);
%idxTmp = sorted(zip(np.arange(len(seq)),seq),key=lambda x: x[1])
%idx = [i[0] for i in idxTmp]
[~,idx] = sort(seq);
db = da(:,idx,:);
%db = da[idx]
dataOut = zeros(nParts*blockSz,nRpts,nVox);
for iRpt = 1:nRpts
    ii = 1:blockSz;
    ct = 1;
    for iPt = (1:nRpts:size(db,1))+(iRpt-1)
        catRpt = db(:,iPt,:);
        jj = ii+(ct-1)*blockSz;
        dataOut(jj,iRpt,:) = catRpt;
        %figure(1); 
        %clf; 
        %imagesc(dataOut(:,:,255));
        %drawnow; 
        %pause
        ct = ct+1;
    end
end