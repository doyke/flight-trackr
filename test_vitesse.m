clear all
close all
clc

subtype_air = 3;
subtype_sol = 1;
vitesse = 350;
%vitesse_bin = [0 1 0 1 0 1 1 1 1 0];
vitesse_bin = [0 0 0 0 0 0 0 0 0 0];
vecteur_vitesse_air_test = [zeros(1,57) vitesse_bin];

vitesse_EW = 50;
vitesse_NS = 340;
vitesse_EW_bin = [0 0 0 0 0 0 0 0 0 1];
vitesse_NS_bin = [0 1 0 1 0 1 0 1 0 0];

vecteur_vitesse_sol_test = [zeros(1,46) vitesse_EW_bin 0 vitesse_NS_bin];

[vitesse_air, vitesse_sol] = decodage_vitesse(vecteur_vitesse_sol_test, subtype_sol);
