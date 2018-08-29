function [] = InitializePupilDetection(filename)
% Function to take .avi file of a mouse's face and output pupil center 
%  location, pupil area, and pupil diameter. The algorithm is a combination 
%  of the starburst and a luminance threshold algorithm.

%  there are 2 key free parameters that will depend on luminance conditions
%  in your setup
%    edgeThreshold - for starburst algorithm, the luminance difference that
%       will trigger the algorithm to break as it creates its rays [ this
%       will be minimum luminance difference that we expect at the edge of
%       the pupil (light - dark) ]
%    luminanceThreshold - luminance threshold to help find dark pixels
%      corresponding to the pupil, this should be a little bit less than
%      the average luminance of pupil pixels

%INPUT: filename - .avi file recorded from eye-tracker
%
%OUTPUT: a saved .mat file with relevant information about pupil

%CREATED: 2018/08/28
%  Byron Price
%UPDATED: 2018/08/28
% By: Byron Price

v = VideoReader(filename);
N = ceil(v.Duration*v.FrameRate);

edgeThreshold = 4;% THE MAIN FREE PARAMETERS
luminanceThreshold = 46;
if hasFrame(v)
    im = readFrame(v);
    im = mean(im,3);
    imshow(uint8(im));
    title('Click on 4 corners around mouse''s eye');
    [X,Y] = getpts;
    minX = round(min(X));maxX = round(max(X));
    minY = round(min(Y));maxY = round(max(Y));
    
    tmp = im(minY:maxY,minX:maxX);
    
    imshow(uint8(tmp));caxis([30 150]);
    title('Click on center of pupil');
    [X,Y] = getpts;
    pupilCenterEst = [X,Y];
    
    imshow(uint8(tmp));caxis([30 150]);
    title('Click a bunch of points in pupil');
    [X,Y] = getpts;
    pupilLuminance = [];
    for ii=1:length(X)
        pupilLuminance = [pupilLuminance;tmp(round(Y(ii)),round(X(ii)))];
    end
    
    imshow(uint8(tmp));caxis([30 150]);
    title('Click a bunch of points in grey area of eye (outside pupil)');
    [X,Y] = getpts;
    greyLuminance = [];
    for ii=1:length(X)
        greyLuminance = [greyLuminance;tmp(round(Y(ii)),round(X(ii)))];
    end
    
    
    v.CurrentTime = 3*v.Duration/4;
    im = readFrame(v);
    
    tmp = im(minY:maxY,minX:maxX);
    
    imshow(uint8(tmp));caxis([30 150]);
    title('Click a bunch of points in pupil');
    [X,Y] = getpts;
    pupilLuminance = [];
    for ii=1:length(X)
        pupilLuminance = [pupilLuminance;tmp(round(Y(ii)),round(X(ii)))];
    end
    
    imshow(uint8(tmp));caxis([30 150]);
    title('Click a bunch of points in grey area of eye (outside pupil)');
    [X,Y] = getpts;
     greyLuminance = [];
    for ii=1:length(X)
        greyLuminance = [greyLuminance;tmp(round(Y(ii)),round(X(ii)))];
    end
    
    pupilLuminance = double(pupilLuminance);
    greyLuminance = double(greyLuminance);
    
    luminanceThreshold = mean(pupilLuminance)+2*std(pupilLuminance);
    edgeThreshold = max(round(mean(greyLuminance)-mean(pupilLuminance)),4);
    

    filename = filename(1:end-4);
    filename = strcat(filename,'-Init.mat');
    save(filename,'minX','minY','maxX','maxY','pupilCenterEst','luminanceThreshold',...
        'edgeThreshold');

end
end