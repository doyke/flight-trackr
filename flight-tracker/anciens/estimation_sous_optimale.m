function [delta_t_hat, rho] = estimation_sous_optimale(y_l, s_p)
    rho = 0;
    delta_t_hat = 0;

    for delta_t = 0:100
        
        interval = delta_t+1:delta_t+length(s_p);
        y_l_portion = y_l(interval);
        
        rho_num = sum(y_l_portion.*s_p);
        rho_denum = norm(s_p)*norm(y_l_portion);
        rho_tmp = rho_num / rho_denum;
            
        if (abs(rho_tmp) > abs(rho))
             rho = rho_tmp;
             delta_t_hat = delta_t;
        end
        
    end
end