function [] = WaveletICA(filename,imInds)
%WaveletICA.m
%   Detailed explanation goes here
savefilename = filename(1:end-4);
savefilename = strcat(savefilename,'-wvltica.mat');

if exist(savefilename,'file') == 2
    return;
else
    v = VideoReader(filename);
    totalFrames = round(v.Duration*v.FrameRate);
    im = readFrame(v);
    
    if nargin<2
        DIM = size(im);
        imInds = [1,DIM(1),1,DIM(2)];
        im = mean(im(imInds(1):imInds(2),imInds(3):imInds(4)),3);
    else
        im = mean(im(imInds(1):imInds(2),imInds(3):imInds(4)),3);
        DIM = size(im);
    end
    
    % vidTime = 250/1000;
    % numFrames = ceil(vidTime/(1/v.FrameRate));
    % video = zeros(DIM(1),DIM(2),numFrames);
    % WDEC = wavedec3(video,5,'db2');
    % N = size(WDEC.dec,1);
    % all = [];
    % for ii=1:N
    %     all = [all;WDEC.dec{ii}(:)];
    % end
    %
    % fullSize = length(all);
    
    wvltLevel = 1;
    wvltType = 'db6';
    [C,S] = wavedec2(im,wvltLevel,wvltType);
    fullSize = length(C(:));
    
    % ica
    numICA = min(1e5,ceil(totalFrames/2));
    times = randperm(totalFrames,numICA);
    
    q = 500;
    fprintf('Data Size: [%d , %d]\n',fullSize,numICA);
    data = zeros(fullSize,numICA);
    
    count = 0;
    while count<numICA
        v.CurrentTime = (times(count+1)-1)./v.FrameRate;
        im = readFrame(v);
        
        if hasFrame(v)
            count = count+1;
            im = mean(im(imInds(1):imInds(2),imInds(3):imInds(4)),3);
            [C,~] = wavedec2(im,wvltLevel,wvltType);
            
            data(:,count) = C(:);
        else
            times(count+1) = randperm(totalFrames,1); 
        end
    end
    fprintf('Computing ICA ... \n');
    [ W, Tinv, mu] = kICA(data,q);
    fprintf('ICA Complete ... \n');
    WTinv = W*Tinv;
    TWt = Tinv\W';

    clear Tinv W;    
    % TRANSFORM ALL OF THE DATA INTO IC SPACE
    clear v data;
    v = VideoReader(filename);
    totalFrames = ceil(v.Duration*v.FrameRate);
    
    icaRep = zeros(totalFrames,q);
    
    for ii=1:totalFrames
        if hasFrame(v)
            im = readFrame(v);
            im = mean(im(imInds(1):imInds(2),imInds(3):imInds(4)),3);
            [C,~] = wavedec2(im,wvltLevel,wvltType);
            icaRep(ii,:) = (WTinv*(C(:)-mu))'; % to go the other way T*W'*icaRep'+mu
        end
    end
    
    if sum(icaRep(end,:))<=1e-6
        icaRep = icaRep(1:end-1,:);
    end
    
    clear v;
    
    newName = filename(1:end-4);
    newName = strcat(newName,'-wvltica.mat');
    save(newName,'icaRep','WTinv','TWt','mu','q','wvltLevel','wvltType',...
        'DIM','filename','S','imInds');
    
    disp(['File Completed: ',filename]);
    
end
end
