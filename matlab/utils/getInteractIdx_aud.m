function [interactIdx, interactDelay, A] = getInteractIdx_aud(rawStim, delays, locality, covtime)

% Make indicies of top of matrix
[A, idxr, idxc] = getSubMatrix([size(rawStim,1) (max(delays) + 1) 1], locality*2 +1, [1 1 0]);

% interactIdx.covsz = single(size(rawStim,1)*size(rawStim,2));
% idx2 =sub2ind([interactIdx.covsz*(4 + 1) interactIdx.covsz*(4 + 1)], idxr, idxc);
% keyboard
if covtime
    
    interactIdx.covsz = double(size(rawStim,1));
    
    idxr = double(idxr);
    idxc = double(idxc);

    idxr2 = rem(idxr,interactIdx.covsz);
    idxrd2 = floor(idxr/interactIdx.covsz)+1;

    idxrd2(idxr2==0)=idxrd2(idxr2==0)-1;
    idxr2(idxr2==0)=interactIdx.covsz;

    idxc2 = rem(idxc,interactIdx.covsz);
    idxcd2 = floor(idxc/interactIdx.covsz)+1;

    idxcd2(idxc2==0)=idxcd2(idxc2==0)-1;
    idxc2(idxc2==0)=interactIdx.covsz;

    interactIdx.idxr = idxr2; 
    interactIdx.idxc = idxc2;
    interactIdx.idxrd = idxrd2; 
    interactIdx.idxcd = idxcd2;
    
    interactIdx.covtime = covtime;
    interactDelay = [0];

else
    interactIdx.idxr = idxr; 
    interactIdx.idxc = idxc;
    interactIdx.idxrd = ones(size(idxr)); 
    interactIdx.idxcd = ones(size(idxc));
    interactIdx.covsz = size(rawStim,1)*size(rawStim,2);
    interactIdx.covtime = covtime;
    interactDelay = delays;
    
end