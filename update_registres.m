function [registres, plots] = update_registres(registres, plots, trames, lon_ref, lat_ref)

    % Cette fonction met en relation les registres d�j� existants avec les
    % possibles nouveaux registres d�tect�s dans les trames

    % D�codage des trames dans des registres
    [r, id] = bits2registres(trames, lon_ref, lat_ref);
    
    % Mise � jour du tableau des registres
    registres = cat(2,registres,r);
    
    % Mise � jour de la carte
    if (~isempty(id))
        plots = update_plots(plots, registres, id);
    end
end