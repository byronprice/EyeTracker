function [] = SemiAutoEyeTracking(filename)
% SemiAutoEyeTracking.m
%  manually detect the pupil in an image, then advance through frames that
%   are similar to the previous one, if similar, just use the same pupil
%   position and diameter as the previous one

simThreshold = 0.9;

tmpFilename = filename(1:end-4);
tmpFilename = strcat(tmpFilename,'-Init.mat');
try
    load(tmpFilename,'minX','minY','maxX','maxY');
catch
    fprintf('No -Init.mat file for file: %s\n',filename);
    return;
end

v = VideoReader(filename);
totalFrames = ceil(v.Duration*v.FrameRate);

pupilInfo = cell(totalFrames,3);
iterCount = 1;

im = readFrame(v);
im = mean(im,3);
im = im(minY:maxY,minX:maxX);
figure(1);
imshow(uint8(im));caxis([30 100]);
title('Click 4 points on edges of pupil');
set(gcf,'Position',[500,500,800,800]);
[X,Y] = getpts;

box = [min(X),min(Y),max(X),max(Y)]; %xmin, ymin, xmax, ymax

pupilInfo{iterCount,1} = box;
pupilInfo{iterCount,2} = [(box(1)+box(3))/2,(box(2)+box(4))/2];
pupilInfo{iterCount,3} = max(box(3)-box(1),box(4)-box(2));

while hasFrame(v)
    iterCount = iterCount+1;
    
    im2 = readFrame(v);
    
    im2 = mean(im2,3);
    im2 = im2(minY:maxY,minX:maxX);
    
    imCorr = ssim(im2,im);
    
    if imCorr>simThreshold
        pupilInfo{iterCount,1} = pupilInfo{iterCount-1,1};
        pupilInfo{iterCount,2} = pupilInfo{iterCount-1,2};
        pupilInfo{iterCount,3} = pupilInfo{iterCount-1,3};
    else
        figure(1);
        imshow(uint8(im2));caxis([30 100]);
        title('Click 4 points on edges of pupil');
        set(gcf,'Position',[500,500,800,800]);
        [X,Y] = getpts;
        
        box = [min(X),min(Y),max(X),max(Y)]; %xmin, ymin, xmax, ymax
        
        pupilInfo{iterCount,1} = box;
        pupilInfo{iterCount,2} = [(box(1)+box(3))/2,(box(2)+box(4))/2];
        pupilInfo{iterCount,3} = max(box(3)-box(1),box(4)-box(2));
        
        im = im2;
    end
    
end

clear v;
close;

tmpFilename = filename(1:end-4);
tmpFilename = strcat(tmpFilename,'-PupilInfo.mat');

save(tmpFilename,'pupilInfo','filename','totalFrames');

end