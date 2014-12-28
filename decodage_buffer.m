function trames = decodage_buffer(absBuffer, s_p, p, n_trame, f_se, N_bits)
    dt_hat = estimation_temporelle(absBuffer, s_p, n_trame);

    % Découpage du buffer aux parties qui nous intéressent
    absBuffer = transpose(absBuffer(ones(1,length(dt_hat)), 1:end));
    [intervalle, offset] = meshgrid(length(s_p)+1:n_trame, dt_hat);
    intervalle = offset + intervalle;
    y_l_desync = absBuffer(intervalle);
    
    % Réglage de l'offset
    moyenne = mean(y_l_desync,2);
    moyenne = moyenne(1:end,ones(1,length(y_l_desync)));
    y_l_unoffset = y_l_desync - moyenne / 4;
    
    % Filtre de réception
    r_l = conv2(y_l_unoffset, p);
    
    % Décodage
    r = (downsample(r_l(:,f_se:N_bits*f_se)',f_se))';
    trames = r >= 0;
end

function [dt_hat] = estimation_temporelle(buffer, s_p, n_trame)
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