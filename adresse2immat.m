function [immat] = adresse2immat(adresse)
    
    dbpath = [pwd '/PlaneInfo.db'];
    URL = ['jdbc:sqlite:' dbpath];

    conn = database('','','','org.sqlite.JDBC',URL);

    adresse = ['"' adresse '"'];

    sqlquery = ['select immat from immatriculation where address = ' adresse];

    curs = exec(conn,sqlquery);
    curs = fetch(curs);
    immat = cell2mat(curs.Data);

    close(curs);
    close(conn);

end