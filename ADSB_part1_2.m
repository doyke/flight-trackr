clear all;
close all;

%% Initialisation des variables

F_e = 20*10^6; % fr?quence d'?chantillonage ? 20 MHz
T_e = 1/F_e; 
D_s = 10^6; % d?bit symbole ? 1 MHz
T_s = 1/D_s; % p?riode symbole ? 1 ?s
F_se = T_s/T_e; % facteur de sur-?chantillonage = 20
N_fft = 512; % nombre de points utilis?s pour la FFT
N_bits = 112; % nombre de bits du message transmis
f = ([0:N_fft-1]/N_fft-0.5)*F_e; % axe des fr?quences

% G?n?ration de la s?quence binaire
b_k = randi([0 1], 1, N_bits);

% Filtre de mise en forme
p = [-0.5*ones(1, 0.5*T_s*F_e), 0.5*ones(1, 0.5*T_s*F_e)];

% Association bit symbole
Ak = 2*b_k-1; % Ak = -1 pour b_k = 0, 1 pour b_k = 1

% Sur-?chantillonage
Ak = upsample(Ak, F_se);

% Signal s_l(t)
s_l = 0.5 + conv(Ak, p);

%% Question 14

% Filtre adapt? p_0*(-t)
p_0 = [];

% Evolution du TEB en fonction de E_b/N_0
P_b = zeros(0);

for i=0:10
    b_k = randi([0 1], 1, N_bits);
    Ak = upsample(Ak, F_se);
    s_l = 0.5 + conv(Ak, p);
    h_l = 1;
    sigma_n_l = 1/(2*(10.^(i/10)));
    n_l = sqrt(sigma_n_l)*randn(1,length(s_l));
    y_l = conv(s_l, h_l) + n_l;
    y_l = [zeros(1,F_se) y_l];
    
end

%figure;
%EbN0 = 0:1:10;
%semilogy(EbN0,P_b);
%hold on
%semilogy(EbN0,1/2*erfc(sqrt(10.^(EbN0/10))),'r');
%hold off
%title('Evolution du TEB et de la probabilit? d''erreur binaire th?orique');
%legend('TEB','Probabilit? d''erreur binaire th?orique');
%xlabel('(E_b/N_0)_{dB}');
%ylabel('TEB');