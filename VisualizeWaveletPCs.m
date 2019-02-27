% VisualizeWaveletPCs.m

load('EyeTracker_20180806-4026621-wvltpca.mat');

x = zeros(DIM);
[~,S] = wavedec2(x,wvltLevel,wvltType);
cm = 'bone';
% cm = magma(100);
figure;
for ii=1:20
    C = Winv(ii,:);
    I = appcoef2(C,S,wvltType,0);
    subplot(5,4,ii);imagesc(I);colormap(cm);
    ax = gca;set(ax,'xtick',[]);set(ax,'ytick',[]);
    title(sprintf('PC %d',ii));
end