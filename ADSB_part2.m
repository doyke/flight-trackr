clear all;
close all;
clc;
javaaddpath('./sqlite-jdbc-3.8.7.jar');

trames = load('trames_20141120.mat');
trames_test = trames.trames_20141120;

registres = [];     % repertoire des registres

% La fonction plot_google_map affiche des longitudes/lattitudes en degre decimaux,
MER_LON = -0.710648; % Longitude de l'aeroport de Merignac
MER_LAT = 44.836316; % Latitude de l'aeroport de Merignac
figure(1)
plot(MER_LON,MER_LAT,'.r','MarkerSize',20);% On affiche l'aeroport de Merignac sur la carte
text(MER_LON+0.05,MER_LAT,'Merignac airport','color','r')
plot_osm_map()
% plot_google_map('MapType','terrain','ShowLabels',0) % On affiche une carte sans le nom des villes

xlabel('Longitude en degre');
ylabel('Latitude en degre');

hold on;
%% Mise a jour des registres
for k = 1:size(trames_test, 2)
    
    trame_test = transpose(trames_test(:,k));
    registres = update_registres(registres, trame_test, MER_LON, MER_LAT);
    
end