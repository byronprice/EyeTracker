function [] = WaveletPCA(filename)
%WaveletPCA.m
%   Detailed explanation goes here

v = VideoReader(filename);
totalFrames = ceil(v.Duration*v.FrameRate);
im = readFrame(v);
im = mean(im,3);
DIM = size(im);

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

wvltLevel = 3;
wvltType = 'db6';
[C,~] = wavedec2(im,wvltLevel,wvltType);
fullSize = length(C(:));

% FIGURE OUT WHICH INDICES TO HOLD ON TO FOR PCA
numPCA = 1000;
times = randperm(totalFrames,numPCA);

fullData = zeros(fullSize,numPCA);
for ii=1:numPCA
    v.CurrentTime = (times(ii)-1)./v.FrameRate;
    im = readFrame(v);
    im = mean(im,3);
    [C,~] = wavedec2(im,wvltLevel,wvltType);
    fullData(:,ii) = C(:);
end
% going to keep the 1000 wavelet coefficients with the most variance

variances = var(fullData,[],2);
threshold = quantile(variances,1-1e3/fullSize);
keptInds = find(variances>threshold);

% NOW DO PCA WITH FEWER COEFFICIENTS
numPCA = min(5e4,ceil(totalFrames/2));
times = randperm(totalFrames,numPCA);

fullData = zeros(length(keptInds),numPCA);
for ii=1:numPCA
    v.CurrentTime = (times(ii)-1)./v.FrameRate;
    im = readFrame(v);
    im = mean(im,3);
    [C,~] = wavedec2(im,wvltLevel,wvltType);
    fullData(:,ii) = C(keptInds);
end

[d,~] = size(fullData);
S = cov(fullData');
[V,D] = eig(S);

mu = mean(fullData,2);
% fullData = fullData-repmat(mu,[1,N]);

q = 50;
start = d-q+1;
eigenvals = diag(D);
meanEig = mean(eigenvals(1:start-1));
W = V(:,start:end)*sqrtm(D(start:end,start:end)-meanEig.*eye(q));
W = fliplr(W);

Winv = pinv(W);

% TRANSFORM ALL OF THE DATA INTO PC SPACE
clear v;
v = VideoReader(filename);
totalFrames = ceil(v.Duration*v.FrameRate);

pcaRep = zeros(totalFrames,q);
for ii=1:totalFrames
    im = readFrame(v);
    im = mean(im,3);
    [C,~] = wavedec2(im,wvltLevel,wvltType);
    C = C';
    pcaRep(ii,:) = (Winv*(C(keptInds)-mu))';
end

clear v;

newName = filename(1:end-4);
newName = strcat(newName,'-wvltpca.mat');
save(newName,'pcaRep','keptInds','Winv','mu','q','wvltLevel','wvltType',...
    'DIM','filename');
end

