% code to train MLP to detect pupil position and diameter
files = dir('*.avi');

savefile = 'EyeTrackingGroundTruth.mat';
load(savefile,'imInfo','iterCount');
figure(1);
iters = 1:length(files);
iters = iters(random('Discrete Uniform',length(files),[5*length(files),1]));
for zz=iters
    filename = files(zz).name;data = cell(1,5);
    tmpFilename = filename(1:end-4);
    tmpFilename = strcat(tmpFilename,'-Init.mat');
    try
        load(tmpFilename,'minX','minY','maxX','maxY');
    catch
        fprintf('No -Init.mat file for file: %s\n',filename);
        continue;
    end
    
    v = VideoReader(filename);
    N = 100;
    
    for ii=1:N
       
       time = (v.Duration-1).*rand;
       v.CurrentTime = time;
       im = readFrame(v);

       im = mean(im,3);
       tmp = im(minY:maxY,minX:maxX);
       figure(1);
       imshow(uint8(tmp));caxis([30 100]);
       title('Click 4 points on edges of pupil');
       set(gcf,'Position',[500,500,800,800]);
       [X,Y] = getpts;
       
       
       if length(X)==4
          iterCount = iterCount+1;
          box = [min(X),min(Y),max(X),max(Y)]; %xmin, ymin, xmax, ymax
          imInfo{iterCount,1} = tmp;
          imInfo{iterCount,2} = box;
          imInfo{iterCount,3} = [X,Y];
          imInfo{iterCount,4} = time;
          imInfo{iterCount,5} = filename;
       end
    end
    
    clear v;
    close;
    response = input('Proceed to next mouse? (y/n): ','s');
    
    if response == 'y'
        save(savefile,'imInfo','iterCount');
    else
        save(savefile,'imInfo','iterCount');
        break;
    end
    
%     for ii=1:2
%         meanVal = mean(DesireOutput(ii,:));stdVal = std(DesireOutput(ii,:));
%         inds = find((DesireOutput(ii,:)>(meanVal-3*stdVal)) & ...
%             (DesireOutput(ii,:)<(meanVal+3*stdVal)));
%         
%         DesireOutput = DesireOutput(:,inds);
%         time = time(inds);
%     end
%     
%     N = length(time);
%     
%     
%     numCalcs = Network.numCalcs;
%     dCostdWeight = cell(1,numCalcs);
%     dCostdBias = cell(1,numCalcs);
%     eta = 1/10000;
%     lambda = 100;
%     
%     for ii=1:10
%         indeces = ceil(rand([batchSize,1]).*(N-10));
%         [dropOutNet,dropOutInds] = MakeDropOutNet(Network,alpha);
%         
%         for jj=1:numCalcs
%             dCostdWeight{jj} = zeros(size(dropOutNet.Weights{jj}));
%             dCostdBias{jj} = zeros(size(dropOutNet.Biases{jj}));
%         end
% 
%         for jj=1:batchSize
%             index = indeces(jj);
%             v.CurrentTime = time(index);
%             im = readFrame(v);
%             im = mean(im,3);
%             
%             miniim = im(minY:maxY,minX:maxX);
%             miniim = imgaussfilt(miniim,1);
%             miniim = imresize(miniim,0.5);
%             miniim = (miniim-luminanceThreshold)./100;
%             
%             [costweight,costbias] = BackProp(miniim(:),dropOutNet,...
%                 DesireOutput(:,index));
%             for kk=1:numCalcs
%                 dCostdWeight{kk} = dCostdWeight{kk}+costweight{kk};
%                 dCostdBias{kk} = dCostdBias{kk}+costbias{kk};
%             end
%         end
%         [dropOutNet] = GradientDescent(dropOutNet,dCostdWeight,dCostdBias,batchSize,eta,N,lambda);
%         [Network] = RevertToWholeNet(dropOutNet,Network,dropOutInds);
%     end
%     
%     [Network] = AdjustDropOutNet(Network,alpha);
% 
%     iterCount = iterCount+1;
%     if mod(iterCount,500) == 0
%         save('EyeTrackingMLP.mat','Network','alpha','batchSize','eta','lambda');
%     end
%     clear v;
end
