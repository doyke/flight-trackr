function trames = decodage_buffer(absBuffer, f_se)
    % Variables
    s_p = [1 1 0 0 1 1 zeros(1,8) 1 1 0 0 1 1 zeros(1,12)];
    N_bits = 112;
    p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;
    p = p / norm(p);
    n_trame = 120 * f_se;
    
    dt_hat = estimation_temporelle(absBuffer, s_p, n_trame);
    
    % Découpage du buffer aux parties qui nous intéressent
    [intervalle, offset] = meshgrid(numel(s_p)+1:n_trame, dt_hat);
    intervalle = offset + intervalle;
    y_l_desync = absBuffer(intervalle);
    
    % Réglage de l'offset
    y_l_unoffset = bsxfun(@minus, y_l_desync, mean(y_l_desync,2)/4);
    
    % Filtre de réception
    r_l = conv2(y_l_unoffset, p);
    
    % Décodage
    r = (downsample(r_l(:,f_se:N_bits*f_se)',f_se))';
    trames = r >= 0;
end

function dt_hat = estimation_temporelle(buffer, s_p, n_trame)
    n = numel(buffer);
    m = numel(s_p);
    l = n-n_trame+m;
    
    num = conv(buffer, fliplr(s_p));
    denum = sqrt(conv(buffer.^2, ones(1,m))) * norm(s_p);
    rho = num ./ denum;
    rho = rho(m:l);
        
    dt_hat = find(rho > 0.75);
    dt_hat = dt_hat - 1;
end