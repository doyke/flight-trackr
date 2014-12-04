function [registre_maj] = bit2registre(vecteur, registre)

    lon_ref = -0.710648;	% Longitude de l'aéroport de Mérignac
    lat_ref = 44.836316;	% Latitude de l'aéroport de Mérignac

    registre_maj.format = bin2num2str(vecteur(1:5));
    registre_maj.adresse = bin2num2str(vecteur(9:32));
    
    FTC = bin2dec(num2str(vecteur(33:37)));
    registre_maj.type = num2str(FTC);
    
    registre_maj.nom = decodage_nom(vecteur);
    registre_maj.altitude = decodage_altitude(vecteur(41:52));
    registre_maj.timeFlag = bin2num2str(vecteur(53));
    
    bit_CPR = vecteur(54);
    
    registre_maj.cprFlag = bin2num2str(bit_CPR);
    [registre_maj.latitude, registre_maj.longitude] = decodage_latitude_longitude(vecteur(55:71), vecteur(72:88), lat_ref, lon_ref, bit_CPR);
    
    bits_controle = vecteur(89:end);
    
    h = crc.detector([ones(1,13), 0, 1, zeros(1,6), 1, 0, 0, 1]);
    [~, error] = detect(h, transpose(bits_controle));
    
    if (error > 0)
        %registre_maj = registre;
        disp('aie');
    end

end

function [num_str] = bin2num2str(vecteur)
    vecteur_str = num2str(vecteur);
    vecteur_str(isspace(vecteur_str)) = '';
    num_str = num2str(bin2dec(vecteur_str));
end