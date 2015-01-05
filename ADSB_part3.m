%% ADSB Project

%% Initialization
clc
clear all
close all

% JAVA init
import java.net.*;
import java.io.*;
javaaddpath('./javaDataReader');
javaaddpath('./sqlite-jdbc-3.8.7.jar');

%% Constants definition
PORT = 1234;
MER_LON = -0.710648;    % Longitude de l'a�roport de M�rignac
MER_LAT = 44.836316;    % Latitude de l'a�roport de M�rignac

%% Param�tres Utilisateur
Fc = 1090e6;            % La fr�quence porteuse
Rs = 4e6;               % Le rythme d'�chantillonnage (pas plus de 4Mhz)
T_e = 1/Rs;

antenna = 'TX/RX';      % Port de l'usrp sur lequel est branch�e l'antenne
antenna_gain = 40;      % Gain d'antenne

secInBuffer = 0.5;      % dur�e du buffer en secondes

%% Autres param�tres
Rb = 1e6;               % d�bit binaire
NsB = floor(Rs/Rb);     % nombre d'�chantillons par symbole
f_se = NsB;
cplxSamplesInBuffer = secInBuffer*Rs; % dur�e en secondes

Ts = 1/Rb;

registres = [];
plots = [];

%% Affichage de la carte avant de commencer
disp('Chargement de la carte ...')

% La fonction plot_osm_map affiche des longitudes/lattitudes en degr� d�cimaux
REF_LON = -0.710648;	% Longitude de l'a�roport de Merignac
REF_LAT = 44.836316;	% Latitude de l'a�roport de Merignac

figure(1)
% On affiche l'a�roport de M�rignac sur la carte
plot(REF_LON,REF_LAT,'.r','MarkerSize',20);
text(REF_LON+0.05,REF_LAT,'Merignac airport','color','r')

% On affiche une carte sans le nom des villes
plot_osm_map();

xlabel('Longitude en degr�');
ylabel('Latitude en degr�');
hold on
drawnow

%% Lancement du server
my_server = ServerSocket (PORT); % D�finition d'un server tcp sur le port 1234

% Affichage des lignes de commande pour lancer le client
disp('Pour lancer le client taper le code suivant dans une console :')
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['cd ',strrep(pwd,' ','\ ')])
disp(['python2.7 uhd_adsb_tcp_client.py -s ',num2str(Rs), ' -f ', num2str(Fc), ' -A ' antenna, ' -g ',num2str(antenna_gain)])
disp('----------------------------------------------------------------------------------------------------------------------')
disp('En attente de connexion client...')
socket = my_server.accept; % attente de connexion client
disp('Connexion accept�e')

% Le n�cessaire pour aller lire les paquets re�us par tcp
my_input_stream = socket.getInputStream;
my_data_input_stream = DataInputStream(my_input_stream);
data_reader = DataReader(my_data_input_stream);

disp('En attente de signal...')

% On attend une trame du client
while ~(my_input_stream.available)
end

% Lorsque le buffer est non-vide on commence le traitement
disp('R�ception...')

%% Boucle principale
while my_input_stream.available % tant qu'on recoit quelque chose on boucle
    disp('new buffer')
    int8Buffer = data_reader.readBuffer(cplxSamplesInBuffer*4)'; % Un complexe est cod� sur 2 entiers 16 bits soit 4 octets et readBuffer lit des octets.
    int16Buffer = typecast(int8Buffer,'int16'); % On fait la conversion de 2 entiers 8 bits Ã  1 entier 16 bits
    cplxBuffer = double(int16Buffer(1:2:end)) + 1i *double(int16Buffer(2:2:end)); % Les voies I et Q sont entrelac�es, on d�sentrelace pour avoir le buffer complexe.
    
    % Code utilisateur
    absBuffer = abs(cplxBuffer);
    trames = decodage_absbuffer(absBuffer, f_se);
    if (~isempty(trames))
        [registres, plots] = update_registres(registres, plots, trames, LON_REF, LAT_REF);
    end
end

%% fermeture des flux
socket.close;
my_input_stream.close;
my_server.close;
disp (['Fin de connexion: ' datestr(now)]);