 function [stim, params] = preprocSTFT(rawStim, params)
 % function [stim, params] = preprocSTFT(rawStim, params)
 %      
 %   Short-time Fourier Transform (Help window)                               
 %                                                                            
 %  Load files: To load data sets for short-time fourier transform. Here one  
 %          data set need include stimulus and its corresponding response     
 %          data, although the response data may not be changed by STFT.      
 %  stimulus file:  shows the filename of one stimulus selected.              
 %  response file:  shows the filename of the response selected.              
 %                                                                            
 %  Parameters:                                                               
 %      filter_width (Hz): the width of the filter in Hz. It defines window   
 %              length of filter (here we use Gaussian filter).               
 %      filter_width (ms): the width of the filter in ms                      
 %      amp_samprate (Hz): the sampling rate that we want for the amplitude   
 %                  envelope. By default, it is 10 times of filter_width (Hz).
 %      resp_samprate (Hz): the sampling rate of spike data.                  
 %      upper frequency (Hz): the upper frequency you want to study.          
 %                           The max frequency is limited to stim_samprate/2. 
 %      lower frequency (Hz): the lower frequency you want to study (>= 0Hz). 
 %      stim_samprate (Hz): the sampling rate of stimulus in Hz.              
 %      nbands: the numbers of frequency bands covered for the calculation.   
 %      Scale option: the choice of linear scale or logarithmic scale         
 %                                                                            
 %  Compute and Save: Compute the spectrogram of the signal and save          
 %       the results into the directory where you will be asked to input.     
 %       The computing status bar also shows up so that you can know progress.
 %  Display: Graphically display the spectrogram of the stimulus and          
 %      the smoothed psth with  Smooth_PSTH window size. The smoothing width  
 %      for psth is shown here. You can modify it by typing different number. 
 %       If more than one data sets are chosen, \fbox{Next} and               
 %       Prev buttons show up so that you can click to see next data sets.    
 %  Reset: Reset all the parameters and the data sets chosen.                 
 %  Close: Close this window and save all the parameters and all the result   
 %                                                                                      
 %                                                                            
 % Updated by Junli, Sept. 2005. 
 % Modified for STRFlab by Michael Oliver July 2009                                             

 optDeflt.class = 'preprocSTFT';
 optDeflt.fs = 32000;
 optRange.fs = [0 Inf];
 optDeflt.dbnoise = 80;
 optRange.dbnoise = [0 Inf];
 optDeflt.fwidthHz = 50;
 optRange.fwidthHz = [0 Inf];
 optDeflt.filteroption = 1;
 optRange.filteroption = [0 Inf];
 optDeflt.ampsamprate = 1000;
 optRange.ampsamprate = [0 Inf];
 optDeflt.desired_fs = 32000;
 optRange.desired_fs = [0 Inf];
 optDeflt.initialFreq = 1;
 optRange.initialFreq = [0 Inf];
 optDeflt.endFreq = 8000;
 optRange.endFreq = [0 Inf];
 if nargin<2
   params=optDeflt;
 else
   params=defaultOpt(params,optDeflt,optRange);
 end
 if nargin<1
   stim=optDeflt;
   return;
 end


fs = params.fs;
dbnoise = params.dbnoise;
ampsamprate = params.ampsamprate;
fwidthHz = params.fwidthHz;
filteroption = params.filteroption;
if ~isfield(params,'initialFreq') & ~isfield(params,'endFreq')
    params.initialFreq = 1;
    params.endFreq = fs/2;
else
    if params.endFreq > fs/2
        ttt=warndlg('Max frequency limit is stimsamprate/2.', 'high frequency warning','modal');
        uiwait(ttt);
        endFreq = fs/2;
    end
end
initialFreq = params.initialFreq;
endFreq = params.endFreq;
% DBNOISE = 80;  % 04/12/2006
% dB in Noise for the log compression - values below will be set to
% zero.

% do calculation
% tempWait = waitbar(0, 'Calculating spectrogram, please wait...');
% hashes_of_stims = {};
% global the_checksum
% the_checksum = '';

% for ii=1:numfiles

    % waitbar(ii/numfiles, tempWait);

    % 3.1. Take care of Stimulus file
    % [input, fs] = wavread(rawDS{ii}.stimfiles);
    % [path,name,ext,ver] = fileparts(rawDS{ii}.stimfiles);
    % Spectrogram calculation
    %
    desired_fs = ceil(fs/ampsamprate)*ampsamprate;
    params.desired_fs = desired_fs;
    if desired_fs > fs
        rawStim = resample(rawStim,desired_fs,fs);
        fs = desired_fs;
    end

    % [yy, xx] = do_cached_calc('ComplexSpectrum',rawStim, floor(fs/ampsamprate),...
        % floor(1/(2*pi*fwidthHz)*6*fs),fs);
    [yy, xx] = ComplexSpectrum(rawStim, floor(fs/ampsamprate),...
        floor(1/(2*pi*fwidthHz)*6*fs),fs);
        
    % if ~isempty(the_checksum)
    %     hashes_of_stims{ii} = the_checksum; % calculated in do_cached_calc; the_checksum is a global variable
    % end
    stimsamprate = fs;

    % Working on more options -JXZ- Aug. 2003
    if filteroption == 1 % linear-linear
        tmp = abs(yy);
    else  % just temporary
        %tmp = log(abs(yy) +1);
        tmp = max(0, 20*log10(abs(yy)./max(max(abs(yy))))+dbnoise);
    end

    freq_range = find(xx>=initialFreq & xx<=endFreq);

    %         if rem(size(tmp,1), 2)    % Odd
    %             cutoff = (size(tmp,1) +1)/2;
    %         else
    %             cutoff = size(tmp,1)/2+1;
    %         end

    stim = tmp(freq_range,:)';
    params.fo = xx(freq_range);

    % save(fullfile(outputPath,[name,'_Stim_',num2str(ii),'.mat']), 'outSpectrum');
    % if isempty(the_checksum)
    %     hashes_of_stims{ii} = checksum_from_file(fullfile(outputPath,[name,'_Stim_',num2str(ii),'.mat']));
    % end
    % Assign values to global variable DS
    % DS{ii}.stimfiles = fullfile(outputPath,[name,'_Stim_',num2str(ii),'.mat']);
    % DS{ii}.nlen = size(outSpectrum,2);

    %save(fullfile(outputPath,['specgram_Stimlabel_',num2str(ii),'.mat']), 'fo');

    % 3.2. Take care of Response file
    %    If you have multiple trial data, calculate psth first
    %    Then resample it using new amp_samp_rate

    %rawResp = load(rawDS{ii}.respfiles);
    % Modified by Junli, 2003 to read new spike arrivial time file
    %
    % [rawResp, trials] = read_spikeTime_2cell(rawDS{ii}.respfiles, round(length(rawStim)*1000/fs) +1);
    %    [path,name,ext,ver] = fileparts(rawDS{ii}.respfiles);
    %    %rawResp = read_spikeTime(rawDS{ii}.respfiles, size(outSpectrum, 2));
    % 
    % 
    %    % save to the file for each data pair
    %    save(fullfile(outputPath,[name,'_Spike_time_',num2str(ii),'.mat']), 'rawResp');
    % 
    %    % Assign values to global variable DS
    %    DS{ii}.respfiles = fullfile(outputPath,[name,'_Spike_time_',num2str(ii),'.mat']);
    %    DS{ii}.ntrials = trials;
   
% end
%save(fullfile(outputPath,'preprocessed_stim_hashes.mat'),'hashes_of_stims');
% put_stim_checksums(hashes_of_stims,DS);
% close(tempWait)

% NBAND = size(outSpectrum, 1);
% save(fullfile(outputPath,'specgram_parameters.mat'),...
    % 'rawDS', 'fwidthHz', 'filteroption','stimsamprate','ampsamprate');

% global originalDS
% originalDS = DS;
%%%$$$ end preprocess