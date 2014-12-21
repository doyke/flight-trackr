% Ajout dans la bdd pour un avion n'existant pas encore

clear all
close all
clc

address = 'A2C802';

% try (pour si pas de connexion)
try
    data = loadjson(urlread(['http://www.flightradar24.com/data/_ajaxcalls/autocomplete_airplanes.php?&term=', address]));
    
    if (~isempty(data))
        % si on a trouve qque ch
        struct = data{1};
        disp(struct);
        immat = struct.id;
        label = struct.label;
        
        separator = strfind(label, ' - ');
        airline = label(separator(2)+3:separator(3)-1);
        
        category = label(separator(3)+3:end);
        separator_category = strfind(category, ' (');
        category = category(1:separator_category-1);
    end
catch
end

dbpath = [pwd '/PlaneInfo.db'];
URL = ['jdbc:sqlite:' dbpath];

conn = database('','','','org.sqlite.JDBC',URL);

tablename = 'immatriculation';
colnames = {'address','immat','category','country','airline'};
data = {address, immat, category,'', airline};

datainsert(conn, tablename, colnames, data);

close(conn);

