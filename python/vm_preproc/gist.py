def preproc_gist(S, 
    image_size=None, 
    orientations_per_scale=(8,8,8,8),
    number_blocks=4,
    fc_prefilt=4,
    boundary_extension=32):
# Note: n_resize is set to 128, boundary_extension is set to that // 4 or 32, 
# unclear which is better to set. 

    """ compute gist features a la Oliva & Torralba 2001

    Preprocess image stack with gist model. Based on A. Oliva & A. Torralba's
    LMgist code (WEB SITE), see references below

    Parameters
    ----------
    S : 3D image matrix (Time, X,Y)
      Stack of images to be processed, should also be
      luminance images - process/remove color before getting here! 
    image_size : nan
          Size to which to resize images; if values is nan, or if field:
          is removed, input images are not resized. Default = nan
      orientations_per_scale = [8 8 8 8]
      number_blocks = 4
      fc_prefilt = 4
      boundary_extension : int
           number of pixels to pad

    Returns
    -------
    References
    ----------
    Modeling the shape of the scene: a holistic representation of the spatial envelope
    Aude Oliva, Antonio Torralba
    International Journal of Computer Vision, Vol. 42(3): 145-175, 2001.
    """

    # resize and crop image to make it square
    if image size is None:
        image_size = S.shape[1:3]
        img = S
    else:
        # TO DO.
        img = imresizecrop(S, image_size, 'bilinear')

    # Define Gabors
    G = create_gabor(orientations_per_scale, image_size + 2 * boundary_extension)

    # Precompute number of filter transfer functions 
    #Nfeatures = size(G,3)*number_blocks^2
    #Spreproc = zeros([Nscenes Nfeatures], 'single')

    # scale intensities to be in the range [0 255]
    img = img - img.min()
    img = 255 * img / img.max()
    # prefiltering: local contrast scaling
    output    = prefilt(img, fc_prefilt)
    # compute gist:
    Spreproc = gist_gabor(output, G=G).T

"""
def prefilt(img, fc=4, n_pad=5):
    # ima = prefilt(img, fc)
    # fc  = 4 (default)
    # 
    # Input images are double in the range [0, 255]
    # You can also input a block of images [ncols nrows 3 Nimages]
    #
    # For color images, normalization is done by dividing by the local:
    # luminance variance.
    
    s1 = fc / np.sqrt(np.log(2))

    # Pad images to reduce boundary artifacts
    img = np.log(img + 1)
    #img = padarray(img, [n_pad n_pad], 'symmetric')
    img = np.pad(img, [(0,0), (n_pad n_pad), (n_pad n_pad)], mode='reflect')
    #[sn, sm, c, N] = size(img)
    N, sn, sm, c = img.shape
    n = np.max([sn, sm])
    n = n + np.mod(n, 2)
    #img = padarray(img, [n-sn n-sm], 'symmetric','post')
    img = padarray(img, [n-sn n-sm], 'symmetric','post')

    # Filter
    [fx, fy] = meshgrid(-n/2:n/2-1)
    gf = fftshift(exp(-(fx.^2+fy.^2)/(s1^2)))
    gf = repmat(gf, [1 1 c N])

    # Whitening
    output = img - real(ifft2(fft2(img).*gf))
    clear img

    # Local contrast normalization
    localstd = repmat(sqrt(abs(ifft2(fft2(mean(output,3).^2).*gf(:,:,1,:)))), [1 1 c 1]) 
    output = output./(.2+localstd)

    # Crop output to have same size as the input
    output = output[n_pad + 1: sn - n_pad, n_pad+1:sm-n_pad,:,:]
    return output
"""
def prefilt(img, fc_prefilt=4, n_pad=5):
    log_img = np.log(img + 1.0)
    pad_img = np.pad(log_img,((n_pad,n_pad), (n_pad,n_pad)), 'symmetric')

    ##
    # gf...
    n_s1 = fc_prefilt / np.sqrt(np.log(2))
    n_boundary = n_resize + 2 * n_pad
         
        np_linear = np.linspace(-n_boundary//2, n_boundary//2-1, n_boundary)
        np_fx, np_fy = np.meshgrid(np_linear, np_linear)
        
#        np_gf = np.fft.fftshift(np.exp( -(np_fx **2 + np_fy **2)/(n_s1 ** 2)))
        self.np_gf = np.fft.fftshift(np.exp( -(np_fx **2 + np_fy **2)/(n_s1 ** 2)))
    ###    

    gf = self.gf
    out = pad_img - np.real(np.fft.ifft2(np.fft.fft2(pad_img) * gf ))
    
    local = np.sqrt(np.abs(np.fft.ifft2(np.fft.fft2(out **2) * gf)))
    out = out / (0.2 + local)
    
    n_size = self.n_resize + 2 * n_pad
    
    return out[n_pad: n_size - n_pad, n_pad : n_size - n_pad]




def gist_gabor(img, params):
    # 
    # Input:
    #   img = input image (it can be a block: [nrows, ncols, c, Nimages])
    #   w = number of windows (w*w)
    #   G = precomputed transfer functions
    #
    # Output:
    #   g: are the global features = [Nfeatures Nimages], 
    #                    Nfeatures = w*w*Nfilters*c

    img = single(img)

    w = number_blocks
    G = G
    be = boundary_extension
    switch ndims(img)
        case {2,3}
            # For now: assume 3D images are stacks of luminance images (unless:
            # c==3, then assume a single color image, handled below)
            [~,~,c] = size(img)
            N = c
        case 4
            # For a stack of color images, treat color channels as separate images.:
            [nrows,ncols,c,N] = size(img)
            img = reshape(img, [nrows ncols c*N])
            N = c*N


    [ny,nx,Nfilters] = size(G)
    W = w*w
    g = zeros([W*Nfilters N])

    # pad image
    img = padarray(img, [be be], 'symmetric')

    img = single(fft2(img)) 
    k=0
    for n = 1:Nfilters:
        # Display progress through filters
        progressdot(n,10,100,Nfilters)

        ig = abs(ifft2(img.*repmat(G(:,:,n), [1 1 N]))) 
        ig = ig(be+1:ny-be, be+1:nx-be, :)
        
        v = downN(ig, w)
        g(k+1:k+W,:) = reshape(v, [W N])
        k = k + W
        drawnow


    if c == 3:
        # If the input was a color image, then reshape 'g' so that one column:
        # is one images output:
        g = reshape(g, [size(g,1)*3 size(g,2)/3])

    return g


def = downN(x, N):
    # averaging over non-overlapping square image blocks
    #
    # Input
    #   x = [nrows ncols nchanels]
    # Output
    #   y = [N N nchanels]

    nx = fix(linspace(0,size(x,1),N+1))
    ny = fix(linspace(0,size(x,2),N+1))
    y  = zeros(N, N, size(x,3))
    for xx=1:N:
      for yy=1:N:
        v=mean(mean(x(nx(xx)+1:nx(xx+1), ny(yy)+1:ny(yy+1),:),1),2)
        y(xx,yy,:)=v(:)




def create_gabor(or, n):
#
# G = create_gabor(numberOforientations_per_scale, n)
#
# Precomputes filter transfer functions. All computations are done on the
# Fourier domain. 
#
# If you call this function without output arguments it will show the:
# tiling of the Fourier domain.
#
# Input
#     numberOforientations_per_scale = vector that contains the number of
#                                orientations at each scale (from HF to BF)
#     n = image_size = [nrows ncols] 
#
# output
#     G = transfer functions for a jet of gabor filters:


Nscales = length(or)
Nfilters = sum(or)

if length(n) == 1:
    n = [n(1) n(1)]

l=0
for i=1:Nscales:
    for j=1:or(i):
        l=l+1
        params(l,:)=[.35 .3/(1.85^(i-1)) 16*or(i)^2/32^2 pi/(or(i))*(j-1)]


# Frequencies:
#[fx, fy] = meshgrid(-n/2:n/2-1)
[fx, fy] = meshgrid(-n(2)/2:n(2)/2-1, -n(1)/2:n(1)/2-1)
fr = fftshift(sqrt(fx.^2+fy.^2))
t = fftshift(angle(fx+sqrt(-1)*fy))

# Transfer functions:
G=zeros([n(1) n(2) Nfilters])
for i=1:Nfilters:
    tr=t+params(i,4) 
    tr=tr+2*pi*(tr<-pi)-2*pi*(tr>pi)

    G(:,:,i)=exp(-10*params(i,1)*(fr/n(2)/params(i,2)-1).^2-2*params(i,3)*pi*tr.^2)


if nargout == 0:
    figure
    for i=1:Nfilters:
        contour(fx, fy, fftshift(G(:,:,i)),[1 .7 .6],'r')
        hold on

    axis('on')
    axis('equal')
    axis([-n(2)/2 n(2)/2 -n(1)/2 n(1)/2])
    axis('ij')
    xlabel('f_x (cycles per image)')
    ylabel('f_y (cycles per image)')
    grid on



## Hmmm - resizing...
def img_resize(np_img_in, ln_resize, run_log=None, b_print=False):
    try:
        np_img_resize = cv2.resize(np_img_in, ln_resize, fx=0.5, fy=0.5, interpolation=cv2.INTER_AREA)
        return np_img_resize, 0
    except Exception as e:
        s_msg = 'resize err:%s' % str(e)
        run_log and run_log.error(s_msg)
        b_print and print(s_msg)
        return None, -3