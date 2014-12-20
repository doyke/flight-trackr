dbpath = [pwd '/PlaneInfo.db'];
URL = ['jdbc:sqlite:' dbpath];

conn = database('','','','org.sqlite.JDBC',URL);

address = '393324';

sqlquery = ['select immat from immatriculation where address = ' address];

curs = exec(conn,sqlquery);
curs = fetch(curs);
curs.Data

close(conn);