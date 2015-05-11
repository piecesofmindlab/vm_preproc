function S = preprocConcatStim(fList,concatFnm,Opts)
% Usage: S = preprocConcatStim(fList [,concatFnm] [,Opts])
% 
% Concatenates image files in to a 3- or 4-dimensional matrix, for easier
% loading into subsequent steps of processing. Can handle any pixelwise
% image type (RGB images, Normal [exr] images from bvp, Zdepth [exr] images
% from bvp. 
% 
% Converts images to single precision floats, with color images 0-1, zdepth
% images 0-1 (by default normalization method in exr2zDepth.m), normals to
% -1-1 as computed by hdr2normals.m
%
% Opts is a struct array, with fields:
%   .ImSz = 72 % 72 pixels square. 
%   .Normalize = false % UNFINISHED - convert to 0-1 (?)
%   .Type = a string; one of the following: 
%       'RGB' % Stimuli are RGB image files. Keep color as is.
%       'LAB' % Convert to LAB color space
%   	'BW' % Save only luminance channel from LAB color space
%   	'Z0-1' % Stimuli are .exr files of z depth; normalize depth to 0-1
%       'Zabs' % Stimuli are .exr files of z depth; keep absolute depth
%       'Normals' = false % Whether stimuli are .hdr files of surface normals
% 
% You do NOT have to provide all fields; fields will be created with
% defaults above, and overwritten with fields of "Opts" input.
% 
% ML 2012.03.19

% Input options
dOpts.ImSz = 72;
dOpts.Normalize = false; % Not functional yet! 
dOpts.Type = 'RGB';
dOpts.AdjustNormalsToBlenderWorld = true; % Make order of normals X (L/R), Y(Front/Back), Z(Up/Down)
if exist('Opts','var')
    Opts = defaultOpt(Opts,dOpts);
else
    Opts = dOpts;
end
% For backwards compatibility
OldFields = {'Is_Normal','Is_BW','Is_Z','Is_LAB'};
OldPres = isfield(Opts,OldFields);
if any(OldPres);
    if sum(OldPres)>1
        error('Can''t have more than one image type to concatenate! Also, you''re using old code. Use .Type instead of .Is_<X>')
    end
    Opts.Type = OldFields{OldPres};
end
% fill in defaults
if numel(Opts.ImSz)==1
    Opts.ImSz = [Opts.ImSz,Opts.ImSz];
end
nIms = length(fList);
% Preallocate size of output matrix
switch lower(Opts.Type)
    case {'z0-1','zabs','bw'}
        S = zeros(Opts.ImSz(1),Opts.ImSz(2),nIms,'single');
    case {'lab','rgb','normals'}
        S = zeros(Opts.ImSz(1),Opts.ImSz(2),3,nIms,'single');
end

for iIm = 1:nIms
    progressdot(iIm,50,1000,nIms);
    switch lower(Opts.Type)
        case 'z0-1'
            params.type = 'exp_med_0-1'; % default as of 2012.04.13
            params.ImSz = Opts.ImSz;
            Im = exr2zDepth(fList{iIm},params);
        case 'zabs'
            params.ImSz = Opts.ImSz;
            params.type = 'realdepth'; % default as of 2012.11.27
            Im = exr2zDepth(fList{iIm},params);
        case 'normals'
            try
                Im = exr2normals(fList{iIm},Opts.AdjustNormalsToBlenderWorld);
            catch
                Im = hdr2normals(fList{iIm},Opts.AdjustNormalsToBlenderWorld);
            end
        otherwise
            [Im map alpha] = imread(fList{iIm});
    end
    % Data type
    if strcmp(class(Im),'uint8')
        Im = single(imresize(Im,Opts.ImSz))/255;
    end
    if any(ismember(class(Im),{'double','single'}))
        Im = single(imresize(Im,Opts.ImSz));
    end
    % If normals, re-normalize after resize!
    if strcmpi(Opts.Type,'normals')
        nThresh = .1; % Reasonable value below which to set normals to zero 
        %(any normal that is a "real" normal should have a value of at
        %least 0.1 - others are probably sky normals (which should be zero)
        %that have been spuriously normalized to greater values). 
        if Opts.AdjustNormalsToBlenderWorld
            % UPDATE! Normals are given back in X = Left / Right, Y = Up / Down, Z =
            % toward / away from camera. This is NOT the same coordinate system that
            % Blender uses natively. Thus we need to be smart about this
            % re-normalization, do it the same way it's done in
            % (exr/hdr)2zDepth.m:
            y = 2;
            z = 3;
        else
            y = 3;
            z = 2;
        end
        nr = reshape(Im,[prod(Opts.ImSz),3]);
        
        % Blender spits out normal values outside the expected range
        % (-1 to 1 for x,y, 0 to 1 for z). - so fix it!
        % (This is a LITTLE alarming, but values are quite close - ML judged this
        % to be a tolerable error, 2012.05.11)
        nr(nr(:,1)<-1,1) = -1;
        nr(nr(:,1)>1,1) = 1;
        nr(nr(:,z)<-1,z) = -1;
        nr(nr(:,z)>1,z) = 1;
        nr(nr(:,y)<0,y) = 0;
        nr(nr(:,y)>1,y) = 1;
        
        L2nrm = sum(nr.^2,2).^.5;
        % Cut all 
        nr(L2nrm<nThresh,:) = 0;
        Im = reshape(nr,[Opts.ImSz,3]);
        Im = bsxfun(@rdivide,Im,reshape(L2nrm,Opts.ImSz)+1e-10);
    end
    % Format: LAB, Luminance Only, Z depth, or Normals:
    if any(strcmpi(Opts.Type,{'BW','LAB'}))
        % Convert to LAB color space
        LAB = colorspace('RGB->LAB',Im);
        if strcmpi(Opts.Type,'BW');
            Im = LAB(:,:,1);
        end
    end
    if Opts.Normalize
        disp('Normalization not ready yet!')
        keyboard;
        % Normalize? (in color space?)
        Im = (Im-mean(Im(:))) ./ std(Im(:));
    end
    switch lower(Opts.Type)
        case {'bw','z0-1','zabs'}
            S(:,:,iIm) = Im;
        case {'rgb','lab','normals'}
            S(:,:,:,iIm) = Im;
    end            
end
% Save resultant 
if exist('concatFnm','var') && ~isempty(concatFnm)
    save(concatFnm,'S','-v7.3');
end
