function varargout = preprocCombineMasks(S,params)
% Usage: [Sout,params] = preprocCombineMasks(S,params)
%
% Converts mask stack (created by preprocStackMasks.m) from a [imX x imY x
% nMasksPerScene x nFrames] matrix to a matrix of images (one image for
% each scene), with masks correctly overlaid in depth.
% 
% S is a [X x Y x nFrames x nMasks] matrix of depth-stacked mask images
% (see preprocStackMasks.m)
% 
% params is a struct array with fields:
%   .finSz = final size of mask matrix [i,j]
%   .sName (optional! default = no sName field) = file name to save when
%       finished. Convention is, e.g.,
%       "ConcatStim_Ses1_Val_128px_Zmask.mat" % for z-stacked masks
%       "ConcatStim_Ses1_Trn_128px_AllMask.mat" % for all masks == 1
%   .Color = color map for successively more far-away object masks
%       (defaults to grayscale, with the front object mask in white and
%       successive (further away) object masks in darker shades of gray)
%   .Zstack = true ; false to combine all masks a single logical image
%   .Consistent = false; % NOT IMPLEMENTED YET! Flag to prevent objects
%       from changing colors if their depth ordering changes (i.e., if one
%       moves closer to the camera in successive frames of the same scene)
%   .mThresh = threshold for logical masks (/255) (default=5)
% 
% ML 2011.07
% Updated by ML 2016.06.04
% NOTE: this code is absurdly slow, and most likely needn't be. But it's
% generally used only once for preprocessing a whole data set, so it
% doesn't seem worth it to update it for now. ML 2013.06

pDefault.finSz = [128,128];
pDefault.Color = nan;
pDefault.Zstack = true;
pDefault.Consistent = false; % Does nothing yet! as of 2012.05.07
% threshold for mask / not mask:
pDefault.mThresh = 5; % /255
if exist('params','var')
    params = defaultOpt(params,pDefault);
end

if numel(params.finSz)==1
    params.finSz = [params.finSz,params.finSz];
end

% Preallocate
[ySz,xSz,nMasks,nIms] = size(S);
ImSz = [ySz,xSz];
Mask = reshape(S,[ySz*xSz,nMasks,nIms])>params.mThresh;

if ~params.Zstack
    M = squeeze(sum(S,3))>params.mThresh;
else
    
    if isnan(params.Color)
        cMap_Mask = [.25 .25 .25; .5 .5 .5; .75 .75 .75; 1 1 1];
    else
        if params.Color == 1 
            % Simple colors
            Col = load('MLColors');
            cMap_Mask = [Col.Red;Col.Yellow;Col.BlueBright;Col.Green]/255;
            M = zeros([ImSz,3,nIms]);
        else
            cMap_Mask = params.Color;
            if size(params.Color,2)==1
                M = zeros([ImSz,nIms]);
            else
                M = zeros([ImSz,3,nIms]);
            end
        end
    end
    
    for iIm = 1:nIms;
        progressdot(iIm,50,2000,nIms);
        % Dummy variable to fill:
        Mcol = zeros([ImSz(1)*ImSz(2),3],'single');
        for iM = 1:nMasks
            if all (Mask(:,iM,iIm)==0)
                continue
            end
            cMap = mlColorMapCreator([0 0 0;cMap_Mask(iM,:)],256);
            tmpIm = repmat(S(:,:,iM,iIm),[1,1,3]);
            Mtmp = mlImChangeCmap(tmpIm,cMap);
            % Replace RGB channels one at a time
            for iRGB = 1:3
                % Substitute colors one by one
                TmpIm1 = Mtmp(:,:,iRGB);
                Mcol(Mask(:,iM,iIm),iRGB) = TmpIm1(Mask(:,iM,iIm));
            end
        end
        Mcol = reshape(Mcol,[ImSz(1),ImSz(2),3]);
        if ~isnan(params.Color)
            M(:,:,:,iIm) = Mcol;
        else
            M(:,:,iIm) = rgb2gray(Mcol);
        end
    end
end
% Resize
Sout = imresize(M,params.finSz,'bilinear');

varargout{1} = Sout;
if nargout==2
    varargout{2} = params;
end
