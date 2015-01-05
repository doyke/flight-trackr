function [registres, plots] = update_registres(registres, plots, trames, lon_ref, lat_ref)

    % Cette fonction met en relation les registres déjà existants avec les
    % possibles nouveaux registres détectés dans les trames

    % Décodage des trames dans des registres
    [r, id] = bits2registres(trames, lon_ref, lat_ref);
    
    % Mise à jour du tableau des registres
    registres = cat(2,registres,r);
    
    % Mise à jour de la carte
    if (~isempty(id))
        plots = update_plots(plots, registres, id);
    end
end