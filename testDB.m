dbpath = [pwd '/PlaneInfo.db'];
URL = ['jdbc:sqlite:' dbpath];

conn = database('','','','org.sqlite.JDBC',URL);

address = '393324';

sqlquery = ['select immat from immatriculation where address = ' address];

curs = exec(conn,sqlquery);
curs = fetch(curs);
immat = cell2mat(curs.Data);

close(curs);
close(conn);

% tablename = 'immatriculation';
%
% datainsert(conn,tablename,colnames,data);

url_to_search = ['http://www.flightradar24.com/data/_ajaxcalls/autocomplete_airplanes.php?&term=' address];
url = urlread(url_to_search);



% autre db : 'http://virad.openskymap.net/VM512/IcaoReport.htm?icao=393324'
