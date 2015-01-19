clear all;
close all;
clc;
javaaddpath('./sqlite-jdbc-3.8.7.jar');

trames = load('trames_20141120.mat');
trames_test = trames.trames_20141120;

registres = [];
plots = [];

% La fonction plot_osm_map affiche des longitudes/lattitudes en degrés décimaux
LON_REF = -0.710648;	% Longitude de l'aéroport de Merignac
LAT_REF = 44.836316;	% Latitude de l'aéroport de Merignac

figure(1)
% On affiche l'aéroport de Mérignac sur la carte
plot(LON_REF,LAT_REF,'.r','MarkerSize',20);
text(LON_REF+0.05,LAT_REF,'Merignac airport','color','r')

% On affiche une carte sans le nom des villes
plot_osm_map();

% Affichage des trajectoires
xlabel('Longitude en degré');
ylabel('Latitude en degré');
hold on
[registres, plots] = update_registres(registres, plots, transpose(trames_test), LON_REF, LAT_REF);