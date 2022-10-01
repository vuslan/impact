function [numBlobs, Centroid] = macroCount(filename, rect, channel)
% Using Function:
% filename = image file name
% rect : (optional) rect = [Row Column Height Width]; default all image
% channel : (optional) rect = [Row Column Height Width]; default green
% Examples:
% macroCount('Project001_Series005_z0.TIF')
% macroCount('M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg',[1 751 250 250])
% numBlobs = macroCount(...);
% [numBlobs, Centroid] = macroCount(...);
% returns number of blobs and centroids.
%% Cell Counting
% This example shows how to use a combination of basic morphological operators and blob analysis to extract information from a video stream. In this case, the example counts the number of E. Coli bacteria in each video frame. Note that the cells are of varying brightness, which makes the task of segmentation more challenging.
% Initialization
% Use these next sections of code to initialize the required variables and objects.
%% Create a System object to read video from avi file.
% filename = 'M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg';
% filename = 'Project001_Series005_z0.TIF';

if nargin < 3
    channel = 3;
    if nargin < 2
        if nargin < 1
            error('filename required!');
        end
        rect = [];
    end
end
orig = imread(filename);
if isempty(rect)
    origCrop = orig;
else
    origCrop = imcrop(orig, rect);
end
cropRed = medfilt2(double(origCrop(:,:,1))/255);
cropGreen = medfilt2(double(origCrop(:,:,2))/255);
cropBlue = medfilt2(double(origCrop(:,:,3))/255);
switch(channel)
    case {1,'r'}
        cropAnalysis = cropRed;
        chanName = 'origRed';
    case {2,'g'}
        cropAnalysis = cropGreen;
        chanName = 'origGreen';
    case {3,'b'}
        cropAnalysis = cropBlue;
        chanName = 'origBlue';
end
% Create a BlobAnalysis System object to find the centroid of the segmented cells in the video.
hblob = vision.BlobAnalysis( ...
    'AreaOutputPort', false, ...
    'BoundingBoxOutputPort', false, ...
    'OutputDataType', 'single', ...
    'MinimumBlobArea', 7, ...
    'MaximumBlobArea', 300, ...
    'MaximumCount', 1500);
%% Stream Processing Loop
%Create a processing loop to count the number of cells in the input video. This loop uses the System objects you instantiated above.
% Read input video frame

% Apply a combination of morphological dilation and image arithmetic
% operations to remove uneven illumination and to emphasize the
% boundaries between the cells.
y1 = 2*cropAnalysis - imdilate(cropAnalysis, strel('square',7));
y1(y1<0) = 0;
y1(y1>1) = 1;
y2 = imdilate(y1, strel('square',7)) - y1;

th = multithresh(y2);      % Determine threshold using Otsu's method
sc = 0.7;
y3 = (y2 <= th*sc);           % Binarize the image.
Centroid = double(step(hblob, y3));   % Calculate the centroid
numBlobs = size(Centroid,1);  % and number of cells.
figure
imshow(origCrop)
text(Centroid(:,1),Centroid(:,2),num2str((1:size(Centroid,1))'),'Color', 'yellow')
title([chanName '-' replace(filename,'_','\_')])
figure
% Display video
image_out = insertMarker(cropAnalysis, Centroid, '+', 'Color', 'green');
y2 = insertMarker(double(y2), Centroid, '+', 'Color', 'green','size',2);
y3 = insertMarker(double(y3), Centroid, '+', 'Color', 'green','size',2);

subplot(2,2,1); imshow(image_out); title(replace(filename,'_','\_'));
subplot(2,2,2); imshow(y1); title([chanName '-Enhanced']);
subplot(2,2,3); imshow(y2); title([chanName '-Blob']);
subplot(2,2,4); imshow(y3); title(sprintf([chanName '-Threshold:%f Scale:%f'], th, sc));
