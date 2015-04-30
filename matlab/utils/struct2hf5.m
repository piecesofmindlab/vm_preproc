function struct2hf5(fName,s,a)
% Usage: struct2hf5(fName,s,a)
% 
% Stores two struct arrays in an hdf5 file.
% 
% Parameters
% ----------
% s : struct (for data)
%   each field is stored as a separate named variable in the hf5 file
% a : struct (for attributes)
%   each field is stored as a named attribute of the data in s. field names
%   for these two struct arrays should be the same.

if exist(fName,'file')
    error('I''m not built to over-write yet..')
end

% Add "Deflate" input to h5create to use gzip compression?

% Convert structs / cells into json strings?

kv = fieldnames(s);
ka = fieldnames(a);
nFields = length(kv);
for iK = 1:nFields
    k = kv{iK};
    % Create file
    h5create(fName,['/' k],size(s.(k)));
    h5write(fName,['/' k],s.(k));
    if ismember(k,ka)
        attNm = fieldnames(a.(k));
        for iAtt = 1:length(attNm)
            att = a.(k).(attNm{iAtt});
            h5writeatt(fName,['/' k],attNm{iAtt},att);
        end
    end
end