% Requete dans la bdd des infos sur les avions, au lieu de la recherche
% dans le fichier txt. Remplacer dans addresse2immat

dbpath = [pwd '/PlaneInfo.db'];
URL = ['jdbc:sqlite:' dbpath];

conn = database('','','','org.sqlite.JDBC',URL);

address = 'XXYYZZ';
address = ['"' address '"'];

sqlquery = ['select immat from immatriculation where address = ' address];

curs = exec(conn,sqlquery);
curs = fetch(curs);
immat = cell2mat(curs.Data);

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
    
    data = {address, immat, category,'', airline};

    datainsert(conn, tablename, colnames, data);
    
    close(conn);
    
end

close(curs);
close(conn);