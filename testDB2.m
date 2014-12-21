clear all
close all
clc

address = '393324';

% try (pour si pas de connexion)
try
    data = loadjson(urlread(['http://www.flightradar24.com/data/_ajaxcalls/autocomplete_airplanes.php?&term=', address]));
    
    if (~isempty(data))
        % si on a trouve qque ch
        struct = data{1};
        disp(struct);
        immat = struct.id;
    end
catch
end