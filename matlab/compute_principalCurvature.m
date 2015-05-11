function [kMin,dMin,kMax,dMax] = compute_principalCurvature(X,Y,Z,ReturnVector)
% Usage: [kMin,dMin,kMax,dMax] = compute_principalCurvature(X,Y,Z [,ReturnVector])
% 
% Compute principal curvatures of a surface. 
% 
% Inputs: 
%   X = 2D matrix of x coordinates of a surface
%   Y = 2D matrix of y coordinates of a surface
%   Z = 2D matrix of z coordinates of a surface
%   ReturnVector (optional) = Boolean T/F, if true returns the principal
%       directions as [u,v] vectors instead of angles projected into 2D
% 
% Outputs: 
%   kMin = minimum curvature at each pixel
%   dMin = direction (vector/ projected angle) of minimum curvature as
%       a 2D angle (measured from X [u] axis)
%   kMax = maximum curvature at each pixel
%   dMax = direction (vector/ projected angle) of maximum curvature as
%       a 2D angle (measured from X [u] axis)
%       
% ** (u,v) most often maps to (x,y) for the original applications of this
% code, because the "surface" for which the curvature was being computed
% was the "projected curvature" of the Z depth buffer; thus Z was always
% the depth axis, X and Y were the "screen" axes. NOT SURE how this will
% change the interpretation of the [u,v] coordinates with other surfaces,
% e.g. objects. Depends on [u,v] parameterization of the surfaces!
% 
% Note: Gaussian curvature (K) = kMin.*kMax;
%       Mean curvature (H) = (kMin+kMax)/2;
% 
% 2012.11.21 M.L., with thanks to surfature.m by Daniel Claxton
% (http://www.mathworks.com/matlabcentral/fileexchange/11168-surface-curvature)
% 

% Inputs
if ~exist('ReturnVector','var')
    ReturnVector = false;
end

sz = size(X);
if ~all(size(Y)==sz) || ~all(size(Z)==sz)
    error(['unequal sized inputs to ' mfilename '!']);
end

% First Derivatives
[Xu,Xv] = gradient(X);
[Yu,Yv] = gradient(Y);
[Zu,Zv] = gradient(Z);

% Second Derivatives
[Xuu,Xuv] = gradient(Xu);
[Yuu,Yuv] = gradient(Yu);
[Zuu,Zuv] = gradient(Zu);

[Xuv,Xvv] = gradient(Xv);
[Yuv,Yvv] = gradient(Yv);
[Zuv,Zvv] = gradient(Zv);

% Reshape 2D Arrays into Vectors
Xu = Xu(:);   Yu = Yu(:);   Zu = Zu(:); 
Xv = Xv(:);   Yv = Yv(:);   Zv = Zv(:); 
Xuu = Xuu(:); Yuu = Yuu(:); Zuu = Zuu(:); 
Xuv = Xuv(:); Yuv = Yuv(:); Zuv = Zuv(:); 
Xvv = Xvv(:); Yvv = Yvv(:); Zvv = Zvv(:); 

Xu          =   [Xu Yu Zu];
Xv          =   [Xv Yv Zv];
Xuu         =   [Xuu Yuu Zuu];
Xuv         =   [Xuv Yuv Zuv];
Xvv         =   [Xvv Yvv Zvv];

% First fundamental Coeffecients of the surface (E,F,G)
E           =   dot(Xu,Xu,2);
F           =   dot(Xu,Xv,2);
G           =   dot(Xv,Xv,2);

m           =   cross(Xu,Xv,2);
p           =   sqrt(dot(m,m,2));
n           =   m./[p p p]; 

% Second fundamental Coeffecients of the surface (L,M,N)
L           =   dot(Xuu,n,2); % e
M           =   dot(Xuv,n,2); % f -> in wikipedia notation
N           =   dot(Xvv,n,2); % g 
[s,t] = size(Z);

% Gaussian Curvature
K = (L.*N - M.^2)./(E.*G - F.^2);
K = reshape(K,s,t);

% Mean Curvature
H = (E.*N + G.*L - 2.*F.*M)./(2*(E.*G - F.^2));
H = reshape(H,s,t);

% Principal Curvatures (This works, but only here for checking for now)
Pmax = H + sqrt(H.^2 - K);
Pmin = H - sqrt(H.^2 - K);

% Principal Directions
% Weingarten equations for "Shape Operator":
rs = @(x) reshape(x,1,1,[]);
S = [rs(L).*rs(G)-rs(M).*rs(F), rs(M).*rs(G)-rs(N).*rs(F);
     rs(M).*rs(E)-rs(L).*rs(F), rs(N).*rs(E)-rs(M).*rs(F)];
S = bsxfun(@rdivide,S,(rs(E).*rs(G)-rs(F).^2));
% Take eigen-decomposition of each 2x2 matrix in S:
WhichEig = 'efficient';
switch WhichEig
    case 'obvious'
        tic
        eV = zeros(size(S,3),2,2);
        MnMxCurv = zeros(size(S,3),2);
        for iS = 1:size(S,3)
            [eVec,eVal] = eig(S(:,:,iS));
            % Max/min curvature are not necessarily 1st or 2nd eigenvector/value.
            % So, figure out which is which:
            [eVal,idx] = sort(diag(eVal)); % [Min,max]
            eV(iS,:,:) = real(eVec(:,idx)); % This has a small rounding error; fuck it.
            MnMxCurv(iS,:) = real(eVal);
        end
        toc
        % NOTE! Somehow the +/- of the eigen vectors come out differently
        % (opposite?) between these two methods of computation. This is WAY
        % (>50x) slower, do not use this - it's just here to give you a
        % sense of what is going on in the efficient computation below.
    case 'efficient'
        %tic
        % Efficient computation of eigendecomposition: Closed-form algebraic solution 
        % (See: http://www.math.harvard.edu/archive/21b_fall_04/exhibits/2dmatrices/index.html) 
        % Re-label for clarity:
        a = squeeze(S(1,1,:));
        b = squeeze(S(1,2,:));
        c = squeeze(S(2,1,:));
        d = squeeze(S(2,2,:));
        % determinant
        D = a.*d-b.*c;
        % trace
        T = a+d; 
        % Eigenvalues
        L1 = T/2-(T.^2/4-D).^.5;
        L2 = T/2+(T.^2/4-D).^.5;
        % (Already sorted)
        MnMxCurv = real([L1,L2]);
        % Eigenvectors
        % Case 1
        eV = zeros([2,2,size(MnMxCurv,1)]);
        eV(1,1,c~=0) = L1(c~=0)-d(c~=0);
        eV(1,2,c~=0) = L2(c~=0)-d(c~=0);
        eV(2,1,c~=0) = c(c~=0);
        eV(2,2,c~=0) = c(c~=0);
        % Case 2 (may be overlapping - fine)
        ii = c==0 & b~=0;
        eV(1,1,ii) = b(ii);
        eV(1,2,ii) = b(ii);
        eV(2,1,ii) = L1(ii)-a(ii);
        eV(2,2,ii) = L2(ii)-a(ii);
        % Case 3
        ii = c==0 & b==0;
        eV(:,:,ii) = repmat(eye(2),[1,1,sum(ii)]);
        % Normalize (not strictly necessary... but what the hell)
        eV = eV./repmat(sum(eV.^2,1).^.5,[2,1,1]);
        eV = permute(eV,[3,1,2]);
        eV = real(eV);
        %toc
end
% Note: Checked:
% max(MnMxCurv(:,1)-Pmin(:)) % = 1e-15 + 1e-8i
% max(MnMxCurv(:,2)-Pmax(:)) % = 1e-15 + 1e-8i % Meaning: equal.
kMin = reshape(MnMxCurv(:,1),sz);
kMax = reshape(MnMxCurv(:,2),sz);

if ~ReturnVector
    %tic
    % Compute angle of each vector from X axis [in 2D]
    dMax = zeros(size(eV,1),1);
    dMin = zeros(size(eV,1),1);
    
    %for iS = 1:size(S,3)
        % Arctangent of Y/X
        dMin(:) = (atand(eV(:,2,1)./eV(:,1,1))+90); % -90 b/c these scenes are upside down (ij, image coordinates)
        dMax(:) = (atand(eV(:,2,2)./eV(:,2,1))+90);
        % as of 2012.11.25, I think that atan2 is NOT necessary; the
        % direction defines a tangent vector, which (in combination with
        % the surface normal at that point) defines a plane; thus, 180deg
        % == 360deg, and atan == atan2. (-2/-3 == 2/3).
        % Long story short: it only makes sense to define the direction of
        % 3D curvature up to 180 degrees.
    %end
    dMin = reshape(dMin,sz);
    dMax = reshape(dMax,sz);
    %toc
else
    dMin = reshape(eV(:,:,1),[sz,2]);
    dMax = reshape(eV(:,:,2),[sz,2]);
end
