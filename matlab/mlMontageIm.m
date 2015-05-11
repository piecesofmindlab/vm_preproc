function im = mlMontageIm(fD,ImSz,Opt)
% Usage: mlMontageIm(fD,ImSz);
% 
% Plot montage of test images
% 
% Specifically designed for BVP directories; needs update to be general
% 
% Should include a wildcard component for image type (see example).
% 
% Optional "Opt" struct clarifies other options: 
%   .Is_Show = false; % whether to show image in figure
%   .txtCol = 'y'; % color of text labels (numbers) for each image
%   .cMap = gray(256); % color map for zdepth images
%   .Is_Normal = false; % whether .hdr images are normal images (default =
%       false, meaning they are z depth images)
%   .sName = save name for generated image
% Example: 
% fD = '/auto/k6/mark/BVPpilot3_Stimuli_Run1/Scenes/*png';
% im = mlMontageIm(fD,ImSz)
%
% ML 2012.03.28

% Inputs
if ~exist('ImSz','var')||isempty(ImSz)
    ImSz = [256,256];
end
o.Is_Show = false;
o.txtCol = 'y';
o.cMap = gray(256);
o.Is_Normal = false;
if exist('Opt','var')
    Opt = mlFillStruct(Opt,o,true);
else
    Opt = o;
end

if all(size(ImSz)==[1,1])
    ImSz = [ImSz,ImSz];
end
[fDir,ext] = fileparts(fD);
fType = strrep(ext,'*','')
fNm = dir(fD);
fNm = {fNm.name}';
im = zeros([ImSz,3,length(fNm)],'uint8');
nIms = length(fNm);
try
    for ii = 1:nIms; 
        progressdot(ii,20,200,nIms);       
        switch fType
            case 'hdr'
                if Opt.Is_Normal
                    tmp = hdr2normals(fullfile(fDir,fNm{ii}));
                else
                    params.ImSz = ImSz;
                    params.type = 'MedianNorm_1-1/z';
                    tmp = hdr2zDepth(fullfile(fDir,fNm{ii}),params);
                    cax = [min(tmp(:)),max(tmp(:))];
                    [hst,idx] = histc(tmp,linspace(cax(1),cax(2),257));
                    RGB = ind2rgb(idx,Opt.cMap);
                    tmp = uint8(255*RGB);
                end 
            otherwise
                % all image formats
                [tmp,map,alph] = imread(fullfile(fDir,fNm{ii}));
        end
        im(:,:,:,ii) = imresize(tmp,ImSz);
    end
catch
    mlErrorCleanup;
    rethrow(lasterror)
end

if Opt.Is_Show
    f = figure;
    montage(im);
    set(gca,'position',[0 0 1 1])
    axis image off;
    [dx,dy] = mlFindSquareishDimensions(nIms);
    [x,y] = meshgrid(ImSz(1)*.1:ImSz(1):ImSz(1)*dy,ImSz(2)*.1:ImSz(2):ImSz(2)*dx);
    x = x(1:nIms);
    y = y(1:nIms);
    txt = cell(nIms,1);
    for ii = 1:nIms
        txt{ii} = num2str(ii);
    end
    text(y,x,txt,'color',Opt.txtCol);
end
if isfield(Opt,'sName')
    mlFigure(f,[dx,dy])
    print(sprintf('-f%d',f),'-dpng','-r128',Opt.sName);
end