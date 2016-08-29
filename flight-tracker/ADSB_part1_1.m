clear all;
close all;
%% Initialisation des variables
f_e = 20E6;                                     % fréquence d'échantillonnage 20MHz
T_e = 1/f_e;
D_s = 1E6;                                      % débit symbole 1MHz
T_s = 1/D_s;
f_se = T_s/T_e;
N_fft = 512;                                    % nombre de points pour la FFT
N_bits = 112;                                   % nombre de bits du message transmis
f = ([0:N_fft-1]/N_fft - 0.5)*f_e;              % axe des fréquences

%% Question 11
b_k = randi([0 1], 1, N_bits);                  % génération de la séquence binaire
s_b = b_k;

p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;         % filtre de mise en forme

A_k = pammod(b_k, 2);                           % association bit->symbole
s_s = upsample(A_k, f_se);                      % sur-échantillonnage au rythme T_e

s_l = 1/2 + conv(s_s, p, 'same');               % signal s_l(t)
figure, plot(s_l(1:25*f_se));                   % affichage des 25 premiers bits
xlabel('Temps (en µs)')
ylabel('Amplitude (sans unité)')
xlim([-10 510])
ylim([-0.05 1.05])
grid on

%% Question 12
eyediagram(s_l(1:100*f_se), 2*f_se, 2*T_s);    % diagramme de l'oeil de durée 2*T_s
ylim([-0.05 1.05])

%% Question 13
s_l_tmp = s_l;
% rajout de zéros si la longueur de s_l non divisible par N
if (mod(length(s_l_tmp), N_fft) ~= 0)
    s_l_tmp = [zeros(1,N_fft-mod(length(s_l_tmp), N_fft)) s_l_tmp];
end

n = length(s_l_tmp)/N_fft;
S_l_cut = zeros(n, N_fft);

% calcul de la TF et DSP de chaque sous-vecteur
for i = 1:n
    S_l_cut(i,:) = abs(fft(s_l_tmp((i-1)*N_fft+1:i*N_fft), N_fft)).^2;
end

% DSP pratique
DSP_S_l = (1/n) * sum(S_l_cut);

% DSP théorique
Dirac = [zeros(1,length(f)/2) 1 zeros(1,length(f)/2-1)];
DSP_S_l_th = Dirac/4 + (pi^2*T_s^3*f.^2)/(16*N_fft*T_e).*sinc(T_s*f/2).^4;

figure;
hold on

% tracé de la DSP pratique et normalisée
plot(f, fftshift(DSP_S_l)./sqrt(sum(DSP_S_l.^2)));

% tracé de la DSP th?orique et normalisée
plot(f, DSP_S_l_th./sqrt(sum(DSP_S_l_th.^2)), 'r');

xlim([-f_e/2 f_e/2-f_e/N_fft]);
legend('DSP réelle', 'DSP théorique');
title('DSP de s_l(t)');
xlabel('Fréquence (Hz)');
ylabel('Amplitude');
hold off