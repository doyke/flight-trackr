function [var] = init_var(i)
    
    % La fonction init_var renvoie les structures types vides :
    %       1       structure des registres
    %       2       structure des tracés

    switch i
        case 1
            var = struct('id', [], 'adresse', [], 'format', 17, 'type', [], 'nom', [], ...
            'altitude', [], 'vitesse_air', [], 'vitesse_sol', [], 'cap', [], ...
            'taux', [], 'timeFlag', [], 'cprFlag', [], 'latitude', [], ...
            'longitude', []);
        case 2
            var = struct('adresse', [], 'immat', [], 'airline', [], 'category', [], ...
            'country', [],'trajectoire', [], 'position', [], 'texte', []);
        otherwise
            var = [];
    end
end