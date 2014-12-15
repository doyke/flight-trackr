function [nom] = decodage_nom(vecteur)

    length = 41:46;
    nom = zeros(1,8);

    for i = 0:7
        nom(i+1) = bin2dec(num2str(vecteur(length + i*6)));

        if (nom(i+1) < 26)
            nom(i+1) = nom(i+1) + 64;
        end
    end

    nom = char(nom);
    nom(isspace(nom)) = '';

end
