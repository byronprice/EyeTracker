function [] = PupilDetect(filename)
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

%CREATED: 2018/07/10
%  Byron Price
%UPDATED: 2018/07/11
% By: Byron Price

% filename = 'EyeTracker_20180709-6028141.avi';
v = VideoReader(filename);
N = ceil(v.Duration*v.FrameRate);

pupilArea = zeros(N,1);
pupilDiameter = zeros(N,1);
pupilTranslation = zeros(N,2);
pupilRotation = zeros(N,2);

meanLuminance = zeros(N,1);
blink = zeros(N,1);

conn = 8;
edgeThreshold = 3;% THE MAIN FREE PARAMETERS
luminanceThreshold = 33;
count = 0;
for ii=1:N
    if hasFrame(v)
        count = count+1;
        im = readFrame(v);
        im = mean(im,3);
        if ii==1
            imshow(uint8(im));
            title('Click on 4 corners around mouse''s eye');
            [X,Y] = getpts;
            minX = round(min(X));maxX = round(max(X));
            minY = round(min(Y));maxY = round(max(Y));
            
            imshow(uint8(im(minY:maxY,minX:maxX)));caxis([20 50]);
            title('Click on center of pupil');
            [X,Y] = getpts;
            pupilCenterEst = [X,Y];
            
        end
        miniim = im(minY:maxY,minX:maxX);
        miniim = imgaussfilt(miniim,1);
        
        meanLuminance(count) = mean(miniim(:));
        
            %     get bright spot from IR led reflection
        temp = miniim>200;
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
        
        if sum(isnan(ledPos))>0  || maxarea<25
            ledPos = pupilTranslation(count-1,:);
            blink(count) = 1;
        end
        
        [pupil_ellipse,~] = ...
            detect_pupil_and_corneal_reflection(miniim,pupilCenterEst(1),pupilCenterEst(2),edgeThreshold,luminanceThreshold);
        
        if count==1
            if norm([pupil_ellipse(1),pupil_ellipse(2)]-pupilCenterEst)>5
                imshow(miniim);caxis([20 50]);
                title('Click on a bunch of points around pupil edge');
                [X,Y] = getpts;
                if isempty(X)
                    pupil_ellipse = [0 0 0 0 0]';
                else
                    [z,a,b,alpha] = fitellipse([X,Y]');
                    pupil_ellipse = [z;a;b;alpha];
                end
            end
        else
            if norm([pupil_ellipse(1),pupil_ellipse(2)]-pupilCenterEst)>10 || ...
                    abs((pupil_ellipse(3)+pupil_ellipse(4))-pupilDiameter(count-1))>10
                imshow(miniim);caxis([20 50]);
                title('Click on a bunch of points around pupil edge');
                [X,Y] = getpts;
                if isempty(X)
                    pupil_ellipse = [0 0 0 0 0]';
                else
                    try
                        [z,a,b,alpha] = fitellipse([X,Y]');
                        pupil_ellipse = [z;a;b;alpha];
                    catch
                        imshow(miniim);caxis([20 50]);
                        title('Click on a bunch of points around pupil edge');
                        [X,Y] = getpts;
                        [z,a,b,alpha] = fitellipse([X,Y]');
                        pupil_ellipse = [z;a;b;alpha];
                    end
                end
            end
        end
        
        pupilCenterEst = [pupil_ellipse(1),pupil_ellipse(2)];
        
        if sum(pupil_ellipse)==0
            blink(count) = 1;
            pupilCenterEst = pupilRotation(count-1,:)+pupilTranslation(count-1,:);
        else
%             imagesc(miniim);colormap('bone');caxis([20 60]);
%             hold on;plotellipse(pupil_ellipse(1:2)',pupil_ellipse(3),pupil_ellipse(4),pupil_ellipse(5),'b--');
%             pause(1/100);
        end

        pupilTranslation(count,:) = ledPos;
        pupilArea(count) = pupil_ellipse(3)*pupil_ellipse(4)*pi;
        pupilRotation(count,:) = [pupil_ellipse(1),pupil_ellipse(2)]-ledPos;
        pupilDiameter(count) = pupil_ellipse(3)+pupil_ellipse(4);
    end
end
N = count;
pupilArea = pupilArea(1:N);
pupilDiameter = pupilDiameter(1:N);
pupilRotation = pupilRotation(1:N,:);
pupilTranslation = pupilTranslation(1:N,:);
time = linspace(0,N/v.FrameRate,N);

filename = filename(1:end-4);
filename = strcat(filename,'.mat');
save(filename,'pupilArea','pupilRotation','pupilTranslation',...
    'pupilDiameter','N','time','blink');
end
