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
%UPDATED: 2018/09/22
% By: Byron Price

v = VideoReader(filename);

if hasFrame(v)
    v.CurrentTime = (v.Duration-1).*rand;
    im = readFrame(v);

    im = mean(im,3);
    imshow(uint8(im));
    title('Click the center of the eye');
    [X,Y] = getpts;
    minX = round(X-40);maxX = round(X+40);
    minY = round(Y-30);maxY = round(Y+30);
    
    tmp = im(minY:maxY,minX:maxX);
    
    imshow(uint8(tmp));caxis([30 150]);
    title('Click the center of the pupil');
    [X,Y] = getpts;
    pupilCenterEst = [X,Y];
    
    filename = filename(1:end-4);
    filename = strcat(filename,'-Init.mat');
    save(filename,'minX','minY','maxX','maxY','pupilCenterEst');

end

end
