%{
M = 10;
N = 20;

[x,y] = meshgrid(1:M,1:N);
% f = x + y;
f = cos( (x + y)*pi/15);

mesh(x,y, f < 0.3);
hold on
mesh(x,y, f);
hold off
%}

% read image
% imread(FullPathToTheImageFile);
clear
img = imread('M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg');
subplot(2,1,1)
imshow(img);
crp = [750 1000 0 250]; 
line(crp([3 3 4 4 3]), crp([1 2 2 1 1]));
% crop image
c = img(crp(1)+1:crp(2),crp(3)+1:crp(4),:);
subplot(2,1,2)
imshow(c);

%% Red, green, blue
r = c(:,:,1);
g = c(:,:,2);
b = c(:,:,3);
% Show the cropped image and rgb channels
subplot(2,2,1);
imshow(c);
subplot(2,2,2);
imshow(r);
subplot(2,2,3);
imshow(g);
subplot(2,2,4);
imshow(b);

%% Threshold rgb cahnnels with thresholds [20,60,90] respectively.
% The range of a pixel value is between 0 and 255
thr = [20,60,90];
subplot(2,2,2);
imshow(r>thr(1)); % Plot the red component that is larger than thr(1) = 20 
subplot(2,2,3);
imshow(g>thr(2));
subplot(2,2,4);
imshow(b>thr(3));

%% Mesh plots of the threasholds, try to rotate meshes by dragging subplots.
subplot(2,2,2);
mesh(r>thr(1)); 
subplot(2,2,3);
mesh(g>thr(2));
subplot(2,2,4);
mesh(b>thr(3));

%% Mesh plots of the channels
subplot(2,2,2);
mesh(r); 
subplot(2,2,3);
mesh(g);
subplot(2,2,4);
mesh(b);

%% contour plots of the channels
subplot(2,2,2);
contour(r); 
subplot(2,2,3);
contour(g);
subplot(2,2,4);
contour(b);
