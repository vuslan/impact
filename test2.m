close all
clear;
clc;
r=7;
se1_para = 3;
se2_para = 2;
img_old = imread('M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg');
% img_old = imread('image.png');
figure(6),imshow(img_old);
% crop
[x,y,z] = size(img_old);
d = y-x;
im_crop = img_old(:,round(d/2)+1:y-(d-round(d/2)),:);
[x,y,z] = size(im_crop);
im_crop = cat(3, medfilt2(im_crop(:,:,1)), medfilt2(im_crop(:,:,2)), medfilt2(im_crop(:,:,3)));
img = rgb2gray(im_crop);
figure(1), imshow(img,[]);

img = 255 - rgb2gray(im_crop);

se1 = strel('disk',se1_para);
img_c = imclose(img,se1);
figure(2), imshow(img_c,[]);
img_fur = double(img_c) - double(img);
figure(3),imshow(img_fur,[]);
[X Y]=meshgrid(1:x);
tt=(X-x/2).^2+(Y-y/2).^2<(x+y)^2;
thresh = otsu(img_fur(tt),sum(tt(:)));
img_b = (img_fur>thresh);
figure(4),imshow(img_b);
se2 = strel('disk',se2_para);
img_b =imdilate(img_b,se2);
figure(5),imshow(img_b);
img_new = uint8(zeros(x,y,z));
for i = 1:x 
  for j = 1:y        
      if img_b(i,j) == false  
          img_new(i,j,:) = im_crop(i,j,:);
      else           
          ttt = im_crop(max(1,i-r):min(i+r,x),max(j-r,1):min(j+r,y),:); % region 
          no_efficient_pix = cat(3,img_b(max(1,i-r):min(i+r,x),max(j-r,1):min(j+r,y)),not(tt(max(1,i-r):min(i+r,x),max(j-r,1):min(j+r,y))));
          no_efficient_pix = any(no_efficient_pix,3);
          ttt = ttt.*repmat(uint8(not(no_efficient_pix)),[1,1,3]);
          efficient_pix_num = (2*r+1)^2-sum(no_efficient_pix(:));
          img_new(i,j,:) = uint8(sum(sum(ttt))./efficient_pix_num);           
      end       
  end   
end
figure(6),imshow(img_new,[]);
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