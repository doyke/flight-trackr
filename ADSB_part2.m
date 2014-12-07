clear all;
close all;

trames = load('trames_20141120.mat');
trames_test = trames.trames_20141120;

registres = [];

%% La fonction plot_google_map affiche des longitudes/lattitudes en degr? d?cimaux,
MER_LON = -0.710648; % Longitude de l'a?roport de M?rignac
MER_LAT = 44.836316; % Latitude de l'a?roport de M?rignac

figure(1);
plot(MER_LON,MER_LAT,'.r','MarkerSize',20);% On affiche l'a?roport de M?rignac sur la carte
text(MER_LON+0.05,MER_LAT,'Merignac airport','color','r')
plot_google_map('MapType','terrain','ShowLabels',0) % On affiche une carte sans le nom des villes

xlabel('Longitude en degr?');
ylabel('Lattitude en degr?');

hold on;

for k = 1:size(trames_test,2)
    
    trame_test = transpose(trames_test(:,k));
    detected = 0;
    trace = 0;
    adresse = decodage_adresse(trame_test);
    
    for i = 1:length(registres)
        if strcmp(registres(i).adresse, adresse)
            detected = 1;
            registres(i) = bit2registre(trame_test, registres(i));
            break;
        end
    end
    
    if ~detected
        registre = struct('immatriculation', [], 'adresse', [], 'format', [], 'type', [], 'nom', [], 'altitude',[], ...
                          'timeFlag', [], 'cprFlag', [], 'latitude', [], 'longitude', [], 'trajectoire', []);
        registre = bit2registre(trame_test, registre);
        
        if (~isempty(registre.adresse))
            registres = [registres, registre];
        end
    end
    
end

%% On actualise la carte
for i = 1:length(registres)
    registre = registres(i);
    longitudes = registre.trajectoire(1,:);
    latitudes = registre.trajectoire(2,:);
    fnplt(cscvn([longitudes;latitudes]),'b--',1)
    Id_airplane = registre.immatriculation; % Nom de l'avion
    PLANE_LON = registre.trajectoire(1,end); % Longitude de l'avion
    PLANE_LAT = registre.trajectoire(2,end); % Latitude de l'avion
    plot(PLANE_LON,PLANE_LAT,'+b','MarkerSize',8);
    text(PLANE_LON+0.05,PLANE_LAT,Id_airplane,'color','b');  
end
