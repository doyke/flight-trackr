clear all;
close all;

%% Initialisation des variables
f_e = 20E6;                                     % fréquence d'échantillonnage 20MHz
T_e = 1/f_e;
D_s = 1E6;                                      % débit symbole 1MHz
T_s = 1/D_s;
f_se = T_s/T_e;
N_fft = 512;                                    % nombre de points pour la FFT
N_bits = 1000;                                  % nombre de bits du message transmis
f = ([0:N_fft-1]/N_fft - 0.5)*f_e;              % axe des fréquences

%% Calculs de la question 11
b_k = randi([0 1], 1, N_bits);                  % génération de la séquence binaire
s_b = b_k;

p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;         % filtre de mise en forme

A_k = pammod(b_k, 2);                           % association bit->symbole
s_s = upsample(A_k, f_se);                      % sur-échantillonnage au rythme T_e

s_l = 1/2 + conv(s_s, p, 'same');               % signal s_l(t)

%% Question 14

% Canal
y_l = s_l;

% Decodage
y_l = y_l - 1/2;

% Filtre adapte
p_adapte = [ones(1,f_se/2) -ones(1,f_se/2)]/2;
r = conv(y_l, p_adapte, 'same');

% Sous-echantillonage
r = downsample(r, f_se);

% Decision
b_k_hat = r;
b_k_hat(b_k_hat > 0) = 1;
b_k_hat(b_k_hat < 0) = 0;

% Evolution du TEB en fonction de E_b/N_0
P_b = zeros(0);

for i = 1:10
    b_k = randi([0 1], 1, N_bits);
    s_b = b_k;
    A_k = pammod(b_k, 2);
    s_s = upsample(A_k, f_se);
    s_l = 1/2 + conv(s_s, p, 'same');
    
    sigma_n_l = 1/(2*(10.^(i/10)));
    n_l = sqrt(sigma_n_l)*randn(1,length(s_l));
    y_l = s_l + n_l;
    y_l = y_l - 1/2;
    
    r = conv(y_l, p_adapte, 'same');
    r = downsample(r, f_se);
    
    b_k_hat = r;
    b_k_hat(b_k_hat > 0) = 1;
    b_k_hat(b_k_hat < 0) = 0;
    
    P_b = [P_b sum(abs(b_k_hat-b_k))/N_bits];
end

figure;
EbN0 = 0:9;
semilogy(EbN0,P_b);
hold on
semilogy(EbN0,1/2*erfc(sqrt(10.^(EbN0/10))),'r');
hold off
title('Evolution du TEB et de la probabilite d''erreur binaire theorique');
legend('TEB','Probabilite d''erreur binaire theorique');
xlabel('(E_b/N_0)_{dB}');
ylabel('TEB');