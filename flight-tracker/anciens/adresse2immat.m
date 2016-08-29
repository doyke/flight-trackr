function [immat, airline, category, country] = adresse2immat(adresse)
    
    dbpath = [pwd '/PlaneInfo.db'];
    URL = ['jdbc:sqlite:' dbpath];

    conn = database('','','','org.sqlite.JDBC',URL);
    tablename = 'immatriculation';
    colnames = {'address','immat','category','country','airline'};
    
    adresse_quote = ['"' adresse '"'];
    address_query = ['select * from ' tablename ' where address = ' adresse_quote];
    curs = exec(conn,address_query);
    curs = fetch(curs);
    cursData = curs.Data;
    
    % Ajout complémentaire des infos via flightradar24
    if (strcmp(cursData, 'No Data'))
        
        country = [];
        [found, immat, airline, category] = flightradar_reader(adresse);
        
        if (found)
            data = {adresse, immat, category, '', airline};
            datainsert(conn, tablename, colnames, data);
        end
    else
        immat = cursData{2};
        category = cursData{3};
        country = cursData{4};
        airline = cursData{5};
        
        if (isempty(airline) || strcmp(airline, 'null') || isempty(category) || strcmp(category, 'null'))
            [found, ~, airline, category] = flightradar_reader(adresse);

            if (found)
                airline_quote = ['"' airline '"'];
                insert_query = ['update ' tablename ' set airline = ' airline_quote ' where address = ' adresse_quote];
                curs = exec(conn, insert_query);
                close(curs);

                category_quote = ['"' category '"'];
                insert_query = ['update ' tablename ' set category = ' category_quote ' where address = ' adresse_quote];
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
