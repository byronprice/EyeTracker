function [ W, mu, eigVecs] = PCA(Z,r)
%
% Syntax:       Zpca = PCA(Z,r);
%               [Zpca, U, mu] = PCA(Z,r);
%               [Zpca, U, mu, eigVecs] = PCA(Z,r);
%               
% Inputs:       Z is an d x n matrix containing n samples of d-dimensional
%               data
%               
%               r is the number of principal components to compute
%               
% Outputs:      Zpca is an r x n matrix containing the r principal
%               components - scaled to variance 1 - of the input samples
%               
%               U is a d x r matrix of coefficients such that
%               Zr = U * Zpca + repmat(mu,1,n);
%               is the r-dimensional PCA approximation of Z
%               
%               mu is the d x 1 sample mean of Z
%               
%               eigVecs is a d x r matrix containing the scaled
%               eigenvectors of the sample covariance of Z
%               
% Description:  Performs principal component analysis (PCA) on the input
%               data
%               
% Author:       Brian Moore
%               brimoor@umich.edu
%               
% Date:         April 26, 2015
%               November 7, 2016
%

% Center data
[Zc, mu] = centerRows(Z);

% Compute truncated SVD
%[U, S, V] = svds(Zc,r); % Equivalent, but usually slower than svd()
[U, S, V] = svd(Zc','econ');
[d,N] = size(Zc);
eigenvals = diag(S.^2/(N-1));

if r<d
    meanEig = mean(eigenvals(r+1:end));
    W = V(:,1:r)*diag(sqrt(eigenvals(1:r)-meanEig));
else
    W = V*diag(sqrt(eigenvals));
end

% [V,D] = eig(Zc*Zc'./(N-1));
% start = d-r+1;
% eigenvals = diag(D);
% meanEig = mean(eigenvals(1:start-1));
% W = V(:,start:end)*sqrtm(D(start:end,start:end)-meanEig.*eye(r));
% W = fliplr(W);

% Compute principal components
%Zpca = S * V';
%Zpca = U' * Zc; % Equivalent but slower

if nargout >= 3
    % Scaled eigenvectors
    eigVecs = bsxfun(@times,U,diag(S)' / sqrt(size(Z,2)));
end
