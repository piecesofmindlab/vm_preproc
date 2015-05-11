function normBin = getSurroundIndices(nBinsX,nBinsY,Type,Neighborhood)
% Usage: normBin = getSurroundIndices(nBinsX,nBinsY,Type,Neighborhood)
% 
% Gets indices for surrounding points on a grid. Creates a T/F matrix that
% is (nBinsX*nBinsY) x (nBinsX*nBinsY) x nDiffSurrounds (The number of
% different surrounds varies with "Type")
% 
% Inputs: 
%   nBinsX,nBinsY = number of grid bins in X and Y dimensions. (stick with
%       square for now... 2012.05.14)
%   Type = 'CenterSurround' [default] or 'Corners' % More??
%   Neighborhood = 9; % 9 = all surrounding grid locations, including
%           diagonals (* shaped); 5 = only up & sides (+ shaped)
% 
% NOTE: It is possible to do much finer-grained normalization than this.
% Instead of using only gridded bins of orientations (or whatever), we can
% compute variable-sized bins of orientation (or whatever) in the original
% image, ONLY for the purpose of taking the (L2) norm and normalizing with
% respect to each different "context" or surround. 
% 
% The way THIS surround (model) works, the granularity of the surround is
% restricted by the granularity of the original model. 
% For a particular voxel (e.g.), we might see positive weights at one
% orientation and negative weights at orthogonal orientations around it for
% the STRF, which would capture *almost* the same thing as the
% non-linearity of the surround normalization, but with fewer parameters to
% fit. 
% The question is: is 
% a b c         [ e / (abde) ]
% d e f         substantially different from 
% g h i         [ e - (abd) ]        ?
%
% (that would make a good figure)
%
% ML 2012.05.14

% Inputs
if ~exist('Type','var')
    Type = 'Corners';
end
if ~exist('Neighborhood','var')
    Neighborhood = 9; % 5
end

% Create a grid of x,y (indices)
[xo,yo] = meshgrid(1:nBinsX,1:nBinsY);
% First, define coordinates for the 9 (or 5) bins surrounding each
% bin (some of which will will go outside the original data matrix,
% e.g. at corners)  
% 
% 1 2 3
% 4 5 6 ** bins are centered at 5
% 7 8 9
% 
% There must be a better way to do this, but this is easy:
switch Neighborhood
    case 9
        surroundBin = zeros(nBinsX*nBinsY,9,2);
        % up, left
        surroundBin(:,1,1) = yo(:)-1;
        surroundBin(:,1,2) = xo(:)-1;
        % up, centered
        surroundBin(:,2,1) = yo(:)-1;
        surroundBin(:,2,2) = xo(:);
        % up, right
        surroundBin(:,3,1) = yo(:)-1;
        surroundBin(:,3,2) = xo(:)+1;
        % left
        surroundBin(:,4,1) = yo(:);
        surroundBin(:,4,2) = xo(:)-1;
        % centered
        surroundBin(:,5,1) = yo(:);
        surroundBin(:,5,2) = xo(:);
        % right
        surroundBin(:,6,1) = yo(:);
        surroundBin(:,6,2) = xo(:)+1;
        % down, left
        surroundBin(:,7,1) = yo(:)+1;
        surroundBin(:,7,2) = xo(:)-1;
        % down, centered
        surroundBin(:,8,1) = yo(:)+1;
        surroundBin(:,8,2) = xo(:);
        % down, right
        surroundBin(:,9,1) = yo(:)+1;
        surroundBin(:,9,2) = xo(:)+1;
        idx = [1,2,4,5; % up-left
               2,3,5,6; % up-right
               4,5,7,8; % down-left
               5,6,8,9]; % down-right
    case 5
        surroundBin = zeros(nBinsX*nBinsY,9,2);
        % centered
        surroundBin(:,1,1) = yo(:);
        surroundBin(:,1,2) = xo(:);
        % up
        surroundBin(:,2,1) = yo(:)-1;
        surroundBin(:,2,2) = xo(:);
        % right
        surroundBin(:,3,1) = yo(:);
        surroundBin(:,3,2) = xo(:)+1;
        % down
        surroundBin(:,4,1) = yo(:)+1;
        surroundBin(:,4,2) = xo(:);
        % left
        surroundBin(:,5,1) = yo(:);
        surroundBin(:,5,2) = xo(:)-1;
        idx = [1,2,5; % up-left
               1,2,3; % up-right
               1,4,5; % down-left
               1,4,3]; % down-right
end
switch lower(Type)
    case 'corners'
        normBin = false(nBinsX*nBinsY,nBinsX*nBinsY,4);
        for iGridElement = 1:nBinsX*nBinsY
            for i4 = 1:4
                % specifies which "corner" to choose
                i = idx(i4,:); 
                % get 4 indices for 4 bins in that "corner"
                tmpI = squeeze(surroundBin(iGridElement,i,:)); 
                % Make sure all tmpI are >0, <= nBinsX,nBinsY
                tmpI = tmpI(all(tmpI>0 & tmpI <= nBinsX,2),:);
                ttmpI = sub2ind([nBinsX,nBinsY],tmpI(:,1),tmpI(:,2));
                normBin(iGridElement,ttmpI,i4) = true;
            end
        end
    case 'centersurround'
        normBin = false(nBinsX*nBinsY,nBinsX*nBinsY);
        for iGridElement = 1:nBinsX*nBinsY
            i = 1:Neighborhood;
            tmpI = squeeze(surroundBin(iGridElement,i,:));
            % Make sure all tmpI are >0, <= nBinsX,nBinsY
            tmpI = tmpI(all(tmpI>0 & tmpI <= nBinsX,2),:);
            ttmpI = sub2ind([nBinsX,nBinsY],tmpI(:,1),tmpI(:,2));
            normBin(iGridElement,ttmpI) = true;
        end
end