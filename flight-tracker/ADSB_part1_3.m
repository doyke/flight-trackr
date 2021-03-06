%clear all;
%close all;
%% Initialisation des variables
f_e = 20E6;                                     % fréquence d'échantillonnage 20MHz
T_e = 1/f_e;
D_s = 1E6;                                      % débit symbole 1MHz
T_s = 1/D_s;
f_se = T_s/T_e;
N_fft = 512;                                    % nombre de points pour la FFT
N_bits = 112;                                   % nombre de bits du message transmis
f = ((0:N_fft-1)/N_fft - 0.5)*f_e;              % axe des fréquences
EbN0 = 0:10;
%% Question 14
P_b = zeros(1,length(EbN0));

% p_O(-t)
p_0_a = ones(1,f_se/2);
% p_1(-t)
p_1_a = [zeros(1,f_se/2) ones(1,f_se/2) zeros(1,f_se)];
% p(t)
p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;
p = p / norm(p);

s_p = [1 1 0 0 1 1 zeros(1,8) 1 1 0 0 1 1 zeros(1,12)];

disp('Calcul du TEB pour Eb/N0 =  ');
for i = 1:length(EbN0)
    erreur = 0;
    iteration = 0;
    % Affichage du traitement en cours (parce que c'est un peu long)
    fprintf('\b\b\b %d\n', EbN0(i));
    
    % garantie de la valeur du TEB (erreur >= 100)
    while erreur < 10^2 || iteration < 5E4
        
        sigma_n_l = 1/(2*(10.^(EbN0(i)/10)));           % calcul de la variance du bruit en fonction du rapport SNR
        
        b_k = randi([0 1], [1 N_bits]);                 % génération de la séquence binaire
        s_b = b_k;

        A_k = pammod(b_k, 2);                           % association bit->symbole
        s_s = upsample(A_k, f_se);                      % sur-échantillonnage au rythme T_e
        
        delta_t = randi(100);
        delta_f = randi([-1E3 1E3]);
        
        s_l = [s_p, 1/2+conv(s_s, p)];          % signal s_l(t) avec premiére partie déterministe
        
        % signal s_l avec désynchronisation temporelle et fréquentielle
        s_l_sync = [zeros(1,delta_t) s_l].*exp(-1i*2*pi*delta_f*T_e.*(-delta_t+1:length(s_l)));

        % simulation du bruit
        n_l = sqrt(sigma_n_l)*randn(1,length(s_l_sync));

        % réception
        y_l = s_l_sync + n_l;
        [delta_t_hat, delta_f_hat] = estimation(y_l, s_p, T_e);
        
        % synchronisation
        y_l_desync = y_l(length(s_p)+delta_t_hat+1:end).*exp(1i*2*pi*delta_f.*(1:length(y_l)-length(s_p)-delta_t_hat));
        
        r_l = conv(y_l_desync, p);
        
        if (length(r_l) < N_bits * f_se)
            r_l = [r_l zeros(1,N_bits*f_se - length(r_l))];
        end
        
        r = downsample(r_l(f_se:N_bits*f_se), f_se);
        
        b_k_hat = r < 0;
        
        erreur = erreur + sum(b_k ~= b_k_hat);
        iteration = iteration + 1;
    end
    P_b(i) = erreur / (iteration * N_bits);
end


% TEB pratique
TEB = P_b;
% TEB théorique
TEB_th = 1/2*erfc(sqrt(10.^(EbN0/10)));

figure;
semilogy(EbN0, TEB);
hold on
semilogy(EbN0, TEB_th,'r');
hold off
title('Evolution du TEB');
legend('TEB pratique','TEB théorique');
xlabel('(E_b/N_0)_{dB}');
ylabel('TEB');