function [] = PupilDetect_MLP(filename)
% Function to take .avi file of a mouse's face and output pupil center 
%  location, pupil area, and pupil diameter. The algorithm is a combination 
%  of the starburst and a luminance threshold algorithm.

%  there is 1 key free parameters that will depend on luminance conditions
%  in your setup
%    luminanceThreshold - luminance threshold to help find dark pixels
%      corresponding to the pupil, this should be a little bit less than
%      the average luminance of non-pupil pixels

%INPUT: filename - .avi file recorded from eye-tracker
%
%OUTPUT: a saved .mat file with relevant information about pupil

%CREATED: 2018/09/14
%  Byron Price
%UPDATED: 2018/09/25
% By: Byron Price

% filename = 'EyeTracker_20180709-6028141.avi';
tmpFilename = filename(1:end-4);
tmpFilename = strcat(tmpFilename,'-Init.mat');
try
    load(tmpFilename,'minX','minY','maxX','maxY','pupilCenterEst','luminanceThreshold');
catch
    return;
end

load('EyeTrackingMLP.mat','Network');

v = VideoReader(filename);
N = ceil(v.Duration*v.FrameRate);

pupilDiameter = zeros(N,1);
pupilTranslation = zeros(N,2);
pupilRotation = zeros(N,2);
flagged = zeros(N,1);

meanLuminance = zeros(N,1);
blink = zeros(N,1);

conn = 8;
count = 0;
for ii=1:N
    if hasFrame(v)
        count = count+1;
        im = readFrame(v);
        im = mean(im,3);

        miniim = im(minY:maxY,minX:maxX);
        miniim = imgaussfilt(miniim,1);

        meanLuminance(count) = mean(miniim(:));

            %     get bright spot from IR led reflection
        temp = miniim>175;
        CC = bwconncomp(temp,conn);
        area = cellfun(@numel, CC.PixelIdxList);
        [maxarea,ind] = max(area);
        idxToKeep = CC.PixelIdxList(ind);
        idxToKeep = vertcat(idxToKeep{:});

        ledmask = false(size(miniim));
        ledmask(idxToKeep) = true;

        [r,c] = find(ledmask);
        ledcloud = [c,r];

        ledPos = [median(ledcloud(:,1)),median(ledcloud(:,2))];

        if sum(isnan(ledPos))>0  || maxarea<20
            ledPos = pupilTranslation(count-1,:);
            blink(count) = 1;
        end

        miniim = imresize(miniim,0.5);
        miniim = (miniim-luminanceThreshold)/100;

        [Out,~] = Feedforward(miniim(:),Network);

        pupilTranslation(count,:) = ledPos;
        pupilRotation(count,:) = [Out{end}(2),Out{end}(1)]-ledPos;
        pupilDiameter(count) = Out{end}(3);

        if pupilDiameter(count)<5
            flagged(count) = 1;
        elseif pupilDiameter(count)>40
            flagged(count) = 1;
        end
        if count>1
            if abs(pupilDiameter(count)-pupilDiameter(count-1))>5
                flagged(count) = 1;
            end
        end
    end
end
N = count;
pupilDiameter = pupilDiameter(1:N);
pupilRotation = pupilRotation(1:N,:);
pupilTranslation = pupilTranslation(1:N,:);
flagged = logical(flagged(1:N));
blink = logical(blink(1:N));
meanLuminance = meanLuminance(1:N);
time = linspace(0,N/v.FrameRate,N);
Fs = v.FrameRate;

threshold = median(meanLuminance)+4*1.4826*mad(meanLuminance,1);

blink = logical(blink+logical(meanLuminance>threshold));

filename = filename(1:end-4);
filename = strcat(filename,'-MLP.mat');
save(filename,'pupilRotation','pupilTranslation',...
    'pupilDiameter','N','time','blink','meanLuminance',...
    'flagged','minX','maxX','minY','maxY','luminanceThreshold','Fs');
end
