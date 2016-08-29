function [immat, airline, category, country] = adresse2immat(adresses)
    
    % La fonction adresse2immat va chercher l'immatriculation, la compagnie
    % a�rienne, la cat�gorie et le pays de l'avion dans notre base de
    % donn�es. Si rien n'a �t� trouv�, on va chercher les informations sur
    % le site de flighradar24.
    
    % Initialisation des variables
    n = size(adresses,1);
    immat = cell(n,1);
    airline = cell(n,1);
    category = cell(n,1);
    country = cell(n,1);

    dbpath = [pwd '/PlaneInfo.db'];
    URL = ['jdbc:sqlite:' dbpath];

    % Connexion � la base de donn�es
    conn = database('','','','org.sqlite.JDBC',URL);
    tablename = 'immatriculation';
    colnames = {'address','immat','category','country','airline'};

    % Pour chaque adresse, on recherche l'immatriculation, la cat�gorie, le
    % pays et la compagnie a�rienne
    for k = 1:size(adresses, 1)
        adresse = adresses(k, :);
        
        % Ex�cution de la requ�te
        query = sprintf('select * from %s where address = "%s"', tablename, adresse);
        curs = fetch(exec(conn,query));
        cursData = curs.Data;
        close(curs);

        % Ajout compl�mentaire des infos via flightradar24
        if (strcmp(cursData, 'No Data'))
            [found, data1, data2, data3] = flightradar_reader(adresse);
            if (found)
                data = {adresse, data1, data3, '', data2};
                datainsert(conn, tablename, colnames, data);
                
                immat(k) = {data1};
                airline(k) = {data2};
                category(k) = {data3};
            end
        else
            immat(k) = cellstr(cursData{2});
            data2 = cursData{5};
            data3 = cursData{3};
            data4 = cursData{4};

            if (isempty(data2) || strcmp(data2, 'null') || isempty(data3) || strcmp(data3, 'null'))
                [found, ~, data2, data3] = flightradar_reader(adresse);

                if (found)
                    query = sprintf('update %s set airline = "%s", category = "%s" where address = "%s"', tablename, data2, data3, adresse);
                    curs = exec(conn, query);
                    close(curs);
                end
            end

            if (isempty(data4) || strcmp(data4, 'null'))
                data4 = [];
            end
            
            airline(k) = {data2};
            category(k) = {data3};
            country(k) = {data4};
        end
    end
    
    % Fermeture de la connexion
    close(conn);
end