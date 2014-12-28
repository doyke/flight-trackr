function [dt_hat] = estimation_sous_optimale3(buffer, s_p, n_trame)

    warning('off','all');
    A = hankel(buffer, zeros(1,32));
    warning('on','all');
    
    A = A(1:end-n_trame+1,:);
    % equivalent à repmat mais plus rapide
    B = s_p(ones(1,length(A)), 1:end);
    
    num = sum(A.*B, 2);
    denum = norme(A) .* norme(B);
    rho = num ./ denum;
    dt_hat = find(rho > 0.75);
    dt_hat = dt_hat - 1;
end

function v = norme(M)
    v = realsqrt(sum(abs(M).^2,2));
end