function preprocGabor_Wrapper(S,params,sName,sType,Ses)
% Usage: preprocGabor_Wrapper(S,params,sName,sType,Ses)
%
% Wrapper script to do Gabor Wavelet preprocessing a la Shinji
%
% Inputs: 
%   S : string file name for stimulus matrix file. Stores a3- or 4-D
%       matrix (sequence of movie frames). Can contain wildcard characters 
%       to denote multiple runs. (something like ModelA_Run*)
% Example from preprocHoG:
% [m.Spreproc m.params] = preprocHoG(S,pp);
% save(sName,'-struct','m','-v7.3')

TrnVal = {'Trn','Val'}; % Always do Trn first - need means & stds to normalize val
% Test if Ses == 2, look for ses 1 for means??

for iTrnVal = 1:2
    % Prealloc
    SppAll = [];
    allStimF = dir(S);
    allStimF = cellfun(@(x) fullfile(intDir,x),{allStimF.name}');
    for iPart = 1:length(allStimF)
        d = load(allStimF{iPart},'S');
        % Turns out that the following is really not necessary. Work it
        % back in if you please, or feel particularly masochistic; numerous
        % changes have been made to the code, so please DOUBLE CHECK THAT
        % THIS SECTION WORKS CORRECTLY IF YOU USE IT.
        %{
        if strcmp(TrnVal{iTrnVal},'Trn') && iPart > 1
            % preproc stim spanning gap btw runs (Note that Trn1 8998,8999,9000 DID precede Trn2 ...1,2,3 ) as noise fillers at the scan start)
            % NOTE: The number of values of overlap depends on params.tsize (= 10 for these two).
            Stmp = cat(4,S(:,:,:,end-9:end),d.S(:,:,:,1:10));
            [Spp,pp] = preprocColorSpace(Stmp,params); % This calls preprocWavelets_grid
            %all(SppAll(end-9:end,:) == Spp(1:10,:),2)
            SppAll(end-4:end,:) = Spp(6:10,:);
        end
        %}
        S = d.S;
        [sX,sY,nCh,nIms] = size(S);
        if nCh > nIms
            disp('WTF. you have given me a stimulus matrix with more image channels than images.')
            %keyboard; % Seems to be fine.
            nIms = nCh;
        end
        switch sType
            case {'Normals','ObNormals'}
                % Move to preprocNormalsToColor? Save as separate int.
                % file? Skip all masking?? Make masking one more nested
                % step?
                S = zeros(size(d.S),'single');
                for iIm = 1:nIms
                    [gm,go] = compute_gradients(d.S(:,:,:,iIm));
                    rr = (max(gm(:))-min(gm(:)));
                    if rr==0
                        rr = 1;
                    end
                    gm = (gm-min(gm(:)))/rr*255;
                    ShowConvertedNorms =false;
                    if ShowConvertedNorms
                        figure(1);
                        cla;
                        imagesc(gm)
                        colormap(gray);
                        %colorbar;
                        drawnow;
                    end
                    S(:,:,:,iIm) = repmat(gm,[1,1,3]);
                    %keyboard;
                end
                if ShowConvertedNorms
                    keyboard;
                end
            case 'Color'
                if max(S(:)) <1.1
                    S = 255*S;
                end
            case 'Zmask'
                S = reshape(d.S,128,128,1,[]);
                S = repmat(S,[1,1,3,1]);
                
        end
        if max(S(:)) <1.1
            % SN code expects uint8, max 255 input
            S = 255*S;
        end
        % Preprocess:
        %[Spreproc,params] = preprocColorSpace(S,params); % This calls preprocWavelets_grid
        % Gets rid of (potentially present) pre-computed means for
        % other stimuli in params struct.
        if any(isfield(params,{'means','stds'}));
            params = rmfield(params,{'means','stds'});
        end
        
        % Do Trn first, then do Val w/ Trn means.
        if iPart==1
            Nn = params.normalize;
            Cc = params.class;
            params.normalize = false;
        end
        [Spreproc,params] = feval(Cc,S,params);         
        %[Spreproc,params] = preproc_downsample(S,params,StimParams,expinfo); % This calls preprocColorSpace, which calls preprocWavelets_grid
        %{
        if strcmp(TrnVal{iTrnVal},'Trn') && iPart > 1
            % Add overlap part from above
            Spreproc(1:5,:) = Spp(11:15,:);
        end
        %}
        SppAll = [SppAll;Spreproc];
    end
    Spreproc = SppAll;
    % Move elsewhere? Just hacked in, not optimized for speed OR
    % readability
    % Set class to do nothing but downsample
    params.class = 'doNothing';
    params.normalize = Nn; % Re-set normalization
    [Spreproc,params] = preproc_downsample(Spreproc,params,StimParams,expinfo); % This calls preprocColorSpace, which calls preprocWavelets_grid
    params.class = Cc;

    % Save values so we don't have to do this again:
    sName = fullfile(sDir,sprintf('Gabor_%dpx_%s_%02d_Ses%d_%s',ImSz,sType,WhichGabor,iSes,TrnVal{iTrnVal}));
    save(sName,'Spreproc','params','-v7.3') % Ver 7.3 in case the variable is too big...
    if ShowResult
        figure; imagesc(Spreproc); colorbar; title(strrep(sName,'_',' '));
    end
    
    % % Save values so we don't have to do this again:
    %sName = fullfile(sDir,sprintf('Gabor_%dpx_%s_%02d_Ses%d_%s',ImSz,ImType{iImType},WhichGabor,iSes,TrnVal{iTrnVal}));
    %save(sName,'Spreproc','params','-v7.3') % Ver 7.3 in case the variable is too big...
end
