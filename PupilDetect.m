function [] = PupilDetect(filename)
% function to take .avi file and output pupil center location and pupil
% area

%INPUT: filename - .avi file recorded from eye-tracker
%
%OUTPUT: a saved .mat file with relevant information about pupil

%CREATED: 2018/07/10
%  Byron Price
%UPDATED: 2018/07/10
% By: Byron Price

% filename = 'EyeTracker_20180709-6028141.avi';
v = VideoReader(filename);
N = ceil(v.Duration*v.FrameRate);

pupilArea = zeros(N,1);
pupilTranslation = zeros(N,2);
pupilRotation = zeros(N,2);

meanLuminance = zeros(N,1);
blink = zeros(N,1);

se = strel('disk',2);
se2 = strel('disk',10);
conn = 8;
pupilLuminanceThreshold = 31;
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
            
%             imshow(uint8(im(minY:maxY,minX:maxX)));
%             title('Click on center of pupil');
%             [X,Y] = getpts;
%             pupilCenterEst = [X,Y];
            
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

        % prepare to find the pupil
        temp = miniim<pupilLuminanceThreshold;
        temp = imopen(temp,se);
        temp = imclose(temp,se2);
        
        CC = bwconncomp(temp,conn);
        
        distance = zeros(CC.NumObjects,1);
        for jj=1:CC.NumObjects
            if size(CC.PixelIdxList{jj},1) > 25
                idxToKeep = CC.PixelIdxList(jj);
                idxToKeep = vertcat(idxToKeep{:});
                mask = false(size(miniim));
                mask(idxToKeep) = true;
                [r,c] = find(mask);
                cloud = [c,r];
                temp = [mean(cloud(:,1)),mean(cloud(:,2))];
                
                distance(jj) = norm(temp-ledPos); 
            else
                distance(jj) = Inf;
            end
        end
        
        [~,ind] = min(distance);
        
        idxToKeep = CC.PixelIdxList(ind);
        idxToKeep = vertcat(idxToKeep{:});
        pupilmask = false(size(miniim));
        pupilmask(idxToKeep) = true;
        
        pupilmask = edge(pupilmask,'Canny');
        
        [r,c] = find(pupilmask);
        cloud = [c,r];
        
%         imagesc(miniim);colormap('bone');caxis([20 50]);
%         hold on;plot(c,r,'.');pause(1/100);
%         pupilRotation(count,:) = [mean(cloud(:,1)),mean(cloud(:,2))]-ledPos;
%         
%         find pupil, best-fitting ellipse
        try
            [z,a,b,alpha] = fitellipse(cloud');
            pupilTranslation(count,:) = ledPos;
            pupilArea(count) = a*b*pi;
            pupilRotation(count,:) = z'-ledPos;
            imagesc(miniim);colormap('bone');caxis([20 60]);
            hold on;plotellipse(z,a,b,alpha);
            pause(1/100);
        catch
           blink(count) = 1; 
        end
    end
end




end