%% Cell Counting
% This example shows how to use a combination of basic morphological operators and blob analysis to extract information from a video stream. In this case, the example counts the number of E. Coli bacteria in each video frame. Note that the cells are of varying brightness, which makes the task of segmentation more challenging.
% Initialization
% Use these next sections of code to initialize the required variables and objects.
%% Create a System object to read video from avi file.
clear;
filename = 'M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg';
orig = imread(filename);
rect = [1 751 250 250];
cropBlue = double(orig(:,:,3))/255; %double(imcrop(orig(:,:,3), rect))/255;
% Create a BlobAnalysis System object to find the centroid of the segmented cells in the video.
hblob = vision.BlobAnalysis( ...
                'AreaOutputPort', false, ...
                'BoundingBoxOutputPort', false, ...
                'OutputDataType', 'single', ...
                'MinimumBlobArea', 7, ...
                'MaximumBlobArea', 300, ...
                'MaximumCount', 1500);
% Acknowledgement
ackText = 'Germany';
%% Stream Processing Loop
%Create a processing loop to count the number of cells in the input video. This loop uses the System objects you instantiated above.
% Read input video frame

% Apply a combination of morphological dilation and image arithmetic
% operations to remove uneven illumination and to emphasize the
% boundaries between the cells.
y1 = 2*cropBlue - imdilate(cropBlue, strel('square',7));
y1(y1<0) = 0;
y1(y1>1) = 1;
y2 = imdilate(y1, strel('square',7)) - y1;

th = multithresh(y2);      % Determine threshold using Otsu's method    
y3 = (y2 <= th*0.72);       % Binarize the image.
Centroid = step(hblob, y3);   % Calculate the centroid
numBlobs = size(Centroid,1);  % and number of cells.
% Display video
image_out = insertMarker(cropBlue, Centroid, '+', 'Color', 'green');   
y2 = insertMarker(y2, Centroid, '*', 'Color', 'green','size',10);   
subplot(2,2,1); imshow(image_out);
subplot(2,2,2); imshow(y1);
subplot(2,2,3); imshow(y2);
subplot(2,2,4); imshow(y3);
fprintf('Number of cells %d\n',numBlobs);
