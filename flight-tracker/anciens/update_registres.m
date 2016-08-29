function [registres] = update_registres(registres, trames, lon_ref, lat_ref)
    % Contrôle CRC
    trames(controle_crc(trames),:) = [];
    
    % Contrôle du format
    format = 17;
    trames(bin_dec(trames(:,1:5)) ~= format) = [];
    
    % Adresses
    adresses = decodage_adresse(trames);
    
    % Décodage des informations à partir des trames
    for k = 1:size(trames,1)

        i = [];
        trame = trames(k,:);
        adresse = adresses(k,:);
        
        registre = struct('immatriculation', [], 'adresse', ...
            adresse, 'airline', [], 'categorie', [], 'pays', [], ...
            'format', format, 'type', [], 'nom', [], 'altitude', [], ...
            'vitesse_air', [], 'vitesse_sol', [], 'cap', [], 'taux', [], ...
            'timeFlag', [], 'cprFlag', [], 'latitude', [], 'longitude', [], ...
            'trajectoire', [], 'plot1', [], 'plot2', [], 'plot3', []);

        % Recherche dans la base des registres
        if (~isempty(registres))
            i = find(strcmp(extractfield(registres, 'adresse'), adresse));
            if (~isempty(i))
                registre = registres(i(1));
            end
        end
        
        registre = bit2registre(trame, registre, lon_ref, lat_ref);
        
        % Mise à jour de la carte
        registre = update_plots(registre);
        
        % Ajout ou mise à jour de la base
        if (isempty(i))
            registres = cat(2, registres, registre);
        else
            registres(i(1)) = registre;
        end
    end
end

function adresse_hex = decodage_adresse(vecteur)
    adresse_hex = dec2hex(bin_dec(vecteur(:,9:32)),6);
end

function erreur = controle_crc(vecteur)
    h = crc.detector([ones(1,13), 0, 1, zeros(1,6), 1, 0, 0, 1]);
    [~, erreur] = detect(h, transpose(vecteur));
end