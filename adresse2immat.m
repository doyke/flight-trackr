function [immat, airline, category, country] = adresse2immat(adresse)
    
    dbpath = [pwd '/PlaneInfo.db'];
    URL = ['jdbc:sqlite:' dbpath];

    conn = database('','','','org.sqlite.JDBC',URL);
    tablename = 'immatriculation';
    colnames = {'address','immat','category','country','airline'};
    
    adresse_quote = ['"' adresse '"'];
    address_query = ['select * from immatriculation where address = ' adresse_quote];
    curs = exec(conn,address_query);
    curs = fetch(curs);
    cursData = curs.Data;
    
    % Si l'avion n'est pas dans la bdd, on l'ajoute avec les infos de
    % flightradar24
    if (strcmp(cursData, 'No Data'))
        
        [found, immat, airline, category] = flightradar_reader(adresse);
        
        if (found)
                data = {adresse, immat, category, '', airline};
                datainsert(conn, tablename, colnames, data);

        end
    
    % pour un avion déjà dans la bdd mais sans airline
    % update aussi la categorie
    else
        
        immat = cursData{2};
        category = cursData{3};
        country = cursData{4};
        airline = cursData{5};
        
        if (isempty(airline) || strcmp(airline, 'null') || isempty(category) || strcmp(category, 'null'))
            [found, ~, airline, category] = flightradar_reader(adresse);

            if (found)
                airline_quote = ['"' airline '"'];
                insert_query = ['update immatriculation set airline = ' airline_quote ' where address = ' adresse_quote];
                curs = exec(conn, insert_query);
                close(curs);

                category_quote = ['"' category '"'];
                insert_query = ['update immatriculation set category = ' category_quote ' where address = ' adresse_quote];
                curs = exec(conn, insert_query);
                close(curs);
            end
        end
        
        if (isempty(country) || strcmp(country, 'null'))
            country = [];
        end
    end

    close(curs);
    close(conn);

end
