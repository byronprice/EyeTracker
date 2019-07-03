function [] = SemiAutoEyeTracking(filename)
% SemiAutoEyeTracking.m
%  manually detect the pupil in an image, then advance through frames that
%   are similar to the previous one, if similar, just use the same pupil
%   position and diameter as the previous one

simThreshold = 0.25;

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

refIms = cell(1,5);refNum = 1;

pupilInfo = cell(totalFrames,4);
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

refIms{refNum,1} = box;
refIms{refNum,2} = [(box(1)+box(3))/2,(box(2)+box(4))/2];
refIms{refNum,3} = max(box(3)-box(1),box(4)-box(2));
refIms{refNum,5} = im;

im(im<200) = 0;
[y,x] = find(im);
pupilInfo{iterCount,4} = [median(x),median(y)];
refIms{refNum,4} = [median(x),median(y)];

while hasFrame(v)
    iterCount = iterCount+1;
    
    im2 = readFrame(v);
    
    im2 = mean(im2,3);
    im2 = im2(minY:maxY,minX:maxX);
    
    imCorr = zeros(refNum,1);
    for ii=1:refNum
        imCorr(ii) = ssim(im2,refIms{ii,5});
    end
    [maxCorr,ind] = max(imCorr);
    
    if maxCorr>simThreshold
        pupilInfo{iterCount,1} = refIms{ind,1};
        pupilInfo{iterCount,2} = refIms{ind,2};
        pupilInfo{iterCount,3} = refIms{ind,3};
        pupilInfo{iterCount,4} = refIms{ind,4};
    else
        iterCount
        figure(1);
        imshow(uint8(im2));caxis([30 100]);
        title('Click 4 points on edges of pupil');
        set(gcf,'Position',[500,500,800,800]);
        [X,Y] = getpts;
        
        if length(X)<4
            pupilInfo{iterCount,1} = NaN;
            pupilInfo{iterCount,2} = NaN;
            pupilInfo{iterCount,3} = NaN;
            pupilInfo{iterCount,4} = NaN;
        elseif length(X)==4
            box = [min(X),min(Y),max(X),max(Y)]; %xmin, ymin, xmax, ymax
        
            pupilInfo{iterCount,1} = box;
            pupilInfo{iterCount,2} = [(box(1)+box(3))/2,(box(2)+box(4))/2];
            pupilInfo{iterCount,3} = max(box(3)-box(1),box(4)-box(2));
        
            
            if refNum<200
                refNum = refNum+1;
                refIms{refNum,1} = box;
                refIms{refNum,2} = [(box(1)+box(3))/2,(box(2)+box(4))/2];
                refIms{refNum,3} = max(box(3)-box(1),box(4)-box(2));
                refIms{refNum,5} = im2;
                
                im2(im2<200) = 0;
                [y,x] = find(im2);
                pupilInfo{iterCount,4} = [median(x),median(y)];
                refIms{refNum,4} = [median(x),median(y)];
            else
                im2(im2<200) = 0;
                [y,x] = find(im2);
                pupilInfo{iterCount,4} = [median(x),median(y)];
            end
        end
    end
    
end

clear v;
close;

tmpFilename = filename(1:end-4);
tmpFilename = strcat(tmpFilename,'-PupilInfo.mat');
Notes = 'First position in pupilInfo is the bounding box, second is the center position, third is the pupil diameter, fourth is the bright IR LED reflection';
save(tmpFilename,'pupilInfo','filename','totalFrames','Notes');

end