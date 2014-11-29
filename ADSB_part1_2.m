clear all;
close all;
%% Initialisation des variables
f_e = 20E6;                                     % fréquence d'échantillonnage 20MHz
T_e = 1/f_e;
D_s = 1E6;                                      % débit symbole 1MHz
T_s = 1/D_s;
f_se = T_s/T_e;
N_fft = 512;                                    % nombre de points pour la FFT
N_bits = 1000;                                   % nombre de bits du message transmis
f = ([0:N_fft-1]/N_fft - 0.5)*f_e;              % axe des fréquences
iteration = 1E2;                                % nombre d'itérations pour le calcul du TEB
EbN0 = 0:10;
%% Question 14
P_b = zeros(iteration,11);

% p_O(-t)
p_1_a = [zeros(1,f_se/2) ones(1,f_se/2) zeros(1,f_se)];
% p_1(-t)
p_0_a = ones(1,f_se/2);
% p(t)
p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;

for k = 1:iteration
    for i = 0:10
        sigma_n_l = 1/(2*(10.^(i/10)));                 % calcul de la variance du bruit en fonction du rapport SNR

        b_k = randi([0 1], 1, N_bits);                  % génération de la séquence binaire
        s_b = b_k;

        A_k = pammod(b_k, 2);                           % association bit->symbole
        s_s = upsample(A_k, f_se);                      % sur-échantillonnage au rythme T_e

        s_l = 1/2 + conv(s_s, p, 'same');               % signal s_l(t)

        n_l = sqrt(sigma_n_l)*randn(1,length(s_l));     % simulation du bruit

        y_l = s_l + n_l;

        r_l_0 = conv(y_l, p_0_a, 'same');
        r_0 = downsample(r_l_0, f_se);                  % r_0(k)

        r_l_1 = conv(y_l, p_1_a, 'same');
        r_1 = downsample(r_l_1, f_se);                  % r_1(k)

        b_k_hat = double(r_0 < r_1);
        P_b(k,i+1) = sum(b_k ~= b_k_hat)/N_bits;
    end
end

% TEB pratique
TEB = mean(P_b);
TEB_th = 1/2*erfc(sqrt(10.^(EbN0/10)));

% TEB théorique
figure;
semilogy(EbN0, TEB);
hold on
semilogy(EbN0, TEB_th,'r');
hold off
title('Evolution du TEB');
legend('TEB pratique','TEB théorique');
xlabel('(E_b/N_0)_{dB}');
ylabel('TEB');