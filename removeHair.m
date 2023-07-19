function [orig, img_new] = removeHair(filename, varargin)
p = inputParser;
validRect = @(x) isnumeric(x) && numel(x) == 4;
validChannel = @(x) (ischar(x) || isnumeric(x));
validScale = @(x) isnumeric(x) && isscalar(x) && (x > 0);
validOpen = @(x) iscell(x) && numel(x)==2 && ischar(x{1}) && isnumeric(x{2});
validDilate = @(x) iscell(x) && numel(x)==2 && ischar(x{1}) && isnumeric(x{2});

addRequired(p,'filename', validChannel);
addParameter(p,'channel', 'k', validChannel);
addParameter(p,'rect',[],validRect);
addParameter(p,'scale',0.7,validScale);
addParameter(p,'open',{'disk', 3},validOpen);
addParameter(p,'dilate',{'disk', 2},validDilate);
addParameter(p,'revert',1,validScale);
addParameter(p,'window',7,validScale);
addParameter(p,'debug',0,validScale);
addParameter(p,'otsu',0,validScale);


parse(p,filename,varargin{:});

orig = imread(p.Results.filename);
if ~isempty(p.Results.rect)
    orig = imcrop(orig, p.Results.rect);
end
if p.Results.debug
    close all
    figure(1), imshow(orig);
end
switch(p.Results.channel)
    case {1,'r'}
        crop = medfilt2(orig(:,:,1));
        % chan = 'origRed';
    case {2,'g'}
        crop = medfilt2(orig(:,:,2));
        % chan = 'origGreen';
    case {3,'b'}
        crop = medfilt2(orig(:,:,3));
        % chan = 'origBlue';
    otherwise
        crop = rgb2gray(cat(3,medfilt2(orig(:,:,1)),medfilt2(orig(:,:,2)),medfilt2(orig(:,:,3))));
        % chan = 'grayScale';
end
if p.Results.revert
    crop = 255 - crop;
end
[x,y] = size(crop);
se1 = strel(p.Results.open{:});
img_c = imclose(crop,se1);
if p.Results.debug
    figure(2), imshow(img_c,[]);
end

img_fur = double(img_c) - double(crop);
if p.Results.debug
    figure(3),imshow(img_fur,[]);
end
if p.Results.otsu
    % [X,Y]=meshgrid(1:x, 1:y);
    % tt=((2*X-x)/x).^2+((2*Y-y)/y).^2 < 1;
    tt = true([x y]);
    thresh = otsu(img_fur(tt),sum(tt(:)));
else
    thresh = multithresh(img_fur);
    thresh = thresh * p.Results.scale;
    tt = true([x y]);
end
img_b = (img_fur>thresh);
if p.Results.debug
    figure(4),imshow(img_b);
end
se2 = strel(p.Results.dilate{:});
img_b =imdilate(img_b,se2);
if p.Results.debug
    figure(5),imshow(img_b);
end
img_new = 0 * orig;
wnd = p.Results.window;
for i = 1:x
    for j = 1:y
        if img_b(i,j) == false
            img_new(i,j,:) = orig(i,j,:);
        else
            ttt = orig(max(1,i-wnd):min(i+wnd,x),max(j-wnd,1):min(j+wnd,y),:); % region
            no_efficient_pix = cat(3,img_b(max(1,i-wnd):min(i+wnd,x),max(j-wnd,1):min(j+wnd,y)),not(tt(max(1,i-wnd):min(i+wnd,x),max(j-wnd,1):min(j+wnd,y))));
            no_efficient_pix = any(no_efficient_pix,3);
            ttt = ttt.*repmat(uint8(not(no_efficient_pix)),[1,1,3]);
            efficient_pix_num = (2*wnd+1)^2-sum(no_efficient_pix(:));
            img_new(i,j,:) = uint8(sum(sum(ttt))./efficient_pix_num);
        end
    end
end
if p.Results.debug
    figure(6),imshow(img_new,[]);
end
end

function thresh = otsu(data,pix_num)
img_var = zeros(256,1);
for i=1:256
     w0 = sum(sum(data<=i-1))./pix_num;
     w1 = 1-w0;
     u0 = sum(sum(data.*double(data<=i-1)))./(w0*pix_num);
     u1 = sum(sum(data.*double(data>i-1)))./(w1*pix_num);
     img_var(i) = w0.*w1.*((u0-u1).^2);
end
[~,I] = max(img_var);
thresh = I-1;
end
