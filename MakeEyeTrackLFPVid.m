load('CompiledData_EyeTracker_2018-07-02_17-04-33_401629.mat');
numSamples = length(lowpassTimes);

load('EyeTracker_20180702-401629.mat','N','pupilArea');
Fs = 80;

filename = 'EyeTracker_20180702-401629.avi';
v = VideoReader(filename);

count = 0;

frameTimes = find(auxData(:,2));


vv = VideoWriter('ExampleEyeTracker.avi');
vv.FrameRate = 80;
open(vv);
for ii=1:N
    if hasFrame(v)
        im = readFrame(v);
        im = uint8(mean(im,3));
        count = count+1;
        
        index = frameTimes(count);
        
        subplot(3,2,[1,3,5]);imshow(im);caxis([20 150]);title('IR Video');
        indRange = max(1,index-2*lpFs):min(numSamples,index);
        subplot(3,2,2);plot(lowpassTimes(indRange),lowpassData(indRange));
        minTime = min(lowpassTimes(indRange));
        maxTime = max(lowpassTimes(indRange));
        axis([minTime maxTime -1000 1000]);
        title('LFP');
        subplot(3,2,4);plot(lowpassTimes(indRange),auxData(indRange,1));
        axis([minTime maxTime 0 6]);
        title('Movement');
        indRange = max(1,count-2*Fs):min(N,count);
        time = linspace(minTime,maxTime,length(indRange));
        subplot(3,2,6);plot(time,pupilArea(indRange));
        axis([minTime maxTime 200 1000]);
        title('Pupil Area');
        F  = getframe(gcf);
        writeVideo(vv,F.cdata);
    end
end

close(vv);
clear;
