function [dt_hat, offset, rho] = estimation_sous_optimale2(buffer, offset, s_p, n_trame)

    dt_hat = -1;
    rho = 0;
    
    for dt = 0:length(buffer)-n_trame
        interval = dt+1:dt+length(s_p);
        y_l = buffer(interval);
        
        rho_num = sum(y_l.*s_p);
        rho_denum = norm(s_p)*norm(y_l);
        rho = rho_num / rho_denum;
            
        if (rho > 0.75)
            dt_hat = dt;
            offset = offset + dt_hat + n_trame;
            break;
        end
    end

end