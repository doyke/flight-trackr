function [] = bit2registre(vecteur)
    
    registre = struct('adresse', [], 'format', [], 'type', [], 'nom', [], 'altitude', [], 'timeFlag', [], 'cprFlag', [], 'latitude', [], 'longitude', [], 'trajectoire', []);
    
    registre.adresse = num2str(bin2dec(num2str(vecteur(9:32))));
    registre.format = num2str(bin2dec(num2str(vecteur(1:5))));
    registre.nom = ;
    registre.type = num2str(bin2dec(num2str(vecteur(33:37))));
    registre.altitude = ;
    registre.timeFlag = ;
    registre.cprFlag = ;
    registre.latitude = ;
    registre.longitude = ;
    registre.trajectoire = ;
    
end

