clear all;
close all;
%% Initialisation des variables
f_e = 20E6;                                     % fr?quence d'?chantillonnage 20MHz
T_e = 1/f_e;
D_s = 1E6;                                      % d?bit symbole 1MHz
T_s = 1/D_s;
f_se = T_s/T_e;
N_fft = 512;                                    % nombre de points pour la FFT
N_bits = 112;                                   % nombre de bits du message transmis
f = ((0:N_fft-1)/N_fft - 0.5)*f_e;              % axe des fr?quences
EbN0 = 0:10;
%% Question 14
P_b = zeros(1,length(EbN0));

% p(t)
p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;
p = p / norm(p);

disp('Calcul du TEB pour Eb/N0 =   ');

for i = 1:length(EbN0)
    erreur = 0;
    iteration = 0;
    
    % Affichage du traitement en cours (parce que c'est un peu long)
    fprintf('\b\b\b %d\n', EbN0(i));
    
	while erreur < 1E2
        sigma_n_l = 1/(2*(10.^(EbN0(i)/10)));           % calcul de la variance du bruit en fonction du rapport SNR

        b_k = randi([0 1], 1, N_bits);                  % g?n?ration de la s?quence binaire
        s_b = b_k;

        A_k = pammod(b_k, 2);                           % association bit->symbole
        s_s = upsample(A_k, f_se);                      % sur-?chantillonnage au rythme T_e

        s_l = 1/2 + conv(s_s, p);                       % signal s_l(t)

        n_l = sqrt(sigma_n_l)*randn(1,length(s_l));     % simulation du bruit

        y_l = s_l + n_l;

        r_l = conv(y_l, p);
        r = downsample(r_l(f_se:N_bits*f_se), f_se);
        
        b_k_hat = r < 0;
        erreur = erreur + sum(b_k ~= b_k_hat);
        iteration = iteration + 1;
	end
    P_b(i) = erreur / (iteration * N_bits);
end

% TEB pratique
TEB = P_b;
TEB_th = 1/2*erfc(sqrt(10.^(EbN0/10)));

% TEB th?orique
figure;
semilogy(EbN0, TEB);
hold on
semilogy(EbN0, TEB_th,'r');
hold off
title('Evolution du TEB');
legend('TEB pratique','TEB th?orique');
xlabel('(E_b/N_0)_{dB}');
ylabel('TEB');