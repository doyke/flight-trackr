function [vitesse_air, vitesse_sol, cap] = decodage_vitesse(vecteur, subtype)
    
    vitesse_sol = [];
    vitesse_air = [];
    cap = [];
    
    % Vitesse sol (vitesse air + prise en compte du vent)
    if (subtype == 1 || subtype == 2)
    
        % Vitesse est-ouest et nord-sud
        if (bin_dec(vecteur(47:56)) && bin_dec(vecteur(58:67)))
            vitesse_sol_EW = bin_dec(vecteur(47:56)) - 1;
            vitesse_sol_NS = bin_dec(vecteur(58:67)) - 1;
            
            disp(vitesse_sol_EW)

            vitesse_sol = sqrt(vitesse_sol_EW^2 + vitesse_sol_NS^2);
            
            % cap
            direction_EW = vecteur(46);
            direction_NS = vecteur(57);
            if (vitesse_sol ~= 0)
                angle = atan(vitesse_sol_NS/vitesse_sol_EW)*180/pi;

                if ((direction_EW == 0) && (direction_NS == 0)) % Cadran NE
                    cap = 90 - angle;
                elseif((direction_EW == 0) && (direction_NS == 1)) % Cadran SE
                    cap = 90 + angle;
                elseif((direction_EW == 1) && (direction_NS == 1)) % Cadran SW
                    cap = 270 - angle;
                elseif((direction_EW == 1) && (direction_NS == 0)) % Cadran NW
                    cap = 270 + angle;
                    if (cap == 360)
                        cap = 0;
                    end
                end
                cap = round(cap);
            end
            
        else
            vitesse_sol = 'No info';
        end
    
    % vitesse air
    elseif (subtype == 3 || subtype == 4)
        % vitesse
        % seulement si info sur la vitesse
        if (bin_dec(vecteur(58:67)))
            vitesse_air = bin_dec(vecteur(58:67)) - 1;
        else
            vitesse_air = 'No info';
        end
        
        % cap
        status = vecteur(46);
        if (status == 1)
            cap = round(bin_dec(vecteur(47:56))*360/1024);
        end
        
    end

end