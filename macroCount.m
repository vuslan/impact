function [numBlobs, Centroid] = macroCount(filename, varargin)
% Using Function:
% macroCount(filename, property value pair);
% Properties : 
% channel : r,g,b default blue
% rect : [Row Column Height Width], default all image.
% scale : 0.01 - 1, default 0.7
% Examples:
% macroCount('Project001_Series005_z0.TIF', 'scale', 0.8)
% macroCount('M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg','rect',[1 751 250 250])
% macroCount('M2_CD163_CTOG_MC_10x_3s_array_1-2 - Kopie.jpg','rect',[1 751 250 250],'channel','g')
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


p = inputParser;
validRect = @(x) isnumeric(x) && numel(x) == 4;
validChannel = @(x) (ischar(x) || isnumeric(x));
validScale = @(x) isnumeric(x) && isscalar(x) && (x > 0);

addRequired(p,'filename', validChannel);
addParameter(p,'channel', 'b', validChannel);
addParameter(p,'rect',[],validRect);
addParameter(p,'scale',0.7,validScale);
parse(p,filename,varargin{:});

orig = imread(p.Results.filename);
if isempty(p.Results.rect)
    origCrop = orig;
else
    origCrop = imcrop(orig, p.Results.rect);
end
cropRed = medfilt2(double(origCrop(:,:,1))/255);
cropGreen = medfilt2(double(origCrop(:,:,2))/255);
cropBlue = medfilt2(double(origCrop(:,:,3))/255);
switch(p.Results.channel)
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
y3 = (y2 <= th*p.Results.scale);           % Binarize the image.
Centroid = double(step(hblob, y3));   % Calculate the centroid
numBlobs = size(Centroid,1);  % and number of cells.
figure
imshow(origCrop)
text(Centroid(:,1),Centroid(:,2),num2str((1:size(Centroid,1))'),'Color', 'yellow')
title([chanName '-' replace(p.Results.filename,'_','\_')])
figure
% Display video
image_out = insertMarker(cropAnalysis, Centroid, '+', 'Color', 'green');
y2 = insertMarker(double(y2), Centroid, '+', 'Color', 'green','size',2);
y3 = insertMarker(double(y3), Centroid, '+', 'Color', 'green','size',2);

subplot(2,2,1); imshow(image_out); title(replace(p.Results.filename,'_','\_'));
subplot(2,2,2); imshow(y1); title([chanName '-Enhanced']);
subplot(2,2,3); imshow(y2); title([chanName '-Blob']);
subplot(2,2,4); imshow(y3); title(sprintf([chanName '-Threshold:%f Scale:%f'], th, p.Results.scale));
