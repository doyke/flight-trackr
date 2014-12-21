% Requete dans la bdd des infos sur les avions, au lieu de la recherche
% dans le fichier txt. Remplacer dans addresse2immat

clear all;
close all;
clc;

dbpath = [pwd '/PlaneInfo.db'];
URL = ['jdbc:sqlite:' dbpath];

conn = database('','','','org.sqlite.JDBC',URL);

address = '78059B';

address_quote = ['"' address '"'];
address_query = ['select immat from immatriculation where address = ' address_quote];
curs = exec(conn,address_query);
curs = fetch(curs);
immat = cell2mat(curs.Data);

airline_query = ['select airline from immatriculation where address = ' address_quote];
curs = exec(conn,airline_query);
curs = fetch(curs);
airline = cell2mat(curs.Data);

category_query = ['select category from immatriculation where address = ' address_quote];
curs = exec(conn,category_query);
curs = fetch(curs);
category = cell2mat(curs.Data);

country_query = ['select country from immatriculation where address = ' address_quote];
curs = exec(conn,country_query);
curs = fetch(curs);
country = cell2mat(curs.Data);

% Si l'avion n'est pas dans la bdd, on l'ajoute avec les infos de
% flightradar24
if (strcmp(immat, 'No Data'))
    
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
    
    data = {address, immat, category, '', airline};

    datainsert(conn, tablename, colnames, data);
    
    close(conn);
    
end

% pour un avion déjà dans la bdd mais sans airline
% update aussi la categorie
if (strcmp(airline, 'null') || strcmp(airline, ''))
    
    % try (si pas de connexion)
    try
        data = loadjson(urlread(['http://www.flightradar24.com/data/_ajaxcalls/autocomplete_airplanes.php?&term=', address]));
        
        if (~isempty(data))
            % si on a trouve qque ch
            struct = data{1};
            %disp(struct);
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
    
    conn2 = database('','','','org.sqlite.JDBC',URL);
    
    airline_quote = ['"' airline '"'];
    insert_query = ['update immatriculation set airline = ' airline_quote ' where address = ' address_quote];
    curs = exec(conn, insert_query);
    close(curs);
    
    category_quote = ['"' category '"'];
    insert_query = ['update immatriculation set category = ' category_quote ' where address = ' address_quote];
    curs2 = exec(conn, insert_query);
    close(curs2);

    close(conn2);
    
end

close(curs);
close(conn);