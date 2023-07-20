function [numBlobs, Centroid] = macroCount(filename, varargin)
% Using Function:
% macroCount(filename, property value pair);
% Properties : 
% channel : r,g,b default blue
% rect : [Row Column Height Width], default all image.
% norm : The rect units are normalized, 0 : pixels, 1: normalized
% scale : 0.01 - 1, default 0.7
% pxmm : pixels per mm
% area : Compute the number of cells for this area in mm^2
% white : Removes white areas using this threhold and the channels not used for analysis, 0-255, default is 0 
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
validWhite = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x < 256);

addRequired(p,'filename', validChannel);      % Filename to be read
addParameter(p,'channel', 'b', validChannel); % Choose channel
addParameter(p,'rect',[],validRect);    % Apply to a specific rectangle
addParameter(p,'scale',0.7,validScale); % Scales OTSU's threshold
addParameter(p,'norm',0,validScale); % 1 if rect is in normalized units
addParameter(p,'pxmm',0,validScale); % Pixels per mm
addParameter(p,'area',0,validScale); % Area in mm^2
addParameter(p,'white',0,validWhite);   % Removes white labels if any
parse(p,filename,varargin{:});

orig = imread(p.Results.filename);
if isempty(p.Results.rect)
    origCrop = orig;
else
    if p.Results.norm
        origCrop = imcrop(orig, p.Results.rect.*repmat(size(orig,[2 1]),[1 2]));
    else
        origCrop = imcrop(orig, p.Results.rect);
    end
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
if p.Results.white 
    switch(p.Results.channel)
        case {1,'r'}
            indx = find(mean(origCrop(:,:,[2 3]),3)>p.Results.white);
        case {2,'g'}
            indx = find(mean(origCrop(:,:,[1 3]),3)>p.Results.white);
        case {3,'b'}
            indx = find(mean(origCrop(:,:,[1 2]),3)>p.Results.white);
    end
    cropAnalysis(indx) = 0;
end
% Create a BlobAnalysis System object to find the centroid of the segmented cells in the video.
hblob = vision.BlobAnalysis( ...
    'AreaOutputPort', true, ...
    'BoundingBoxOutputPort', true, ...
    'CentroidOutputPort',true,...
    'EccentricityOutputPort',true,...
    'ExcludeBorderBlobs',true,...
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

th = multithresh(y2);               % Determine threshold using Otsu's method
y3 = (y2 <= th*p.Results.scale);    % Binarize the image.
[area,Centroid,bbox,ecc] = hblob(y3);
area = double(area);
% Centroid = double(step(hblob, y3)); % Calculate the centroid
numBlobs = size(Centroid,1);        % and number of cells.
figure
image_out = origCrop;
image_out = insertShape(image_out,"rectangle",bbox,"Color","red");
imshow(image_out)
text(Centroid(:,1),Centroid(:,2),num2str((1:size(Centroid,1))'),'Color', 'yellow')
title([chanName '-' replace(p.Results.filename,'_','\_')])
figure
% Display video
image_out = cropAnalysis;
image_out = insertMarker(image_out, Centroid, '+', 'Color', 'green');

y2 = insertMarker(double(y2), Centroid, '+', 'Color', 'green','size',2);
y3 = insertMarker(double(y3), Centroid, '+', 'Color', 'green','size',2);
subplot(2,2,1); imshow(image_out); title(replace(p.Results.filename,'_','\_'));
subplot(2,2,2); imshow(y1); title([chanName '-Enhanced']);
subplot(2,2,3); imshow(y2); title([chanName '-Blob']);
subplot(2,2,4); imshow(y3); title(sprintf([chanName '-Threshold:%f Scale:%f'], th, p.Results.scale));
fprintf(2,'# of cells %d\n',numBlobs);
fprintf(2,'Ecc %f+-%f\n',mean(ecc),std(ecc));
if p.Results.pxmm
    fprintf(2,'Cell area %f+-%f um^2\n',mean(area)/(p.Results.pxmm^2)*1e6,std(area)/(p.Results.pxmm^2)*1e6);
    numBlobs = numBlobs/prod(size(cropAnalysis)/p.Results.pxmm);
    if p.Results.area
        fprintf(2,'# of cells/%gmm^2 %d\n',p.Results.area,round(numBlobs*p.Results.area));
    else
        fprintf(2,'# of cells/mm^2 %d\n',round(numBlobs));
    end
else
    fprintf(2,'Cell area %f+-%f pixels^2\n',mean(area),std(area));
end
