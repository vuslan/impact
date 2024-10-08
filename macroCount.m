function [numBlobs, Centroid] = macroCount(filename, varargin)
% Using Function:
% macroCount(filename, property value pair);
% Properties : 
% channel : r,g,b, gb default blue
% rect : [Row Column Height Width], default all image.
% norm : The rect units are normalized, 0 : pixels, 1: normalized
% scale : 0.01 - 1, default 0.7
% pxmm : pixels per mm
% area : Compute the number of cells for this area in mm^2
% white : Removes white areas using this threhold and the channels not used for analysis, 0-255, default is 0 
% wchans: The channels used for white thresholding, 0-Using default
% channels which are the channels except the channel specified by channel
% input, otherwise any compination of rgb
% border : Crop from borders by this amount of pixels, scalar, [Horizontal
% Vertical] or [left top right bottom]
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
validAngle = @(x) isnumeric(x) && isscalar(x);
validWhite = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x < 256);
validBorder = @(x) isnumeric(x) && (isscalar(x) || numel(x) == 2 || numel(x) == 4);
validBlob = @(x) isnumeric(x) && numel(x) < 3;

addRequired(p,'filename', validChannel);      % Filename to be read
addParameter(p,'channel', 'b', validChannel); % Choose channel
addParameter(p,'rect',[],validRect);    % Apply to a specific rectangle, crops image
addParameter(p,'scale',0.7,validScale); % Scales OTSU's threshold
addParameter(p,'norm',0,validScale); % 1 if rect is in normalized units
addParameter(p,'pxmm',0,validScale); % Pixels per mm
addParameter(p,'area',0,validScale); % Area in mm^2
addParameter(p,'white',0,validWhite);   % Removes white labels if any
addParameter(p,'wchans',0,validChannel);   % Removes white using this channels
addParameter(p,'border',0,validBorder); % Border crop
addParameter(p,'areablob',[4 300],validBlob); % Blob area min-max
addParameter(p,'maskRect',[],validRect);      % Clears all image data external to this rectangle 
addParameter(p,'maskAngle',[],validAngle);    % The angle that maskRect should be rotated in clockwise direction  

parse(p,filename,varargin{:});
areablob = p.Results.areablob;
if isscalar(p.Results.areablob)
    areablob = [p.Results.areablob 300];
end
areablob = [min(areablob) max(areablob)];

orig = imread(p.Results.filename);
if ~isempty(p.Results.maskRect)
    pg = prod(size(orig,[1 2]));
    msk = find(~immask(orig,p.Results.maskRect,p.Results.maskAngle))+[0 pg 2*pg]; % [0 pg 2*pg] -> We need to mask all three channels.
    orig(msk) = 0;
end
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
    case {4,'r'}
        cropAnalysis = cropRed;
        chanName = 'origRed';
    case {2,'g'}
        cropAnalysis = cropGreen;
        chanName = 'origGreen';
    case {1,'b'}
        cropAnalysis = cropBlue;
        chanName = 'origBlue';
    case {3,'gb','bg'}
        cropAnalysis = (cropBlue + cropGreen)/2;
        chanName = 'origGreenBlue';
end
if numel(p.Results.border) > 1 || p.Results.border(1)
    switch numel(p.Results.border)
        case 1
            cropAnalysis = cropAnalysis(1+p.Results.border:end-p.Results.border,1+p.Results.border:end-p.Results.border);
            origCrop = origCrop(1+p.Results.border:end-p.Results.border,1+p.Results.border:end-p.Results.border,:);
        case 2
            cropAnalysis = cropAnalysis(1+p.Results.border(2):end-p.Results.border(2),1+p.Results.border(1):end-p.Results.border(1));
            origCrop = origCrop(1+p.Results.border(2):end-p.Results.border(2),1+p.Results.border(1):end-p.Results.border(1),:);
        case 4
            cropAnalysis = cropAnalysis(1+p.Results.border(2):end-p.Results.border(4),1+p.Results.border(1):end-p.Results.border(3));
            origCrop = origCrop(1+p.Results.border(2):end-p.Results.border(4),1+p.Results.border(1):end-p.Results.border(3),:);
    end
end
if p.Results.white
    if isnumeric(p.Results.wchans)
        if ~p.Results.wchans(1) 
            switch(p.Results.channel)
                case {4,'r'}
                    indx = find(mean(origCrop(:,:,[2 3]),3)>p.Results.white);
                case {2,'g'}
                    indx = find(mean(origCrop(:,:,[1 3]),3)>p.Results.white);
                case {1,'b'}
                    indx = find(mean(origCrop(:,:,[1 2]),3)>p.Results.white);
                case {3,'gb','bg'}
                    indx = find(mean(origCrop(:,:,1),3)>p.Results.white);
            end
        else
            indx = find(mean(origCrop(:,:,p.Results.wchans),3)>p.Results.white);
        end
    else
        [~,indx] = intersect('rgba',p.Results.wchans);
        if any(indx == 4)
            indx = find(mean(origCrop,3)>p.Results.white);
        else
            indx = find(mean(origCrop(:,:,indx),3)>p.Results.white);
        end
    end
    cropAnalysis(indx) = 0;
end
% Create a BlobAnalysis System object to find the centroid of the segmented cells in the video.
hblob = vision.BlobAnalysis( ...
    'AreaOutputPort', true, ...
    'CentroidOutputPort',true,...
    'BoundingBoxOutputPort', true, ...
    'MajorAxisLengthOutputPort',true,...
    'MinorAxisLengthOutputPort',true,...
    'OrientationOutputPort',true,...
    'EccentricityOutputPort',true,...
    'EquivalentDiameterSquaredOutputPort',true,...
    'ExtentOutputPort',true,...
    'PerimeterOutputPort',true,...
    'MinimumBlobArea', areablob(1), ...
    'MaximumBlobArea', areablob(2), ...
    'ExcludeBorderBlobs',false,...
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
[area,Centroid,bbox,majoraxis,minoraxis,orientation,eccentricity,eqdiasq,extent,perimeter] = hblob(y3);
idxrem = eccentricity>0.95;
area(idxrem) = [];
Centroid(idxrem,:) = [];
bbox(idxrem,:) = [];
majoraxis(idxrem) = [];
minoraxis(idxrem) = [];
orientation(idxrem) = [];
eccentricity(idxrem) = [];
eqdiasq(idxrem) = [];
extent(idxrem) = [];
perimeter(idxrem) = [];

area = double(area);
% Centroid = double(step(hblob, y3)); % Calculate the centroid
numBlobs = size(Centroid,1);        % and number of cells.
figure
% image_out = origCrop;
% image_out = insertShape(image_out,"rectangle",bbox,"Color","red");
imshow(origCrop)
text(Centroid(:,1),Centroid(:,2),num2str((1:size(Centroid,1))'),'Color', 'yellow','FontSize',12,'FontWeight','bold')
filename = p.Results.filename;
if any(filename == '\')
    fni = find(filename=='\');
    filename = filename(fni(end)+1:end);
    filename = replace(filename,'_','\_');
end
title([chanName '-' filename],'Interpreter','none')
hold on
bbox = double(bbox);
plot([bbox(:,1) bbox(:,1)+bbox(:,[3 3]) bbox(:,[1 1])]',[bbox(:,[2 2]) bbox(:,2)+bbox(:,[4 4]) bbox(:,2)]','Color','r','LineWidth',2);
phi = linspace(0,2*pi,50);
cosphi = cos(phi);
sinphi = sin(phi);
for k = 1:numBlobs
    xbar = Centroid(k,1);
    ybar = Centroid(k,2);

    a = majoraxis(k)/2;
    b = minoraxis(k)/2;

    theta = orientation(k);
    R = [ cos(theta)   sin(theta)
         -sin(theta)   cos(theta)];

    xy = [a*cosphi; b*sinphi];
    xy = R*xy;

    x = xy(1,:) + xbar;
    y = xy(2,:) + ybar;

    plot(x,y,'g','LineWidth',2);
end
hold off
figure
% Display video
image_out = cropAnalysis;
image_out = insertMarker(image_out, Centroid, '+', 'Color', 'green');

y2 = insertMarker(double(y2), Centroid, '+', 'Color', 'green','size',2);
y3 = insertMarker(double(y3), Centroid, '+', 'Color', 'green','size',2);
subplot(2,2,1); imshow(image_out); title(filename);
subplot(2,2,2); imshow(y1); title([chanName '-Enhanced']);
subplot(2,2,3); imshow(y2); title([chanName '-Blob']);
subplot(2,2,4); imshow(y3); title(sprintf([chanName '-Threshold:%f Scale:%f'], th, p.Results.scale));
fprintf(2,'# of cells\t%d\n',numBlobs);
fprintf(2,'Ecc\t%f+-%f\n',mean(eccentricity),std(eccentricity));
fprintf(2,'Extent\t%f+-%f\n',mean(extent),std(extent));
if p.Results.pxmm
    pxum = p.Results.pxmm/1e3;
    fprintf(2,'Cell area\t%f+-%f\tum^2\n',mean(area)/(pxum^2),std(area)/(pxum^2));
    if isempty(p.Results.maskRect)
    numBlobs = numBlobs/prod(size(cropAnalysis)/p.Results.pxmm);
    else
        numBlobs = numBlobs/prod(p.Results.maskRect([3 4])/p.Results.pxmm);
    end
    if p.Results.area
        fprintf(2,'# of cells/%gmm^2\t%d\n',p.Results.area,round(numBlobs*p.Results.area));
    else
        fprintf(2,'# of cells/mm^2\t%d\n',round(numBlobs));
    end
    fprintf(2,'MajorAxis\t%f+-%f\tum\n',mean(majoraxis)/pxum,std(majoraxis)/pxum);
    fprintf(2,'MinorAxis\t%f+-%f\tum\n',mean(minoraxis)/pxum,std(minoraxis)/pxum);
    fprintf(2,'Equivalent diameter\t%f+-%f\tum\n',mean(sqrt(eqdiasq))/pxum,std(sqrt(eqdiasq))/pxum);
    fprintf(2,'Perimeter\t%f+-%f\tum\n',mean(perimeter)/pxum,std(perimeter)/pxum);
else
    fprintf(2,'Cell area\t%f+-%f\tpixels^2\n',mean(area),std(area));
    fprintf(2,'MajorAxis\t%f+-%f\tpixels\n',mean(majoraxis),std(majoraxis));
    fprintf(2,'MinorAxis\t%f+-%f\tpixels\n',mean(minoraxis),std(minoraxis));
    fprintf(2,'Equivalent diameter\t%f+-%f\tpixels\n',mean(sqrt(eqdiasq)),std(sqrt(eqdiasq)));
    fprintf(2,'Perimeter\t%f+-%f\tpixels\n',mean(perimeter),std(perimeter));
end
figure
imshow(image_out);
figure
imshow(y1);
figure
imshow(y2);
figure
imshow(y3);
