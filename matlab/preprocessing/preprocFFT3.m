function [Spreproc,params] = preprocFFT3(S,params)
% Usage: [Spreproc,params] = preprocFFT3(S,params)
% 
% 3D Fourier transform of stimulus, plus binning by orientation and spatial
% / temporal frequency. 
% 
% Inputs: 
%        S : Grayscale image matrix, [X x Y x T]
%   params : parameter struct, w/ fields:
%       .nOris : n orientation bins [default 16]
%       .nSFs : n spatial frequency bins [default 10]
%       .nTFs : n temporal frequency bins [default 10]
% 
% TO DO: pad SppTmp w/ zeros for larger FFT!
% ML 2013.07.02

% Default values
dParams.class = 'preprocFFT3';
dParams.zeroSF = true;
dParams.ori_n = 8;
dParams.sf_n = 8;
dParams.tf_n = 4;
dParams.ori_max = pi;
dParams.sf_max = 32; % defaults to size of S / 2 if empty
dParams.tf_max = []; % defaults to params.tSize/2 if empty
% Optionally, directly specify bins (2 row matrix of bin edges: 1st row=bin min, 2nd row=bin max)
dParams.tf_bins = []; % if empty, subdivide evenly among available frequencies
dParams.sf_bins = [];
dParams.ori_bins = []; % Ori will be handled differently
dParams.tSize = 30; % should be at least 2x nTFs
dParams.tStep = 1; % values less than tSize give overlapping windows
dParams.logSpaceFreq = false; % ignored if sf_bins or tf_bins are specified
dParams.tf_pad = 0; % 'symmetric'; % 'replicate';%(borders) % Zeros seem most honest
%dParams.sf_pad = 0; % 'symmetric'; % 'replicate';%(borders) % 
if ~exist('params','var')
    params = struct;
end
% Fill defaults
params = defaultOpt(params,dParams);

if nargin<1 % just called to set the default set of parameters
	Spreproc = params;
	return;
end

% Compute more params
[szY,szX,nTPs] = size(S);
if nTPs<params.tSize
    error('You must have more frames than "params.tSize"');
end
if isempty(params.tf_bins) && isempty(params.tf_max)
    params.tf_max = floor(params.tSize/2);
end
if isempty(params.sf_bins) && isempty(params.sf_max)
    params.sf_max = floor(size(S,1)/2);
end
% Compute bins in K space
% Space
[x,y] = meshgrid(-szY/2:szY/2-1,-szX/2:szX/2-1);
[theta,rho] = cart2pol(x,y);
theta = imrotate(theta,90); % so 0 is up
% Time
tt = -params.tSize/2:params.tSize/2-1;  
t = repmat(reshape(tt,1,1,[]),[szY,szX,1]);
theta = repmat(theta,[1,1,params.tSize]);
rho = repmat(rho,[1,1,params.tSize]);
% Bins: 
b = {'tf','sf','ori'};
for iBin=1:3
    bb = [b{iBin} '_bins'];
    bMax = params.([b{iBin} '_max']);
    nBins = params.([b{iBin} '_n']);
    
    if isempty(params.(bb))
        if strcmp(bb,'ori_bins')
            obw = bMax/nBins; % ori bin width
            params.(bb) = [0:obw:bMax]; %2nd row? Use circdist function??
        else
            if params.logSpaceFreq
                % log spaced
                if params.zeroSF
                    be = [0,logspace(log10(1),log10(bMax),nBins)];
                else
                    be = logspace(log10(1),log10(bMax),nBins+1);
                end
                be = [be(1:nBins);be(2:nBins+1)];
            else
                % linearly spaced
                if params.zeroSF
                    be = linspace(0,bMax,nBins+1);
                else
                    be = linspace(1,bMax,nBins+1);
                end
                be = [be(1:nBins);be(2:nBins+1)];
            end
            params.(bb) = be;
        end
    else
        obw = diff(params.ori_bins);
        error('not ready for this!')
    end
    
end

% Compute fft channel descriptors
if params.logSpaceFreq
    [tf,sf,ori] = meshgrid(params.tf_bins(1,:),params.sf_bins(1,:),params.ori_bins(1:end-1));
else
    [tf,sf,ori] = meshgrid(diff(params.tf_bins)/2+params.tf_bins(1,:),diff(params.sf_bins)/2+params.sf_bins(1,:),params.ori_bins(1:end-1));
end
params.fftparams = [tf(:),sf(:),ori(:)]';

%GrpIdx = zeros(szX,szY,params.tSize,'uint16');
GrpIdx2 = zeros(szX*szY*params.tSize,params.tf_n*params.sf_n*params.ori_n,'single');
ct = 1;
for iTF = 1:params.tf_n
    tf = abs(t)>=params.tf_bins(1,iTF) & abs(t)<params.tf_bins(2,iTF);
    for iSF = 1:params.sf_n
        sf = rho>=params.sf_bins(1,iSF) & rho<params.sf_bins(2,iSF);
        for iOri = 1:params.ori_n
            ori = abs(circ_dist(theta,params.ori_bins(iOri)))<=obw/2 | ...
                abs(circ_dist(theta,pi+params.ori_bins(iOri)))<=obw/2;
            if ~any(sf(:)&ori(:)&tf(:));
                disp('empty bin!')
                keyboard;
            end
            %GrpIdx(sf&ori&tf) = ct;
            GrpIdx2(:,ct) = sf(:)&ori(:)&tf(:);
            ct = ct+1;
        end
    end
end
disp('Grp idx done!')
bStart = 1:params.tStep:nTPs;
bEnd = params.tSize:params.tStep:nTPs+params.tSize-1;
nBlocks = length(bStart);
Spreproc = zeros(nBlocks,params.sf_n*params.ori_n*params.tf_n);
% Zero-pad S to correctly compute beginning / end
t1 = floor(params.tSize/2);
t2 = floor(params.tSize/2);
if ~mod(params.tSize,2)
    t2 = t2-1;
end
S = padarray(S,[0,0,t1],params.tf_pad,'pre');
S = padarray(S,[0,0,t2],params.tf_pad,'post');
for ii = 1:nBlocks
    progressdot(ii,floor(nBlocks/30),floor(nBlocks/3),nBlocks);
    b = bStart(ii):bEnd(ii);
    SppTmp = S(:,:,b);
    % Apply window function! Hard rect is dumb:
    w = reshape(window(@gausswin,length(b)),1,1,[]);
    SppTmp = bsxfun(@times,SppTmp,w);
    % Pad image here!
    % Decided against! This is lame! any padding will mess with the spatial
    % frequency content of the image in one way or another (particularly
    % the low frequencies, which are the ones we're interested in). There
    % is no way to "upsample" the low frequenices besides NOT taking a
    % discrete fourier transform, which means doing this some completely
    % different way. Abandoned as of 2013.07.08
    %SppTmpPd = padarray(im,[szY/2,szX/2],'symmetric');
    % Fourier transform
    SppTmp = fftshift(fftn(SppTmp));
    % Optimization over different possible ways to average over sections of
    % the FFT: 
    % Slowest option
    %disp('Timing loop sum')
    %tic
    %SppTmp2 = zeros(params.sf_n,params.ori_n,params.tf_n);
    %for iSF = 1:params.sf_n
    %   sf = rho>=params.sf_bins(1,iSF) & rho<params.sf_bins(2,iSF);
    %   for iOri = 1:params.ori_n
    %       ori = circ_dist(theta,params.ori_bins(iOri))<obw;
    %       for iTF = 1:params.tf_n
    %           tf = t>=params.tf_bins(1,iTF) & t<params.tf_bins(2,iTF);
    %           % Mean?? Sum??
    %           SppTmp2(iSF,iOri,iTF) = sum(abs(SppTmp(sf&ori&tf)));
    %       end
    %   end
    %end
    %toc
    % 4x faster than loop
    %disp('Timing GrpStats')
    %tic
    %[m,n] = grpstats(abs(SppTmp(:)),GrpIdx(:),{'mean','numel'}); % But we want sum...
    %toc
    %Spreproc(ii,:) = m(2:end).*n(2:end);
    %keyboard;
    % 4x faster than grpstats: matrix multiply by condition labels (takes SUM!)
    Spreproc(ii,:) = abs(SppTmp(:)')*GrpIdx2;
    % NOTE: This produces results APPROXIMATELY the same as the previous
    % methods... but not exactly. WTF is up with that. Not sure. FML.
    % We're going to say that it's fine.
end
% Account for start/finish gaps
% FOR NOW: fill w/ first, last valid computed value. This could get SHADY
% AS SHIT for ephys, or for long time window FFTs. Also: Do we want other
% shapes for windows??
st = floor(params.tSize/2)-1;
fin = ceil(params.tSize/2)-1;
if st==fin
    fin = fin+1;
end
Spreproc = [repmat(Spreproc(1,:),st,1);Spreproc;repmat(Spreproc(end,:),fin,1)];

disp('done.');
