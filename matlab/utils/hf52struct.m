function [data,attr] = hf52struct(fName)
% Usage: struct2hf5(fName)
% 
% Reads hf5 file into two struct arrays: data and attr

% Convert structs / cells into json strings?

fi = h5info(fName);
nDataSets = length(fi.Datasets);
for iDS = 1:nDataSets
    varNm = fi.Datasets(iDS).Name;
    data.(varNm) = h5read(fName,['/' varNm]);
    nAttrs = length(fi.Datasets(iDS).Attributes);
    for iAtt = 1:nAttrs
        attrNm = fi.Datasets(iDS).Attributes(iAtt).Name;
        attrVal = fi.Datasets(iDS).Attributes(iAtt).Value;
        attr.(varNm).(attrNm) = attrVal;
    end
end

