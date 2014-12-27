function [registres] = update_registres(registres, trame, lon_ref, lat_ref)

    i = [];
    adresse = decodage_adresse(trame);

    registre = struct('immatriculation', [], 'adresse', adresse, 'airline', [], 'categorie', [], 'pays', [], 'format', [], ...
                'type', [], 'nom', [], 'altitude', [], 'vitesse_air', [], 'vitesse_sol', [], 'cap', [], 'taux', [], 'timeFlag', [], ...
                'cprFlag', [], 'latitude', [], 'longitude', [], 'trajectoire', [], 'plot1', [], 'plot2', [], 'plot3', []);
    
    % Recherche dans la base des registres
    if (~isempty(registres))
        i = find(cellfun(@(x)strcmp(x, adresse),{registres.adresse}));
        if (~isempty(i))
            registre = registres(i(1));
        end
    end
    
    [registre, erreur] = bit2registre(trame, registre, lon_ref, lat_ref);
        
    % Contrôle CRC
    if (erreur)
        return;
    end
    
    % Mise à jour de la carte
    registre = update_plots(registre);
    
    % Ajout ou mise à jour de la base
    if (isempty(i))
        registres = cat(2, registres, registre);
    else
        registres(i(1)) = registre;
    end
end

function [adresse_hex] = decodage_adresse(vecteur)
    adresse_hex = dec2hex(bin_dec(vecteur(9:32)),6);
end