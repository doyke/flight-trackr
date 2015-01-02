function [delta_t_hat, delta_f_hat] = estimation2(y_l, s_p, T_e)
    m = length(s_p);
    y_l = y_l(1:132);

    delta_f_range = -1E3:1E3;
    t = 0:length(y_l)-1;
    y_l_rep = repmat(y_l, [length(delta_f_range),1]);
    
    [t, delta_f] = meshgrid(t, delta_f_range);
    
    y_l_exp = y_l_rep .* exp(1i*2*pi*T_e*delta_f.*t);

    rho_num = conv2(y_l_exp, fliplr(s_p));
    rho_denum = norm(s_p) * sqrt(conv2(abs(y_l_exp).^2, ones(1,m)));
    abs_rho = abs(rho_num(:,32:end)./rho_denum(:,32:end));
    [~, i] = max(abs_rho(:));

    delta_f_hat = delta_f_range(mod(i,size(abs_rho,1))+1);
    delta_t_hat = floor(i/size(abs_rho,1));