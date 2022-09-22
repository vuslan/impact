%% Example Fly
clear;
fname = 'C:\hi-level\examples\ExampleFly\ExampleFly\images\01_POS002_';
OrigGreen = imread([fname 'F.TIF']);
OrigBlue = imread([fname 'D.TIF']);
OrigRed = imread([fname 'R.TIF']);

CropRect = [501 251 199 199];

CropBlue = imcrop(OrigBlue ,CropRect);
CropGreen = imcrop(OrigGreen ,CropRect);
CropRed = imcrop(OrigRed ,CropRect);

Orig = cat(3, CropRed, CropGreen, CropBlue);
imshow(Orig);
%%
img = CropBlue;
