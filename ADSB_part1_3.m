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
EbN0 = 0:9;
%% Question 14
P_b = zeros(1,length(EbN0));

% p_O(-t)
p_0_a = ones(1,f_se/2);
% p_1(-t)
p_1_a = [zeros(1,f_se/2) ones(1,f_se/2) zeros(1,f_se)];
% p(t)
p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;
p = p / norm(p);

s_p = [1 0 1 0 0 0 0 1 0 1 0 0 0 0 0 0];                % s_p au rythme 0.5?s
s_p = upsample(s_p, T_s/(0.5E-6));

disp('Calcul du TEB pour Eb/N0 =   ');
for i = length(EbN0)
    erreur = 0;
    iteration = 0;
    % Affichage du traitement en cours (parce que c'est un peu long)
    fprintf('\b\b\b %d\n', EbN0(i));
    
    % garantie de la valeur du TEB (erreur >= 100)
    while erreur < 1E2
        
        sigma_n_l = 1/(2*(10.^(EbN0(i)/10)));           % calcul de la variance du bruit en fonction du rapport SNR
        
        b_k = randi([0 1], [1 N_bits]);                 % g?n?ration de la s?quence binaire
        s_b = b_k;

        A_k = pammod(b_k, 2);                           % association bit->symbole
        s_s = upsample(A_k, f_se);                      % sur-?chantillonnage au rythme T_e
        
        delta_t = randi(100);
        delta_f = randi([-1E3 1E3]);
        
        s_l = [s_p, 1/2+conv(s_s, p)];          % signal s_l(t) avec premi?re partie d?terministe
        
        % signal s_l avec d?synchronisation temporelle et fr?quentielle
        s_l_sync = [zeros(1,delta_t) s_l].*exp(-1i*2*pi*delta_f*T_e.*(-delta_t+1:length(s_l)));

        % simulation du bruit
        n_l = sqrt(sigma_n_l)*randn(1,length(s_l_sync));

        % r?ception
        y_l = s_l_sync + n_l;
        [delta_t_hat, delta_f_hat] = estimation(y_l, s_p, T_e);
        
        % synchronisation
        y_l_desync = y_l(length(s_p)+delta_t_hat+1:end).*exp(1i*2*pi*delta_f.*(1:length(y_l)-length(s_p)-delta_t_hat));
        
        r_l = conv(y_l_desync, p);
        
        r = downsample(r_l(f_se:N_bits*f_se), f_se);
        
        b_k_hat = r < 0;
        
        erreur = erreur + sum(b_k ~= b_k_hat);
        iteration = iteration + 1;
    end
    P_b(i) = erreur / (iteration * N_bits);
end


% TEB pratique
TEB = P_b;
% TEB th?orique
TEB_th = 1/2*erfc(sqrt(10.^(EbN0/10)));

figure;
semilogy(EbN0, TEB);
hold on
semilogy(EbN0, TEB_th,'r');
hold off
title('Evolution du TEB');
legend('TEB pratique','TEB th?orique');
xlabel('(E_b/N_0)_{dB}');
ylabel('TEB');