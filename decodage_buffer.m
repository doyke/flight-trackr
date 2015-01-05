function trames = decodage_buffer(buffer, T_e, f_se)
    % Variables
    s_p = [1 1 0 0 1 1 zeros(1,8) 1 1 0 0 1 1 zeros(1,12)];
    N_bits = 112;
    p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;
    p = p / norm(p);
    n_trame = 120 * f_se;
    
    [dt_hat, df_hat] = estimation(buffer, s_p, n_trame, T_e);
    
    % Découpage du buffer aux parties qui nous intéressent
    [intervalle, offset] = meshgrid(numel(s_p)+1:n_trame, dt_hat);
    intervalle = offset + intervalle;
    y_l_desync = buffer(intervalle);
    
    % Réglage de l'offset
    y_l_unoffset = bsxfun(@minus, y_l_desync, mean(y_l_desync,2)/4);
    
    % Filtre de réception
    r_l = conv2(y_l_unoffset, p);
    
    % Décodage
    r = (downsample(r_l(:,f_se:N_bits*f_se)',f_se))';
    trames = r >= 0;
    
    % Suppression des trames identiques
    trames = unique(trames, 'rows', 'stable');
end

function [delta_t_hat, delta_f_hat] = estimation(buffer, s_p, n_trame, T_e)
    n = numel(buffer);
    m = numel(s_p);
    l = n-n_trame+m;

    delta_f_range = -1E3:1E3;
    t = 0:length(buffer)-1;
    %y_l_rep = repmat(buffer, [length(delta_f_range),1]);
    
    [t, delta_f] = meshgrid(t, delta_f_range);
    
    y_l_exp = bsxfun(@times, buffer, exp(1i*2*pi*T_e*delta_f.*t));

    rho_num = conv2(y_l_exp, fliplr(s_p));
    rho_denum = norm(s_p) * sqrt(conv2(abs(y_l_exp).^2, ones(1,m)));
    abs_rho = abs(rho_num./rho_denum);
    abs_rho = abs_rho(:,m:l);
    [rho,i] = max(abs_rho, [], 1);
    delta_t_hat = find(rho > 0.75);
    delta_f_hat = delta_f_range(i(delta_t_hat));
end