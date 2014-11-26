clear all;
close all;

%% Initialisation des variables

F_e = 20*10^9; % fr�quence d'�chantillonage � 20 MHz
T_e = 1/F_e; 
D_s = 10^9; % d�bit symbole � 1 MHz
T_s = 1/D_s; % p�riode symbole � 1 �s
F_se = T_s/T_e; % facteur de sur-�chantillonage = 20
N_fft = 512; % nombre de points utilis�s pour la FFT
N_bits = 1000; % nombre de bits du message transmis

%% Question 11

% G�n�ration de la s�quence binaire
b_k = randi([0 1], 1, N_bits);

% Filtre de mise en forme
p = [-0.5*ones(1, 0.5*T_s*F_e), 0.5*ones(1, 0.5*T_s*F_e)];

% Association bit symbole
Ak = 2*b_k-1; % Ak = -1 pour b_k = 0, 1 pour b_k = 1

% Sur-�chantillonage
Ak = upsample(Ak, F_se);

% Signal s_l(t)
s_l = 0.5 + conv(Ak, p);

% Affichage des 25 premiers bits du signal s_l
figure, plot(s_l(1:25*F_se));