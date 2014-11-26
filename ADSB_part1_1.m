clear all;
close all;

%% Initialisation des variables

F_e = 20*10^9; % fréquence d'échantillonage à 20 MHz
T_e = 1/F_e; 
D_s = 10^9; % débit symbole à 1 MHz
T_s = 1/D_s; % période symbole à 1 µs
F_se = T_s/T_e; % facteur de sur-échantillonage = 20
N_fft = 512; % nombre de points utilisés pour la FFT
N_bits = 1000; % nombre de bits du message transmis

%% Question 11

% Génération de la séquence binaire
b_k = randi([0 1], 1, N_bits);

% Filtre de mise en forme
p = [-0.5*ones(1, 0.5*T_s*F_e), 0.5*ones(1, 0.5*T_s*F_e)];

% Association bit symbole
Ak = 2*b_k-1; % Ak = -1 pour b_k = 0, 1 pour b_k = 1

% Sur-échantillonage
Ak = upsample(Ak, F_se);

% Signal s_l(t)
s_l = 0.5 + conv(Ak, p);

% Affichage des 25 premiers bits du signal s_l
figure, plot(s_l(1:25*F_se));