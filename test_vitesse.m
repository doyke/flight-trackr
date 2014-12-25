clear all
close all
clc

subtype_air = 3;
subtype_sol = 1;

%% heading
status = 1;
heading = [1 0 0 0 0 0 0 0 0 0];

%% taux de montee/descente
signe_taux = 0;
taux = [0 0 0 0 0 0 0 1 0];

%% vitesse air
vitesse_bin = [0 0 0 0 0 0 0 0 0 0];
vecteur_vitesse_air_test = [zeros(1,45) status heading 0 vitesse_bin 0 signe_taux taux];

%% vitesse sol
vitesse_EW_bin = [0 0 1 0 0 0 0 0 0 0];
vitesse_NS_bin = [0 0 0 0 0 0 0 0 0 0];
vecteur_vitesse_sol_test = [zeros(1,46) vitesse_EW_bin 0 vitesse_NS_bin 0 signe_taux taux];

[vitesse_air, vitesse_sol, heading] = decodage_vitesse(vecteur_vitesse_air_test, subtype_air);

%% test taux
if (bin2dec(num2str(vecteur_vitesse_air_test(70:78))))
    taux = bin2dec(num2str(vecteur_vitesse_air_test(70:78))) * 64 - 64;
    
    signe = vecteur_vitesse_air_test(69);
    if (signe == 1)
        taux = -taux;
    end
end
