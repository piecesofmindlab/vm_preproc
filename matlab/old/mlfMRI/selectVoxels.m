function voxIdx = selectVoxels(voxSelType,varargin)
% Usage: voxIdx = selectVoxels(voxSelType,[inputs...])
% 
% Creates a voxel mask based on criteria specified in inputs.
% 
% Inputs: 
%   voxSelType : 'roi'|'voxFile'|'voxCrit' !! Last one not done yet,
%       subject to change!!
%   [following inputs depend on voxSelType]
%   for 'roi' : 
%     roiF : file with rois stored in it
%     roiNames : names of ROIs to select. 
%   for 'voxFile' : 
%     
% 
% ML 2013.04.28

switch voxSelType
    case 'roi'
        % Arguments are roiF,roiNames
        roiF = varargin{1};
        roiNames = varargin{2};
        d = load(roiF);
        error('Not done yet!')
    case 'voxFile'
        fNm = varargin{1};
        varNm = varargin{2};
        load(fNm,varNm);
        eval(['voxIdx = ' varNm ';']);
    case 'mask'
        % Load mask from STRFdb
        q = varargin{1};
        if nargin<3
            db = mlabSTRFdb;
            % else db = mlabSTRFdb(varargin{3})?
        end
        m = db.query(q);
        if length(m)>1
            error('Specified mask is not unique!')
        end
        [mask,mskattr] = hf52struct(m.path);
        voxIdx = mask.mask>0;
end
