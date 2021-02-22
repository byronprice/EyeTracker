function [] = PCAMotEngRT(filename,imInds)
%PCAMotEngRT.m
%  https://arxiv.org/pdf/1511.03688.pdf for online PCA algorithm
savefilename = filename(1:end-4);
savefilename = strcat(savefilename,'-pcamotengrt.mat');

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
    
    DIM = DIM(1:2);
    fullSize = prod(DIM);
    scaleFactor = 127.5;
    
    % online pca
    numPCA = 2e4;
    timeinds = randperm(totalFrames-5,numPCA);
    
    q = 100;
    W = normrnd(0,1,[fullSize,q]);
    for qq=1:q
        W(:,qq) = W(:,qq)./norm(W(:,qq));
    end
    mu = zeros(fullSize,1);
    precision = 1;
    
    xtx = 0;
    xEzt = zeros(fullSize,q);
    EzEzt = zeros(q,q);
    
    WtW = W'*W;
    Iq = eye(q);
    Minv = (WtW+Iq./precision)\Iq;
    MiWt = Minv*W';
    
    count = 0;skipN = 2*q;
    nu = 1e-3;
    while count<numPCA
        v.CurrentTime = (timeinds(count+1)-1)./v.FrameRate;
        im = readFrame(v);
        disp(count);
        if hasFrame(v)
            count = count+1;
            im2 = readFrame(v);
            im = mean(im(imInds(1):imInds(2),imInds(3):imInds(4)),3)./scaleFactor;
            im2 = mean(im2(imInds(1):imInds(2),imInds(3):imInds(4)),3)./scaleFactor;
            C = abs(im2-im);
            
            meanSubtract = C(:)-mu;
            mu = mu+(1/(count+1))*meanSubtract;
            
            Ez = MiWt*meanSubtract;
            EzEzt = EzEzt+Ez*Ez';
            %xEzt = xEzt+meanSubtract*Ez';
            xEzt = xEzt+bsxfun(@times,meanSubtract,Ez');
            xtx = xtx-meanSubtract'*meanSubtract;
            
            if mod(count,skipN)==0
                EzEzt = EzEzt+(Minv.*skipN)./precision;
                Wgrad = (xEzt-W*EzEzt).*precision;
                preGrad = xtx+fullSize*skipN/precision+2*sum(sum(W.*xEzt))...
                    -sum(sum(EzEzt'.*WtW));
                
                W = W+nu*Wgrad./skipN;
                precision = max(precision+nu*preGrad./skipN,1e-9);
                
                xEzt = zeros(fullSize,q);
                EzEzt = zeros(q,q);
                xtx = 0;
                
                WtW = W'*W;
                Minv = (WtW+Iq./precision)\Iq;
                MiWt = Minv*W';
            end
        else
            timeinds(count+1) = randperm(totalFrames,1); 
        end
    end
    
    [U,S,~] = svd(W,'econ');
    W = U*S;
    Minv = (W'*W+Iq./precision)\Iq;
    sigmasquare = 1/precision;
    MiWt = Minv*W';
    
    % optimal conversion back to full space
%     x = W*((W'*W)\M*z)+mu;
    
    % TRANSFORM ALL OF THE DATA INTO PC SPACE
    clear v;
    v = VideoReader(filename);
    totalFrames = ceil(v.Duration*v.FrameRate);
    
    pcaRep = zeros(totalFrames,q);
    
    meanIm = reshape(mu,DIM);
    im = readFrame(v);
    im = mean(im(imInds(1):imInds(2),imInds(3):imInds(4)),3)./scaleFactor;
    C = abs(im-meanIm);
    pcaRep(1,:) = (MiWt*(C(:)-mu))'; % to go the other way W*pcaRep'+mu
    prevIm = im;
    
    checks = round(linspace(2,totalFrames,20));checkcount=1;
    for ii=2:totalFrames
        if hasFrame(v)
            im = readFrame(v);
            im = mean(im(imInds(1):imInds(2),imInds(3):imInds(4)),3)./scaleFactor;
            C = abs(im-prevIm);
            pcaRep(ii,:) = (MiWt*(C(:)-mu))';
            prevIm = im;
        end
        if checks(checkcount)==ii
            fprintf('%3.2f Percent Complete\n',100*ii/totalFrames);
            checkcount = checkcount+1;
        end
    end
    
    if sum(abs(pcaRep(end,:)))<=1e-6
        pcaRep = pcaRep(1:end-1,:);
    end
    
    clear v;
    
    newName = filename(1:end-4);
    newName = strcat(newName,'-pcamotengrt.mat');
    save(newName,'pcaRep','W','Minv','mu','sigmasquare','q',...
        'DIM','filename','imInds','scaleFactor');
    
    disp(['File Completed: ',filename]);
    
end
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
