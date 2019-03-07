function [] = WaveletPCA(filename)
%WaveletPCA.m
%   Detailed explanation goes here

v = VideoReader(filename);
totalFrames = round(v.Duration*v.FrameRate);
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

wvltLevel = 5;
wvltType = 'db6';
[C,~] = wavedec2(im,wvltLevel,wvltType);
fullSize = length(C(:));

% online pca
numPCA = min(5e3,ceil(totalFrames/2));
times = randperm(totalFrames,numPCA);

q = 30;
W = normrnd(0,1,[fullSize,q]);
eigenvalues = zeros(q,1);
mu = zeros(fullSize,1);

step = min(0.1,1./(1:numPCA));
for tt=1:numPCA
    v.CurrentTime = (times(tt)-1)./v.FrameRate;
    im = readFrame(v);
    im = mean(im,3);
    [C,~] = wavedec2(im,wvltLevel,wvltType);
    meanSubtract = C(:)-mu;
    mu = mu+(1/(tt+1))*meanSubtract;
    
    if tt>100
        phi = meanSubtract'*W;
        W = W+step(tt)*meanSubtract*phi;
        W = GramSchmidt(W);
        eigenvalues = eigenvalues+step(tt)*((phi').^2-eigenvalues);
        disp(tt/numPCA);
    end
end

[~,inds] = sort(eigenvalues);

eigenvalues = eigenvalues(inds);

newW = zeros(size(W));

for ii=1:q
   newW(:,ii) = W(:,inds(ii)); 
end
W = newW;

Winv = pinv(W);

% TRANSFORM ALL OF THE DATA INTO PC SPACE
clear v;
v = VideoReader(filename);
totalFrames = ceil(v.Duration*v.FrameRate);

pcaRep = zeros(totalFrames,q);
for ii=1:totalFrames
    if hasFrame(v)
        im = readFrame(v);
        im = mean(im,3);
        [C,~] = wavedec2(im,wvltLevel,wvltType);
        pcaRep(ii,:) = (Winv*(C(:)-mu))';
    end
    disp(ii/totalFrames);
end

if sum(pcaRep(end,:))==0
    pcaRep = pcaRep(1:end-1,:);
end

clear v;

newName = filename(1:end-4);
newName = strcat(newName,'-wvltpca.mat');
save(newName,'pcaRep','W','Winv','mu','q','wvltLevel','wvltType',...
    'DIM','filename','eigenvalues');

disp(['File Completed: ',filename]);
end

function [Q] = GramSchmidt(A)
[M,N] = size(A);
Q = zeros(M,N);
R = zeros(N,N);

for jj=1:N
    v = A(:,jj);
    for ii=1:jj-1
       R(ii,jj) = Q(:,ii)'*v;
       v = v-R(ii,jj)*Q(:,ii);
    end
    R(jj,jj) = norm(v); % v'*v
    Q(:,jj) = v./R(jj,jj);
end

end