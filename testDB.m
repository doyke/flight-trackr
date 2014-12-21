% Requete dans la bdd des infos sur les avions, au lieu de la recherche
% dans le fichier txt

dbpath = [pwd '/PlaneInfo.db'];
URL = ['jdbc:sqlite:' dbpath];

conn = database('','','','org.sqlite.JDBC',URL);

address = '"393324"';

sqlquery = ['select immat from immatriculation where address = ' address];

curs = exec(conn,sqlquery);
curs = fetch(curs);
immat = cell2mat(curs.Data);

close(curs);
close(conn);

% tablename = 'immatriculation';
% datainsert(conn,tablename,colnames,data);
