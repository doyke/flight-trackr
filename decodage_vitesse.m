function [vitesse_air, vitesse_sol] = decodage_vitesse(vecteur, subtype)
    
    % vitesse sol (vitesse air + prise en compte du vent)
    if (subtype == 1 || subtype == 2)
    
        vitesse_sol = 0;
        % vitesse est-ouest et nord-sud
        % seulement si info sur la vitesse
        if (~bin2dec(num2str(vecteur(47:56))) && bin2dec(num2str(vecteur(58:67))))
            vitesse_sol_EW = bin2dec(num2str(vecteur(47:56))) - 1;
            vitesse_sol_NS = bin2dec(num2str(vecteur(58:67))) - 1;

            vitesse_sol = sqrt(vitesse_sol_EW^2 + vitesse_sol_NS^2);

        end
    
    % vitesse air
    elseif (subtype == 3 || subtype == 4)
        vitesse_air = 0;
        % vitesse
        % seulement si info sur la vitesse
        if (~bin2dec(num2str(vecteur(58:67))))
            vitesse_air = bin2dec(num2str(vecteur(58:67))) - 1;
        end

    end

end

