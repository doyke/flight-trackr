%% Fonction qui permet un affichage dynamique des trajectoires des avions

clc;
clear all;
close all;
%% La fonction plot_google_map affiche des longitudes/lattitudes en degr� d�cimaux,
MER_LON = -0.710648; % Longitude de l'a�roport de M�rignac
MER_LAT = 44.836316; % Latitude de l'a�roport de M�rignac

figure(1);
plot(MER_LON,MER_LAT,'.r','MarkerSize',20);% On affiche l'a�roport de M�rignac sur la carte
text(MER_LON+0.05,MER_LAT,'Merignac airport','color','r')
plot_google_map('MapType','terrain','ShowLabels',0) % On affiche une carte sans le nom des villes

xlabel('Longitude en degr�');
ylabel('Lattitude en degr�');

hold on;

%% Affichage d'un avion
PLANE_LON = -0.402398; % Longitude de l'avion
PLANE_LAT = 45.01234; % Latitude de l'avion

Id_airplane='AF-1214'; % Nom de l'avion
plot(PLANE_LON,PLANE_LAT,'+b','MarkerSize',8);
text(PLANE_LON+0.05,PLANE_LAT,Id_airplane,'color','b');
