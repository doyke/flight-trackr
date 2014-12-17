clear all;
close all;

trames = load('trames_20141120.mat');
trames_test = trames.trames_20141120;

registres = [];     % r?pertoire des registres

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

%% Mise ? jour des registres
for k = 1:size(trames_test,2)
    
    trame_test = transpose(trames_test(:,k));
    detected = 0;
    trace = 0;
    adresse = decodage_adresse(trame_test);
    
    % on regarde si on a d?j? r?pertori? cet avion
    for i = 1:length(registres)
        if strcmp(registres(i).adresse, adresse)
            detected = 1;
            registres(i) = bit2registre(trame_test, registres(i));
            break;
        end
    end
    
    % sinon on cr?e un nouveau registre
    if ~detected
        registre = struct('immatriculation', [], 'adresse', [], 'format', [], 'type', [], 'nom', [], 'altitude', [], ...
                          'vitesse_air', [], 'vitesse_sol', [], 'taux', [], 'timeFlag', [], 'cprFlag', [], 'latitude', [], ...
                          'longitude', [], 'trajectoire', [], 'plot1', [], 'plot2', [], 'plot3', []);
        registre = bit2registre(trame_test, registre);
        
        % si pas d'erreur CRC, on l'ajoute dans le r?pertoire des registres
        
        if (~isempty(registre.adresse))
            registres = [registres, registre];
            i = length(registres);
        end
    end
    
    if (~isempty(registres) && ~isempty(registres(i).trajectoire))
        % si le registre a une trajectoire, on la (re)trace
        longitudes = registres(i).trajectoire(1,:);
        latitudes = registres(i).trajectoire(2,:);
        altitudes = registres(i).trajectoire(3,:);
        
        PLANE_LON = longitudes(end);    % Longitude de l'avion
        PLANE_LAT = latitudes(end);     % Latitude de l'avion
        PLANE_ALT = altitudes(end);
        
        if (~isempty(registres(i).plot1) && ~isempty(registres(i).plot2) && ~isempty(registres(i).plot3))
            % on enl?ve ce qui a d?j? ?t? trac?
            delete(registres(i).plot1);
            delete(registres(i).plot2);
            delete(registres(i).plot3);
        end
        
        % si l'avion n'a pas d'immatriculation, on affiche son adresse
        if (~isempty(registres(i).immatriculation))
            Id_airplane = registres(i).immatriculation;
        else
            Id_airplane = registres(i).adresse;
        end

        points = fnplt(cscvn([longitudes;latitudes;altitudes]));
        
        % finalement, on affiche les informations n?cessaires
        registres(i).plot1 = plot3(points(1,:),points(2,:), points(3,:), 'b:');
        registres(i).plot2 = plot3(PLANE_LON,PLANE_LAT, PLANE_ALT,'*b', 'MarkerSize', 8);
        registres(i).plot3 = text(PLANE_LON+0.1,PLANE_LAT, PLANE_ALT,Id_airplane,'color','b');
    end
end