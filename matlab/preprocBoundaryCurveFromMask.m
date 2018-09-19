function [varargout] = preprocBoundaryCurveFromMask(S,pp)
% Usage: [Spreproc,params] = preprocBoundaryCurveFromMask(S,params);
%
% Finding and quantifying curvature at object edges. Operates on a stack
% of masks. Masks are binary true/false 2D matrices with true values where
% there is FIGURE (an object) and false values where there is GROUND (only
% background/nothing).
% Masks for all objects in a scene should be stacked in depth, with
% S(:,:,1) being FARTHEST and S(:,:,end) being NEAREST. S(:,:,end) should
% always exist; S(:,:,1) can be full of nans or zeros.
%
% S can also be supplied as an array of masks, of size [ImSz x ImSz x
% nObjects x nFrames]. Same depth stacking applies. If a mask is supplied,
% *OR* S is a string file name for a mask file, or for a set of mask files
% saved by preprocStackMasks.m
%
% The general process followed below is:
% (1) From 2D mask matrices, compute (x,y) coordinate sets (lines)
%     associated with each mask.
% (2) Compute curvature along each of those lines (+=convex,-=concave)
% (3) Mask out curves that are occluded by other objects
% (4) (optionally) Bin curvature in a grid of x,y bins
%
% This process can be run at several different scales.
%
% params is a struct with default values as follows:
%     % First-stage processing
%     o params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
%     x params.ImSmoothSTD = [5,4,2]; % Leave empty for no smoothing
%     x params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
%     x -> [[Determined by params.Scales]] params.ImBinSzPx = 16; % Curvaure will be computed at ImBinSzPx * Scale size,
%     params.MaskThresh = 5; %for uint8 images
%     params.BinFn = {{'mlMaxPosNeg'},{'curvRectify'}}; % How to summarize over bins of curvature
%     params.nDimsPerBin = 2; % This could be computed, but given the number of variations of BinFn, it's easier to specify it explictly
%     params.DimValues = {'pos','neg'}; % For later labels / visualization
%     params.FlattenInfCurvFn = {'mlSquash',-1,1}; % function + arguments for reducing large / infinite values of curvature
%     params.Is_FillHoles = true; % false = do not fill holes, incorporate holes in objects into boundary curvature
%     params.Is_ClipOccluded = true;
% 
%
% ML 2011.08.03
% Revised 2013.03.13

try
    % Default Params
    % First-stage processing
    params.Scales = [16,8,4]; % 3 values for 3 scales - convert these to visual degrees?
    params.ImSmoothSTD = [5,4,2]; % Leave empty for no smoothing
    params.CurvSmoothSTD = [3,3,3]; %1.5; % STD of smoothing Gaussian for each scale
    params.ImBinSzPx = 16; % Curvaure will be computed at ImBinSzPx * Scale size,
    params.MaskThresh = 5; %for uint8 images
    params.BinFn = {{'mlMaxPosNeg'},{'curvRectify'}}; % How to summarize over bins of curvature
    params.nDimsPerBin = 2; % This could be computed, but given the number of variations of BinFn, it's easier to specify it explictly
    params.DimValues = {'pos','neg'}; % For later labels / visualization
    params.FlattenInfCurvFn = {'mlSquash',-1,1}; % function + arguments for reducing large / infinite values of curvature
    params.Is_FillHoles = true; % false = do not fill holes, incorporate holes in objects into boundary curvature
    params.Is_ClipOccluded = true;
    params.Is_Normalize = true; 
    
    if exist('pp','var')
        if isnumeric(pp)
            % if params are given in the form: [1,3];
            pp = preprocBoundaryCurveFromMask_GetMetaParams(pp);
        end
        params = defaultOpt(pp,params);
    end
    % Computed params
    params.nScales = length(params.Scales);
    % Check that other fields have same nScales
    if (length(params.CurvSmoothSTD)~=params.nScales && ~isempty(params.CurvSmoothSTD)) || ...
            (length(params.ImSmoothSTD)~=params.nScales && ~isempty(params.ImSmoothSTD));
        error('all parameters for scales must indicate the same number of scales!')
    end
    % Convert sizes in pixels to vis. degreees??
    %params.ScalesDegrees = []; %? necessary?
    % Params for visualizing this model later
    params.cParams.Xc = []; % center of bin, X
    params.cParams.Yc = []; % center of bin, Y
    params.cParams.Sz = []; % bin size (proportion of screen)
    params.cParams.K = [];
    for iSc = 1:params.nScales
        [x,y] = meshgrid(1:params.Scales(iSc),1:params.Scales(iSc));
        % Repeats according to nDimsPerBin
        R = params.nDimsPerBin;
        Xc = repmat(x(:),[R,1]);
        Yc = repmat(y(:),[R,1]);
        Sz = repmat(1/params.Scales(iSc),[length(x(:))*R,1]);
        switch params.DimValues{1}
            case 'pos' % for {'pos','neg'}
                K = repmat([1,-1],[length(x(:)),1]);
                K = K(:);
            case 'bin'
                K = repmat([params.DimValues{2:end}],[length(x(:)),1]);
                K = K(:);
        end     
        params.cParams.Xc = [params.cParams.Xc;Xc];
        params.cParams.Yc = [params.cParams.Yc;Yc];
        params.cParams.Sz = [params.cParams.Sz;Sz];
        params.cParams.K = [params.cParams.K;K];
        clear Xc Yc Sz K;
    end
    
    % Misc details, preallocation
    BinF = {};
    for iB = 1:length(params.BinFn)
        BinF = [BinF,params.BinFn{iB}{1}];
    end
    if any(ismember(BinF,'curvHardBinSum'))
        idx = ismember(BinF,'curvHardBinSum');
        params.BinFn{idx}{2}(end) = inf; % this makes the last bin useless; we will cut it below.
        clear idx;
    end
    if ~nargin
        % Return parameters if called alone.
        varargout{1} = params;
        return;
    end
    
    if ischar(S)
        % S is a string file name (or string with wildcard for multiple masks)
        tmpFdir = [fileparts(S) filesep]; % directory to store temporary (intermediate) files
        maskF = dir(S);
        maskF = {maskF.name}';
        nChunks = length(maskF);
        clear(S);
    else
        nChunks = 1;
    end
    
    SkipTo = 0;
    % Optional info for saving (intermediate and finished) files:
    if isfield(params,'fInfo')
        %%% NOTE! This is a prime candidate for managing with a couch
        %%% database instead of file name conventions...
        % fInfo is information particular to this parameter preset and this
        % particular run (training / validation, session #, pixels for images)
        if isfield(params.fInfo,'sNameA')
            sTmp = dir(fullfile(params.fInfo.iDir,sNameA));
            sNameA = mlAddToCell({sTmp.name},params.fInfo.iDir);
        else
            for iCh = 1:nChunks
                sNameA{iCh} = sprintf('%sBoundCurvLines_%dpx_%s_Ses%d_%s_%02d_Part%02d.mat',params.fInfo.iDir,params.fInfo.nPixels,params.fInfo.ImType,params.fInfo.Ses,params.fInfo.TrnVal,params.metaparams.preset(1),iCh);
            end
        end
        for iCh = 1:nChunks
            sNameB{iCh} = sprintf('%sBoundCurvImage_%dpx_%s_Ses%d_%s_%02d_Part%02d.mat',params.fInfo.iDir,params.fInfo.nPixels,params.fInfo.ImType,params.fInfo.Ses,params.fInfo.TrnVal,params.metaparams.preset(1),iCh);
        end
        if exist(sNameB{1},'file')
            SkipTo = 2;
        elseif exist(sNameA{1},'file')
            SkipTo = 1;
        end
    end
    
    % For use below, indexing curvature parameters into Spreproc variable
    idxEnd = [0,params.Scales.^2 * params.nDimsPerBin]; % (Specifies number of channels for each scale)
    Spreproc = [];
    for iChunk = 1:nChunks
        fprintf('Processing part %d of %d\n',iChunk,nChunks);
        % Load mask file, if necessary
        if exist('maskF','var');
            S = load([tmpFdir maskF{iChunk}]);
            S = S.MaskStack;
        end
        % Preallocate
        nMasks = size(S,3);
        nFrames = size(S,4);
        Fn = {'X',{cell(nMasks,params.nScales)},'Y',{cell(nMasks,params.nScales)},'K',{cell(nMasks,params.nScales)}};
        C(1:nFrames) = struct(Fn{:});
        if SkipTo < 2
            Spreproc = zeros(nFrames,sum(idxEnd));
            for iFr = 1:nFrames
                % track progress
                progressdot(iFr,100,1000,nFrames);
                if SkipTo < 1
                    C(iFr) = contourFromMask(S(:,:,:,iFr),params);
                    if iFr==nFrames && exist('sNameA','var')
                        save(sNameA{iChunk},'C','params')
                    end
                else
                    if iFr==1
                        load(sNameA{iChunk},'C');
                    end
                end
                
                for iScale = 1:params.nScales
                    % Flatten image, instead of doing this mask by mask
                    x = cat(1,C(iFr).X{:,iScale});
                    y = cat(1,C(iFr).Y{:,iScale});
                    k = cat(1,C(iFr).K{:,iScale});
                    % Resample x,y, and k to be on a regular grid before binning??
                    [xGr,yGr]= meshgrid(0:params.Scales(iScale)-1,0:params.Scales(iScale)-1);
                    Bins = yGr+params.Scales(iScale)*xGr + 1;
                    Bins = imresize(Bins,params.ImBinSzPx,'nearest');
                    CurvParamTmp = nan(params.Scales(iScale)^2,params.nDimsPerBin);
                    for iBin = 1:max(Bins(:))
                        [yf,xf] = find(Bins==iBin);
                        try
                            idx = ismember(round([x,y]),[xf,yf],'rows');
                        catch
                            idx = [];
                            disp(['complete occlusion/off-camera object in scene: ' num2str(iFr)])
                        end
                        if ~any(idx)
                            CurvParamTmp(iBin,:) = nan;
                            continue
                        end
                        kk = k(idx);
                        % Allow for iterative computations (max, then
                        % binning, etc.) within bins
                        for iBinCollapse = 1:length(params.BinFn)
                            BinFn = params.BinFn{iBinCollapse};
                            kk = feval(BinFn{1},kk,BinFn{2:end});
                        end
                        CurvParamTmp(iBin,:) = kk; clear kk;
                    end % iBin
                    % Get index for where to insert these values & insert
                    sppIdx = (1:idxEnd(iScale+1))+sum(idxEnd(1:iScale));
                    Spreproc(iFr,sppIdx) = CurvParamTmp(:)';
                end % iScale
            end % iFr
            % Save temporary file for this chunk
            if isfield(params,'fInfo')
                save(sNameB{iChunk},'Spreproc','params','-v7.3');
            end
        else
            % Above the Chunk loop, we pre-allocated Spreproc to be empty
            Spp = load(sNameB{iChunk},'Spreproc');
            Spreproc = [Spreproc;Spp.Spreproc];
        end % SkipTo==2
    end % iChunk

    if any(isnan(Spreproc(:)))
        warning('Converting nan values to zero!')
        Spreproc(isnan(Spreproc)) = 0;
    end
    % Normalize
    if params.Is_Normalize
        mm = nanmean(Spreproc);
        ss = nanstd(Spreproc);
        SppDeMean = bsxfun(@minus,Spreproc,mm);
        SppZ = bsxfun(@rdivide,SppDeMean,ss);
        SppZ(isnan(SppZ)) = 0;
        % Straight Z score gives wacky results: curves appear so sparsely
        % that it's not uncommon for a given channel to have one point of
        % high curvature appear, and nothing else (or, no other high values
        % of curvature for the whole training set). This means that z
        % scoring by channel can give really high z scores - up to 35 - to
        % some values of curvature, which is not appropriate. Solution:
        % squash 'em back down with a sigmoid function, same as above for
        % curvature.
        % Sigmoid squashing function:
        squash = @(x,b) 6/(1+exp(-b*x))-3; % Range from -3 to +3
        bb = 1; % this is the choice of STD... 2 seems to work well, but I don't have a rigorous reason for that.
        SppZs = zeros(size(SppZ));
        for iN = 1:size(SppZ,2);
            SppZs(:,iN) = arrayfun(@(ii) squash(ii,bb),SppZ(:,iN));
        end
        Spreproc = SppZs;
    end
    % Save final file
    if isfield(params,'fInfo') && isfield(params.fInfo,'sNameFin')
        fprintf('Saving %s ...\n',params.fInfo.sNameFin);
        save(params.fInfo.sNameFin,'Spreproc','params');
    end
    % Outputs
    varargout{1} = Spreproc;
    if nargout==2
        varargout{2} = params;
    end
catch
    save('DebugVars_preprocBC')
    %fprintf('crapped out at frame %d\n',iFr)
    rethrow(lasterror)
end
end

% Functions that operate within 2d bins in the image
function b = curvSoftBinSum(k,bc,bw,div)
% k = curvature of line within bin
% bc = bin centers
% bw = bin width(s)
% div = normalization (what to divide by); by default, length of k
if ~exist('div','var')
    div = size(k,1);
end
b = softBin(k,bc,bw);
b = sum(b)/div;
end
function b = curvHardBinSum(k,be,div)
% k = cuvature of line within bin
% be = bin edges
% div = normalization (what to divide by); by default, length of k
if ~exist('div','var')
    div = size(k,1);
end
b = histc(k,be,2);
b = b(:,1:end-1);
b = sum(b)/div;
end
function b = curvRectify(k)
% Rectify: separate positive/negative
p = max(k,0);
n = abs(min(k,0));
b = [p,n];
end
function b = curvNormMax(kk)
% Max (absolute) curvature, w/ sign retained,
% divided by the standard deviation of curvature in this bin
kMax = mlMaxPosNeg(kk);
kZ = abs(zscore(kk));
zFac = normcdf(max(abs(kZ)));
b = kMax*zFac;
if false
    figure(1);
    plot(x,y,'k',x(idx),y(idx),'r.');
    axis ij;
    AxLim = params.Scales(iScale) * params.ImBinSzPx;
    axis([1 AxLim 1 AxLim]);
    title(sprintf('k=%.3f, zFac = %.3f',kMax,zFac));
    keyboard;
end
end