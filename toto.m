% m=2000000;
% n=32;
% 
% tic;
% B = ones(n,m);
% B(1,:) = 1:m;
% B = cumsum(B);
% toc,
% 
% 
% tic;
% 
% C= bsxfun(@plus,(1:n-m).', 0:m-1);
% 
% toc;
% 
% tic,
% [a, b] = meshgrid(1:n, 0:m-1);
% E = a+b;
% toc;
a = plot(sin(2*pi*(0:0.01:1)));
hold on
b = plot(cos(2*pi*(0:0.01:1)));
hold off
A = [a,b];