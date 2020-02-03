function [ W, Tinv,T, mu] = kICA(Z,r)
%
% Syntax:       Zica = kICA(Z,r);
%               [Zica, W, T, mu] = kICA(Z,r);
%               
% Inputs:       Z is an d x n matrix containing n samples of d-dimensional
%               data
%               
%               r is the number of independent components to compute
%               
% Outputs:      Zica is an r x n matrix containing the r independent
%               components - scaled to variance 1 - of the input samples
%               
%               W and T are the ICA transformation matrices such that
%               Zr = T \ W' * Zica + repmat(mu,1,n);
%               is the r-dimensional ICA approximation of Z
%               
%               mu is the d x 1 sample mean of Z
%               
% Description:  Performs independent component analysis (ICA) on the input
%               data using the max-kurtosis ICA algorithm
%
% Reference:    http://www.cs.nyu.edu/~roweis/kica.html
%               
% Author:       Brian Moore
%               brimoor@umich.edu
%               
% Date:         November 12, 2016
%

% Center and whiten data
mu = mean(Z,2);
Z = bsxfun(@minus,Z,mu);ZtZ = Z*Z'./(size(Z,2)-1);
try
   T = chol(ZtZ);T = T';
   Tinv = inv(T);
catch
    T = sqrtm(ZtZ);
    Tinv = inv(T);
end
Zcw = T\Z;

% Max-kurtosis ICA
[W, ~, ~] = svd(bsxfun(@times,sum(Zcw.^2,1),Zcw) * Zcw');
%Zica = W(1:r,:) * Zcw;

W = W(1:r,:);
