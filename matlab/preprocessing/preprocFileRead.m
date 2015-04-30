function [stim params] = preprocFileRead(rawStim, params)

if nargin==0
    params = [];
    params.class = 'preprocFileRead';
    stim = params;
    return
end

basedir = '/auto/data/shinji/preprocFiles/';

switch params.fileclass
    case 'semantic'
        s=load('/auto/data/shinji/semanticlabels/vidsem_stim_trn.mat');
        stim_trn = s.stim;
        s=load('/auto/data/shinji/semanticlabels/vidsem_stim_val.mat');
        stim_val = s.valStim;
        stim = cat(1, stim_trn, stim_val);
        stim = norm_std_mean(stim);
        stim = stim(:,params.validlabels);
    case 'ica'
        fname = [basedir params.filename '.mat'];
        disp(['preprocFileRead: loading ' fname]);
        load(fname);
        
    case 'turk_video'
        fname='/auto/data/shinji/semanticlabels/turk_video.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);
        stim = single(stim);

    case 'turk_video_ica'
        fname='/auto/data/shinji/semanticlabels/turk_video_ica.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);
        stim = single(stim);

    case 'turk_video3840'
        fname='/auto/data/shinji/semanticlabels/turk_video3840.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);

    case 'turk_video_TR2_01'
        fname='/auto/data/shinji/semanticlabels/turk_video_TR2_01.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);
        if isfield(params, 'gaborhybrid') & params.gaborhybrid
          switch params.gaborhybrid
            case 241
              s=load('/auto/data/shinji/preptmp/TGDUWBAMHPZBPRIDLUNJTQQRQDBRWY.mat');
          end
          stim = cat(2,stim, s.stim);
        end

    case 'lsa_TR2_01'
        fname='/auto/data/shinji/semanticlabels/lsa_TR2_01.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);

    case 'turk_video_TR2_01_val1min'
        fname='/auto/data/shinji/semanticlabels/turk_video_TR2_01_val1min.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);

    case 'turk_video3840_ica'
        fname='/auto/data/shinji/semanticlabels/turk_video3840_ica.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);

    case 'sfa2'
        fname=sprintf('/auto/data/shinji/sfa/sfa%03d_stim.mat',params.number);
        disp(['preprocFileRead: loading ' fname]);
        load(fname);
        pstim=reshape(pstim,15,[],size(pstim,2));
        stim=squeeze(mean(pstim,1));
        stim=norm_std_mean(stim);
        stim(stim<-3)=-3;
        stim(stim>3)=3;
        
    case 'arg314pca_TR02_1'
        basedir = '/auto/data/shinji/semanticlabels/';
        switch params.number
            case 1
                fname = [basedir 'arg314pca_0100.mat'];
            case 2
                fname = [basedir 'arg314pca_0200.mat'];
            case 3
                fname = [basedir 'arg314pca_0500.mat'];
            case 4
                fname = [basedir 'arg314pca_0100pn.mat'];
            case 5
                fname = [basedir 'arg314pca_0200pn.mat'];
            case 6
                fname = [basedir 'arg314pca_0500pn.mat'];
            case 7
                fname = [basedir 'arg314pca_0050.mat'];
            case 8
                fname = [basedir 'arg314pca_0050pn.mat'];
        end
        disp(['preprocFileRead: loading ' fname]);
        load(fname);
        
        if isfield(params, 'hybrid') && params.hybrid==1
            h=load([basedir 'arg314_TR2_01.mat']);
            stim = [h.stim stim];
        end
        
    case 'wordnetface3_TR2_01'
        fname='/auto/data/shinji/semanticlabels/wordnetface3_TR2_01.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);

    case 'lsaword_v8min'
        fname='/auto/data/shinji/semanticlabels/lsaword_v8min.mat';
        disp(['preprocFileRead: loading ' fname]);
        load(fname);

    case 'fracs'
        disp(['Loading :' params.fname]);
        load(params.fname);
        stim = stims(:,params.ranges,:);
        clear stims
        stim = reshape(stim,[],size(stim,3));
        stim = norm_std_mean(stim)';

    otherwise
        if isstr(params.filename)
          fname=params.filename;
          disp(['preprocFileRead: loading ' fname]);
          load(fname);
        else
          s=[];
          for ii=1:length(params.filename)
            fname=params.filename{ii};
            disp(['preprocFileRead: loading ' fname]);
            load(fname);
            s = cat(2,s,stim);
          end
          stim = s;
        end


end


if isfield(params, 'gaborhybrid') & params.gaborhybrid
    if isnumeric(params.gaborhybrid)
      switch params.gaborhybrid
          case 225
              s=load('/auto/data/shinji/preptmp/KILGJPKKVLMLFDEXEZOHDOSMVOCXWE.mat');
          case 275
              s=load('/auto/data/shinji/preptmp/ATPOQVYDPTUDKHLGQBPRQLNSHARBYD.mat');
      end
    end
    stim = cat(2,stim, s.stim);
end
