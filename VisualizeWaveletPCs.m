% VisualizeWaveletPCs.m

load('EyeTracker_20180806-4026621-wvltpca.mat');

x = zeros(DIM);
[C,S] = wavedec2(x,wvltLevel,wvltType);
cm = 'bone';
% cm = magma(100);
figure;
for ii=1:20
    tmp = Winv(ii,:);
    C = zeros(size(C));
    C(keptInds) = tmp;
    I = appcoef2(C,S,wvltType,1);
    subplot(5,4,ii);imagesc(I);colormap(cm);
    ax = gca;set(ax,'xtick',[]);set(ax,'ytick',[]);
    title(sprintf('PC %d',ii));
end