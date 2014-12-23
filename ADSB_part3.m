%% ADSB Project

%% Initialization
clc
clear all
close all

% JAVA init
import java.net.*;
import java.io.*;
javaaddpath('./javaDataReader');


%% Constants definition
PORT = 1234;
MER_LON = -0.710648; % Longitude de l'a?roport de M?rignac
MER_LAT = 44.836316; % Latitude de l'a?roport de M?rignac

%% Paramètres Utilisateur
Fc = 1090e6; % La fr?quence porteuse
Rs = 4e6; % Le rythme d'?chantillonnage (pas plus de 4Mhz)
T_e = 1/Rs;

antenna = 'TX/RX'; % Port de l'usrp sur lequel est branch?e l'antenne
antenna_gain = 40; % Gain d'antenne

secInBuffer = 0.5; % dur?e du buffer en secondes

%% Autres param?tres
Rb = 1e6;% d?bit binaire
N_bits = 112;
NsB = floor(Rs/Rb); % nombre d'?chantillons par symbole
f_se = NsB;
cplxSamplesInBuffer = secInBuffer*Rs; % dur?e en secondes

Ts = 1/Rb;
s_p = [1 0 1 0 0 0 0 1 0 1 0 0 0 0 0 0];                % s_p au rythme 0.5?s
s_p = upsample(s_p, Ts/(0.5E-6));

p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;
p = p / norm(p);
registres = [];

%% Affichage de la carte avant de commencer
disp('Chargement de la carte ...')
figure(1);
plot(MER_LON,MER_LAT,'.r','MarkerSize',20);
text(MER_LON+0.05,MER_LAT,'Merignac airport','color','b') % On affiche l'a?roport de M?rignac sur la carte
plot_google_map('MapType','terrain','ShowLabels',0) % On affiche une carte sans le nom des villes
xlabel('Longitude en degre');
ylabel('Latitude en degre');
hold on
drawnow


%% Lancement du server
my_server = ServerSocket (PORT); % D?finition d'un server tcp sur le port 1234

% Affichage des lignes de commande pour lancer le client
disp('Pour lancer le client taper le code suivant dans une console :')
disp('----------------------------------------------------------------------------------------------------------------------')
disp(['cd ',strrep(pwd,' ','\ ')])
disp(['python2.7 uhd_adsb_tcp_client.py -s ',num2str(Rs), ' -f ', num2str(Fc), ' -A ' antenna, ' -g ',num2str(antenna_gain)])
disp('----------------------------------------------------------------------------------------------------------------------')
disp('En attente de connexion client...')
socket = my_server.accept; % attente de connexion client
disp('Connexion accept?e')

% Le n?cessaire pour aller lire les paquets re?us par tcp
my_input_stream = socket.getInputStream;
my_data_input_stream = DataInputStream(my_input_stream);
data_reader = DataReader(my_data_input_stream);

disp('En attente de signal...')

% On attend une trame du client
while ~(my_input_stream.available)
end

% Lorsque le buffer est non-vide on commence le traitement
disp('R?ception...')

%% Boucle principale
while my_input_stream.available % tant qu'on re?oit quelque chose on boucle
    disp('new buffer')
    int8Buffer = data_reader.readBuffer(cplxSamplesInBuffer*4)'; % Un complexe est cod? sur 2 entiers 16 bits soit 4 octets et readBuffer lit des octets.
    int16Buffer = typecast(int8Buffer,'int16'); % On fait la conversion de 2 entiers 8 bits à 1 entier 16 bits
    cplxBuffer = double(int16Buffer(1:2:end)) + 1i *double(int16Buffer(2:2:end)); % Les voies I et Q sont entrelac?es, on d?sentrelace pour avoir le buffer complexe.
    %% Code utilisateur
    
    % première estimation grossière de l'offset
    offset1 = real(mean(cplxBuffer));
    y = cplxBuffer - offset1;
    
    [delta_t_hat, delta_f_hat] = estimation(y, s_p, T_e);

    % synchronisation
    y_l_desync = y(length(s_p)+delta_t_hat+1:end).*exp(1i*2*pi*delta_f_hat.*(1:length(y)-length(s_p)-delta_t_hat));

    % estimation de l'offset restant
    offset2 = mean(abs(s_p))-mean(abs(y_l_desync(1:length(s_p))));
    
    y_l_unoffset = y_l_desync - offset2;
    
    r_l = conv(y_l_unoffset, p);
    
    if (length(r_l) < N_bits * f_se)
        r_l = [r_l zeros(1,N_bits*f_se - length(r_l))];
    end

    r = downsample(r_l(f_se:N_bits*f_se), f_se);
    trame = r < 0;
    
    detected = 0;
    trace = 0;
    adresse = decodage_adresse(trame);
    
    % on regarde si on a déjà répertorié cet avion
    for i = 1:length(registres)
        if strcmp(registres(i).adresse, adresse)
            detected = 1;
            registres(i) = bit2registre(trame, registres(i));
            break;
        end
    end
    
    % sinon on crée un nouveau registre
    if ~detected
        registre = struct('immatriculation', [], 'adresse', [], 'airline', [], 'categorie', [], 'pays', [], 'format', [], ...
                          'type', [], 'nom', [], 'altitude', [], 'vitesse_air', [], 'vitesse_sol', [], 'taux', [], 'timeFlag', [], ...
                          'cprFlag', [], 'latitude', [], 'longitude', [], 'trajectoire', [], 'plot1', [], 'plot2', [], 'plot3', []);
        registre = bit2registre(trame, registre);
        
        % si pas d'erreur CRC, on l'ajoute dans le repertoire des registres
        if (~isempty(registre.adresse))
            registres = [registres, registre];
            i = length(registres);
        else
            % sinon on a eu une erreur CRC, on passe à la suite
            continue;
        end
    end
    
    if (~isempty(registres) && ~isempty(registres(i).trajectoire))
        % si le registre a une trajectoire, on la (re)trace
        longitudes = registres(i).trajectoire(1,:);
        latitudes = registres(i).trajectoire(2,:);
        altitudes = registres(i).trajectoire(3,:);
        
        PLANE_LON = longitudes(end);    % Longitude de l'avion
        PLANE_LAT = latitudes(end);     % Latitude de l'avion
        PLANE_ALT = altitudes(end);
        
        if (~isempty(registres(i).plot1) && ~isempty(registres(i).plot2) && ~isempty(registres(i).plot3))
            % on enlève ce qui a d?j? ?t? trac?
            delete(registres(i).plot1);
            delete(registres(i).plot2);
            delete(registres(i).plot3);
        end
        
        % si l'avion n'a pas d'immatriculation, on affiche son adresse
        if (~isempty(registres) && ~isempty(registres(i).immatriculation))
            Id_airplane = registres(i).immatriculation;
        else
            Id_airplane = registres(i).adresse;
        end

        points = fnplt(cscvn([longitudes;latitudes;altitudes]));
        
        % finalement, on affiche les informations n?cessaires
        registres(i).plot1 = plot3(points(1,:),points(2,:), points(3,:), 'b:');
        registres(i).plot2 = plot3(PLANE_LON,PLANE_LAT,PLANE_ALT,'*b', 'MarkerSize', 8);
        registres(i).plot3 = text(PLANE_LON+0.1,PLANE_LAT, PLANE_ALT, Id_airplane,'color','b');
    end
end

%% fermeture des flux
socket.close;
my_input_stream.close;
my_server.close;
disp (['Fin de connexion: ' datestr(now)]);
