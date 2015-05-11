function DataOut = blockNormalize2D(Data,bIdx,Opts)
% Usage: DataOut = blockNormalize2D(Data,bIdx,Opts)
% 
% Normalize a (vectorized 2D image) by the surround of each pixel or
% element (possibly by multiple different surrounds). 
% 
% Originally written for HoG normalization, 2012.05.14
% 
% Inputs: 
%   Data = a 2D matrix of 
% 
% ML 2012.05.14

% Default inputs
Opt.bType = 'Corners'; % block type (default = corners)
Opt.nType = 'L2'; % norm type (default = L2)
if exist('Opts','var')
    Opts = mlFillStruct(Opts,Opt,true);
else
    Opts = Opt;
end
clear Opt;
% Preprocessing: 
% Determine if data is matrix or vector
if ndims(Data)==3
    Data = reshape(Data,[size(Data,1) * size(Data,2),size(Data,3)]);
end

switch lower(Opts.bType)
    case 'corners'
        DataOut = zeros([size(Data),4]);
        for iC = 1:4
            Ss = sum((bIdx(:,:,iC)*Data.^2),2);
            N = Ss.^0.5;
            DataOut(:,:,iC) = bsxfun(@rdivide,Data,N);
        end

    case 'centersurround'
        DataOut = zeros(size(Data));
        Ss = sum((bIdx*Data.^2),2);
        N = Ss.^0.5;
        DataOut(:,:) = bsxfun(@rdivide,Data,N);
        
end

