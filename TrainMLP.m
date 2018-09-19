% code to train MLP to detect pupil position and diameter
files = dir('EyeMoveTest_2018*.avi');

load('EyeTrackingMLP.mat');
iterCount = 0;
iters = 1:length(files);
iters = iters(random('Discrete Uniform',length(files),[10000,1]));
for zz=iters
    filename = files(zz).name;
    tmpFilename = filename(1:end-4);
    tmpFilename = strcat(tmpFilename,'-Init.mat');
    try
        load(tmpFilename,'minX','minY','maxX','maxY','luminanceThreshold');
    catch
        return;
    end
    
    tmpFilename = filename(1:end-4);
    tmpFilename = strcat(tmpFilename,'.mat');
    load(tmpFilename,'pupilEllipseInfo','pupilDiameter','time','meanLuminance',...
        'flagged','blink');

    v = VideoReader(filename);
    
    luminanceThresh = mean(meanLuminance)+std(meanLuminance);
    goodFrames = ~blink & ~flagged & (meanLuminance<luminanceThresh) ...
        & (pupilDiameter>6) & (pupilDiameter<40);
    inds = find(goodFrames);
    DesireOutput = [pupilEllipseInfo(inds,2),pupilEllipseInfo(inds,1),pupilDiameter(inds)]';
    time = time(inds);
    
    for ii=1:2
        meanVal = mean(DesireOutput(ii,:));stdVal = std(DesireOutput(ii,:));
        inds = find((DesireOutput(ii,:)>(meanVal-3*stdVal)) & ...
            (DesireOutput(ii,:)<(meanVal+3*stdVal)));
        
        DesireOutput = DesireOutput(:,inds);
        time = time(inds);
    end
    
    N = length(time);
    
    
    numCalcs = Network.numCalcs;
    dCostdWeight = cell(1,numCalcs);
    dCostdBias = cell(1,numCalcs);
    eta = 1/10000;
    lambda = 100;
    
    error = zeros(10,1);
    for ii=1:10
        indeces = ceil(rand([batchSize,1]).*(N-1));
        [dropOutNet,dropOutInds] = MakeDropOutNet(Network,alpha);
        
        for jj=1:numCalcs
            dCostdWeight{jj} = zeros(size(dropOutNet.Weights{jj}));
            dCostdBias{jj} = zeros(size(dropOutNet.Biases{jj}));
        end
        tmpError = zeros(batchSize,1);
        for jj=1:batchSize
            index = indeces(jj);
            v.CurrentTime = time(index);
            im = readFrame(v);
            im = mean(im,3);
            
            miniim = im(minY:maxY,minX:maxX);
            miniim = imgaussfilt(miniim,1);
            miniim = imresize(miniim,0.5);
            miniim = (miniim-luminanceThreshold)./100;
            
            [costweight,costbias,tmpError(jj)] = BackProp(miniim(:),dropOutNet,...
                DesireOutput(:,index));
            for kk=1:numCalcs
                dCostdWeight{kk} = dCostdWeight{kk}+costweight{kk};
                dCostdBias{kk} = dCostdBias{kk}+costbias{kk};
            end
        end
        error(ii) = mean(tmpError);
        [dropOutNet] = GradientDescent(dropOutNet,dCostdWeight,dCostdBias,batchSize,eta,N,lambda);
        [Network] = RevertToWholeNet(dropOutNet,Network,dropOutInds);
    end
    
    [Network] = AdjustDropOutNet(Network,alpha);
    pause(1);
    iterCount = iterCount+1
    if mod(iterCount,500) == 0
        save('EyeTrackingMLP.mat','Network','alpha','batchSize','eta','lambda');
    end
    mean(error)
    std(error)
end