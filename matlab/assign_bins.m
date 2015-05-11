function [BinnedData,Xc,Yc,Sz] = assign_bins(ImData,params)
% Usage: [BinnedData,Xc,Yc,Sz] = assign_bins(ImData,params)
% 
% Assigns values computed in an image to spatial bins. 
% Returns "BinnedData", along with X and Y centers of bins (Xc,Yc)
% This code was written to make bins of orientation energy for Histograms
% of Gradients (HoG - Dalal & Triggs, 2005), but ImData can be any
% quantity. General principle should be to quantize features over whatever
% third dimension (orientation, normals, curvature, texture, etc), and this
% will divide whatever quantities among (2D) spatial bins. 
% 
% Inputs: 
%
% ImData = multi-dimensional image data to be binned according to
%   parameters in "params" struct. 
% 
% params = a struct with the fields: 
%   .nSpatBins = 9; number of spatial bins across whatever size the image
%       is. Assumes square images as of 2012.04.03
%   .nSubBins = 1; see note below 
%   .histWtScale = computed to be neutral (no effect) unless it is
%       specified. Specify as a multiple as of 
%   .Use_Gaussian_Bins = false; 
%
% Output: 
% 
% BinnedData = [params.nSpatBins x params.nSpatBins x size(ImData,3) x
%       params.nSubBins x params.nSubBins]
% Xc = X centers of HoG bins
% Yc = Y centers of HoG bins
% 
% ML 2012.04.03 - based heavily on Lubomir Bourdev's HoG implementation for
% poselets (http://www.eecs.berkeley.edu/~lbourdev/poselets/)
% 
% NOTE: Not sure that nSubBins does what it's supposed to. Best to keep it
% set to 1 for now (i.e., no overlap in bins). Also, for a given pixel
% in the original image, it seems that it only adds the values in that
% pixel to the bin immediately surrounding it (rather than proportionally
% to the nearest 4 bins, as bilinear interpolation would dictate)

pDefault.nSpatBins = 9;
pDefault.nSubBins = 1;
pDefault.histWtScale = nan;
pDefault.Use_Gaussian_Bins = false;
% Inputs
if ~exist('params','var')
    params = struct;
end
% Fill in default options
params = defaultOpt(params,pDefault);
[H,W,nCh] = size(ImData); 
if H ~= W
    error('Can''t handle non-square images yet!')
end
binSz = H / params.nSpatBins;
if binSz == floor(binSz)
    % always allow room at edges
    binSz = binSz-1; 
end
binSz = floor(binSz);
% For weighting by Gaussian bins
%var2 = params.HOG_CELL_DIMS(1:2)/(2*params.histWtScale);
if isnan(params.histWtScale)
    params.histWtScale = binSz/2; % ? 
end
var2 = [binSz,binSz]/(2*params.histWtScale);
var2 = (var2.*var2*2);

nSubBins = [params.nSubBins,params.nSubBins];
binDims = [binSz,binSz];
half_bin = nSubBins/2;
cenBand = binDims/2;
bandwidth = binDims ./ nSubBins;

binDim = [binSz,binSz];
% number of overlapping bins? Stride length?
ptBins = [params.nSubBins,params.nSubBins];

num_cells = [params.nSpatBins,params.nSpatBins]; %floor(([W H]-2)./bandwidth(1:2)) - nSubBins(1:2)+1;
samples_x = (0:(num_cells(1)-1))*bandwidth(1);
samples_y = (0:(num_cells(2)-1))*bandwidth(2);

% Sampling points across image:
%samples_x = (0:((params.nSpatBins*params.nSubBins)-1))*bandwidth(1);
%samples_y = (0:((params.nSpatBins*params.nSubBins)-1))*bandwidth(2);

% D&T Move the grid to the right
%offset = floor(mod([H W],bandwidth(1:2))/2);
offset = floor(([W H] - [samples_x(end) samples_y(end)] - binDims(1:2))/2);
%offset = floor(([W H] - [samples_x(end) samples_y(end)] - bandwidth(1:2))/2);

samples_x=samples_x+offset(1);
samples_y=samples_y+offset(2);
% store bin locations, as % of space across image:
[Xc,Yc] = meshgrid(samples_x+binSz/2,samples_y+binSz/2);
Xc = repmat(Xc(:),size(ImData,3),1) / size(ImData,1);
Yc = repmat(Yc(:),size(ImData,3),1) / size(ImData,2);
Sz = repmat(binSz/size(ImData,1),length(Xc),1);
% ct = 1;
BinnedData = zeros([num_cells(2:-1:1) size(ImData,3) nSubBins(1:2)]);
for x=1:binDim(1)
   for y=1:binDim(2)
       if ~params.Use_Gaussian_Bins
           w=1;
       else
           w = exp(-sum((([x y]-1 - binDim(1:2)/2).^2)./var2));
           ww(x,y) = w;
       end
       pt = half_bin(1:2) - 0.5 + ([x y]-0.5 - cenBand(1:2))./bandwidth(1:2);
       xy_bin_frac = pt - floor(pt);
       xyf(:,x,y) = xy_bin_frac; % for debugging
       xy_bin_floor = floor(pt)+1;
       xybfl(:,x,y) = xy_bin_floor;
       xy_bin_ceil = xy_bin_floor+1;
       xybce(:,x,y) = xy_bin_ceil;
       weight = ImData(samples_y+y,samples_x+x,:)*w;
       % The following lines implement assignment of orientation "energy"
       % to the nearest bins (a fraction of the total orientation energy
       % will go to each of the nearest bins)
       % Note 2012.04.03: This is NOT exactly linear interpolation, as
       % prescribed by Dalal & Triggs; it seems to be a Gaussian-like
       % window applied WITHIN each bin.
       
       % update floor,floor       
       if xy_bin_floor(1)>0 && xy_bin_floor(2)>0
           %flfl(ct,:) = [x,y];
           %flfl_fr(x,y) = (1-xy_bin_frac(1))*(1-xy_bin_frac(2));
           BinnedData(:,:,:,xy_bin_floor(2),xy_bin_floor(1)) = BinnedData(:,:,:,xy_bin_floor(2),xy_bin_floor(1)) + weight*( ((1-xy_bin_frac(1))*(1-xy_bin_frac(2))));               
       end

       % update floor,ceil       
       if xy_bin_floor(1)>0 && xy_bin_ceil(2)<=nSubBins(2)
           %flce(ct,:) = [x,y];
           %flce_fr(x,y) = ((1-xy_bin_frac(1))*   xy_bin_frac(2));
           BinnedData(:,:,:,xy_bin_ceil(2), xy_bin_floor(1)) = BinnedData(:,:,:,xy_bin_ceil(2),xy_bin_floor(1) ) + weight*( ((1-xy_bin_frac(1))*   xy_bin_frac(2)));
        end

       % update ceil,floor
       if xy_bin_ceil(1)<=nSubBins(1) && xy_bin_floor(2)>0
           %cefl(ct,:) = [x,y];
           %cefl_fr(x,y) = xy_bin_frac(1) *(1-xy_bin_frac(2));
           BinnedData(:,:,:,xy_bin_floor(2),xy_bin_ceil(1) ) = BinnedData(:,:,:,xy_bin_floor(2),xy_bin_ceil(1) ) + weight*(     xy_bin_frac(1) *(1-xy_bin_frac(2)));               
       end
       
       % update ceil,ceil
       if xy_bin_ceil(1)<=nSubBins(1) && xy_bin_ceil(2)<=nSubBins(2)
           %cece(ct,:) = [x,y];
           %cece_fr(x,y) = xy_bin_frac(1) *   xy_bin_frac(2);
           BinnedData(:,:,:,xy_bin_ceil(2) , xy_bin_ceil(1)) = BinnedData(:,:,:,xy_bin_ceil(2) ,xy_bin_ceil(1) ) + weight*(     xy_bin_frac(1) *   xy_bin_frac(2));
       end
       %ct = ct+ 1;
   end
   %keyboard
end
