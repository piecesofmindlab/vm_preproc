function [I2,locations] = imfill_fast(I,locations,conn)
%IMFILL Fill image regions and holes.
%   MODIFICATION by ML: no parsing of inputs
%   BW2 = IMFILL(BW1,LOCATIONS) performs a flood-fill operation on
%   background pixels of the input binary image BW1, starting from the
%   points specified in LOCATIONS.  LOCATIONS can be a P-by-1 vector, in
%   which case it contains the linear indices of the starting locations.
%   LOCATIONS can also be a P-by-NDIMS(IM1) matrix, in which case each row
%   contains the array indices of one of the starting locations.
%
%   BW2 = IMFILL(BW1,'holes') fills holes in the input image.  A hole is
%   a set of background pixels that cannot be reached by filling in the
%   background from the edge of the image.
%
%   I2 = IMFILL(I1) fills holes in an intensity image, I1.  In this
%   case a hole is an area of dark pixels surrounded by lighter pixels.
%
%   Interactive use
%   ---------------
%   BW2 = IMFILL(BW1) displays BW1 on the screen and lets you select the
%   starting locations using the mouse.  Use normal button clicks to add
%   points. Press <BACKSPACE> or <DELETE> to remove the previously selected
%   point.  A shift-click, right-click, or double-click selects a final
%   point and then starts the fill; pressing <RETURN> finishes the selection
%   without adding a point.  Interactive use is supported only for 2-D images.
%
%   The syntax [BW2,LOCATIONS] = IMFILL(BW1) can be used to get the starting
%   points selected using the mouse.  The output LOCATIONS is always in the
%   form of a vector of linear indices into the input image.
%
%   Specifying connectivity
%   -----------------------
%   By default, IMFILL uses 4-connected background neighbors for 2-D
%   inputs and 6-connected background neighbors for 3-D inputs.  For
%   higher dimensions the default background connectivity is
%   CONNDEF(NUM_DIMS,'minimal').  You can override the default
%   connectivity with these syntaxes:
%
%       BW2 = IMFILL(BW1,LOCATIONS,CONN)
%       BW2 = IMFILL(BW1,CONN,'holes')
%       I2  = IMFILL(I1,CONN)
%
%   To override the default connectivity and interactively specify the
%   starting locations, use this syntax:
%
%       BW2 = IMFILL(BW1,0,CONN)
%
%   CONN may have the following scalar values:
%
%       4     two-dimensional four-connected neighborhood
%       8     two-dimensional eight-connected neighborhood
%       6     three-dimensional six-connected neighborhood
%       18    three-dimensional 18-connected neighborhood
%       26    three-dimensional 26-connected neighborhood
%
%   Connectivity may be defined in a more general way for any dimension by
%   using for CONN a 3-by-3-by- ... -by-3 matrix of 0s and 1s.  The 1-valued
%   elements define neighborhood locations relative to the center element of
%   CONN.  CONN must be symmetric about its center element.
%
%   Class Support
%   -------------
%   The input image can be numeric or logical, and it must be real and
%   nonsparse.  It can have any dimension.  The output image has the
%   same class as the input image.
%
%   Examples
%   --------
%   Fill in the background of a binary image from a specified starting
%   location:
%
%       BW1 = logical([1 0 0 0 0 0 0 0
%                      1 1 1 1 1 0 0 0
%                      1 0 0 0 1 0 1 0
%                      1 0 0 0 1 1 1 0
%                      1 1 1 1 0 1 1 1
%                      1 0 0 1 1 0 1 0
%                      1 0 0 0 1 0 1 0
%                      1 0 0 0 1 1 1 0]);
%       BW2 = imfill(BW1,[3 3],8)
%
%   Fill in the holes of a binary image:
%
%       BW4 = im2bw(imread('coins.png'));
%       BW5 = imfill(BW4,'holes');
%       figure, imshow(BW4), figure, imshow(BW5)
%
%   Fill in the holes of an intensity image:
%
%       I = imread('tire.tif');
%       I2 = imfill(I,'holes');
%       figure, imshow(I), figure, imshow(I2)
%
%   See also BWSELECT, IMRECONSTRUCT, ROIFILL.

%   Copyright 1993-2010 The MathWorks, Inc.
%   $Revision: 1.10.4.14 $  $Date: 2011/08/09 17:50:48 $
    
% Grandfathered syntaxes:
% IMFILL(I1,'holes') - no longer necessary to use 'holes'
% IMFILL(I1,CONN,'holes') - no longer necessary to use 'holes'

% Testing notes
% =============
% I            - real, full, nonsparse, numeric array, any dimension
%              - Infs OK
%              - NaNs not allowed
%
% CONN         - valid connectivity specifier
%
% LOCATIONS    - the value 0 is used as a flag to indicate interactive
%                selection
%              - can be either a P-by-1 double vector containing
%                valid linear indices into the input image, or a 
%                P-by-ndims(I) array.  In the second case, each row
%                of LOCATIONS must contain a set of valid array indices
%                into the input image.
%              - can be empty.
%
% 'holes'      - match is case-insensitive; partial match allowed.
%
% If 'holes' argument is not provided, then the input image must be
% binary.

if ~exist('conn','var')
    conn = 8;
%     conn = [0     1     0
%             1     1     1
%             0     1     0];
end        
mask = imcomplement(I);
marker = mask;
marker(:) = 0;
marker(locations) = mask(locations);
%fD = fileparts(which('imreconstruct.m'))
%SUPERPRIVATEPATH = fullfile(fD,'private/');
%addpath(SUPERPRIVATEPATH);
% Want to do this, but can't for some bullshit path reason...
%marker = imreconstructmex(marker,mask,conn); %imreconstruct(marker,mask,conn);
% So shit, live with this:
marker = imreconstruct(marker,mask,conn);
%rmpath(SUPERPRIVATEPATH)
I2 = I | marker;
