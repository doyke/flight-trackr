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
f = ([0:N_fft-1]/N_fft-0.5)*F_e; % axe des fréquences

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

%% Question 12

% Diagramme de l'oeil de durée 2*T_s pour les 100 premiers bits envoyés
eyediagram(s_l(1:100*F_se), 3*F_se, 2*T_s);

%% Question 13

% DSP de s_l(t)
s_l_tmp = s_l;
% on rajoute des zéros si la longueur de s_l n'est pas divisible par N
if length(s_l_tmp)/N_fft-fix(length(s_l_tmp)/N_fft) ~= 0
    s_l_tmp = [zeros(1,(fix(length(s_l_tmp)/N_fft)+1)*N_fft-length(s_l_tmp)) s_l_tmp];
end
S_l_cut = zeros(0);
% on calcule la TF puis DSP de chaque sous-vecteur
for i=1:fix(length(s_l_tmp)/N_fft)
    tmp = abs(fft(s_l_tmp((i-1)*N_fft+1:i*N_fft), N_fft)).^2;
    S_l_cut = [S_l_cut; tmp];
end
DSP_S_l_th = (pi^2.*f.^2.*T_s.^3)/16.*sinc(f.*T_s/2).^4;
DSP_S_l = (1/(size(S_l_cut,1)))*sum(S_l_cut);
% finalement, on trace les DSP normalisées
figure;
hold on
plot(f,fftshift(DSP_S_l)./sqrt(sum(DSP_S_l.^2)));
plot(f,DSP_S_l_th./sqrt(sum(DSP_S_l_th.^2)),'r');
xlim([-F_e/2 F_e/2-F_e/N_fft]);
legend('DSP réelle', 'DSP théorique');
title('DSP de s_l(t)');
xlabel('Fréquence (Hz)');
ylabel('Amplitude');