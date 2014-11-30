function [delta_t_hat, delta_f_hat] = estimation(y_l, s_p, T_e)

    rho = 0;
    delta_t_hat = 0;
    delta_f_hat = 0;

    for delta_t = 0:100
        
        interval = delta_t+1:delta_t+length(s_p);
        y_l_portion = y_l(interval);
        
        for delta_f = -1E3:1E2:1E3
            rho_num = sum(y_l_portion.*s_p.*exp(1i*2*pi*delta_f*T_e.*interval));
            rho_denum = norm(s_p)*norm(y_l_portion);
            rho_tmp = rho_num / rho_denum;
            
            if (abs(rho_tmp) > abs(rho))
                rho = rho_tmp;
                delta_t_hat = delta_t;
                delta_f_hat = delta_f;
            end
        end
        
    end

end