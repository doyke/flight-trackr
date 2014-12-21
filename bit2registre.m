function [registre_maj, erreur] = bit2registre(vecteur, registre)

    h = crc.detector([ones(1,13), 0, 1, zeros(1,6), 1, 0, 0, 1]);
    [~, erreur] = detect(h, transpose(vecteur));

    if (erreur > 0)
        % on ne change pas le registre
        registre_maj = registre;
    else

        registre_maj = registre;
        registre_maj.format = bin2num2str(vecteur(1:5));
        %adresse_decimale = bin2num2str(vecteur(9:32));
        %registre_maj.immatriculation = adresse2immat(str2double(adresse_decimale));
        registre_maj.adresse = decodage_adresse(vecteur);
        registre_maj.immatriculation = adresse2immat(registre_maj.adresse);

        FTC = bin2dec(num2str(vecteur(33:37)));
        registre_maj.type = num2str(FTC);

        if (FTC > 0 && FTC < 5)

            % message d'identification : on identifie l'avion
            registre_maj.nom = decodage_nom(vecteur);
        
        elseif (FTC == 19)
            
            % message de vitesse en vol
            subtype = bin2dec(num2str(vecteur(38:40)));
            
            [registre_maj.vitesse_air, registre_maj.vitesse_sol] = decodage_vitesse(vecteur, subtype);
            
            % taux de montée/descente
            % seulement si info sur le taux
            if (~bin2dec(num2str(vecteur(70:78))))
                taux = bin2dec(num2str(vecteur(70:78))) * 64 - 64;
                    
                signe = vecteur(69);
                if (signe == 1)
                    taux = -taux;
                end
                    
                registre_maj.taux = taux;
            end
            
        elseif (FTC > 4 && FTC < 9)
             
            % message de position au sol
            % vitesse au sol à prendre en compte
            
            % message de position
            lon_ref = -0.710648;	% Longitude de l'a?roport de M?rignac
            lat_ref = 44.836316;	% Latitude de l'a?roport de M?rignac

            registre_maj.timeFlag = bin2num2str(vecteur(53));

            bit_CPR = vecteur(54);

            registre_maj.cprFlag = bin2num2str(bit_CPR);
            [registre_maj.latitude, registre_maj.longitude] = decodage_latitude_longitude(vecteur(55:71), vecteur(72:88), lat_ref, lon_ref, bit_CPR);
            lon = str2double(registre_maj.longitude);
            lat = str2double(registre_maj.latitude);
            registre_maj.trajectoire = [registre_maj.trajectoire, [lon;lat]];
            

        elseif (FTC > 8 && FTC ~= 19 && FTC < 23)

            % message de position
            lon_ref = -0.710648;	% Longitude de l'a?roport de M?rignac
            lat_ref = 44.836316;	% Latitude de l'a?roport de M?rignac

            registre_maj.altitude = decodage_altitude(vecteur(41:52));
            registre_maj.timeFlag = bin2num2str(vecteur(53));

            bit_CPR = vecteur(54);

            registre_maj.cprFlag = bin2num2str(bit_CPR);
            [registre_maj.latitude, registre_maj.longitude] = decodage_latitude_longitude(vecteur(55:71), vecteur(72:88), lat_ref, lon_ref, bit_CPR);
            lon = str2double(registre_maj.longitude);
            lat = str2double(registre_maj.latitude);
            registre_maj.trajectoire = [registre_maj.trajectoire, [lon;lat;str2double(registre_maj.altitude)*0.3048]];
        else

            % on ne modifie pas le registre
            registre_maj = registre;

        end
    end

end

function [num_str] = bin2num2str(vecteur)
    vecteur_str = num2str(vecteur);
    vecteur_str(isspace(vecteur_str)) = '';
    num_str = num2str(bin2dec(vecteur_str));
end

function [hex_str] = bin2hex2str(vecteur)
    vecteur_str = num2str(vecteur);
    vecteur_str(isspace(vecteur_str)) = '';
    hex_str = dec2hex(bin2dec(vecteur_str));
end