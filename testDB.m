% Requete dans la bdd des infos sur les avions, au lieu de la recherche
% dans le fichier txt. Remplacer dans addresse2immat

dbpath = [pwd '/PlaneInfo.db'];
URL = ['jdbc:sqlite:' dbpath];

conn = database('','','','org.sqlite.JDBC',URL);

address = '7805D6';
address = ['"' address '"'];

sqlquery = ['select immat from immatriculation where address = ' address];

curs = exec(conn,sqlquery);
curs = fetch(curs);
immat = cell2mat(curs.Data);

close(curs);
close(conn);
