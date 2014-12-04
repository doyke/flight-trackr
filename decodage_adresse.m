function [adresse_hex] = decodage_adresse(vecteur)
    
    adresse_hex_1 = dec2hex(bin2dec(num2str(vecteur(9:16))));
    adresse_hex_2 = dec2hex(bin2dec(num2str(vecteur(17:24))));
    adresse_hex_3 = dec2hex(bin2dec(num2str(vecteur(25:32))));

    adresse_hex = [adresse_hex_1 adresse_hex_2 adresse_hex_3];

end

