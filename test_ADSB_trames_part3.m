%% ADSB Project

%% Initialization
clc
clear all
close all

javaaddpath('./sqlite-jdbc-3.8.7.jar');

%% Constants definition
PORT = 1234;
MER_LON = -0.710648; % Longitude de l'a?roport de M?rignac
MER_LAT = 44.836316; % Latitude de l'a?roport de M?rignac

%% Paramètres Utilisateur
Fc = 1090e6; % La fr?quence porteuse
Rs = 4e6; % Le rythme d'?chantillonnage (pas plus de 4Mhz)
T_e = 1/Rs;

%% Autres param?tres
Rb = 1e6;% d?bit binaire
N_bits = 112;
NsB = floor(Rs/Rb); % nombre d'?chantillons par symbole
f_se = NsB;

Ts = 1/Rb;
s_p = [1 0 1 0 0 0 0 1 0 1 0 0 0 0 0 0];                % s_p au rythme 0.5?s
s_p = upsample(s_p, Ts/(0.5E-6));

p = [-ones(1,f_se/2) ones(1,f_se/2)]/2;
p = p / norm(p);
registres = [];

%% Code utilisateur
abs_cplxBuffer = load('abs_cplxBuffer.mat');
real_cplxBuffer = load('real_cplxBuffer.mat');

absBuffer = abs_cplxBuffer.abs_cplxBuffer;
realBuffer = real_cplxBuffer.real_cplxBuffer;

longueur_trame = length(s_p) + N_bits * f_se;
n = 0:longueur_trame:length(absBuffer) - longueur_trame - 100;

for k = 1:length(n)-1

    Buffer = absBuffer(n(k)+1:n(k+1)+100);

    [delta_t_hat, rho] = estimation_sous_optimale(Buffer, s_p);

    % on s'évite des calculs
    if (rho < 0.7)
        continue;
    else
        figure, plot(Buffer(delta_t_hat+1:delta_t_hat+480))
        hold on
        rectangle('Position', [0,0,32,max(Buffer(delta_t_hat+1:delta_t_hat+32))],'EdgeColor', 'r')
        % decoupage pour lecture des bits
        for k = 0:70 
            yL = get(gca,'YLim');
            line([k*f_se k*f_se],yL,'Color','r');
        end
        hold off
        fprintf('Début de trame ADS-B possible trouvée à la position %d.\n', n(k)+delta_t_hat)
    end

    % synchronisation
    y_l_desync = Buffer(length(s_p)+delta_t_hat+1:length(s_p)+delta_t_hat+N_bits*f_se);

    % offset
    y_l_unoffset = (y_l_desync + median(findpeaks(-y_l_desync)));
    y_l_unoffset = y_l_unoffset / median(findpeaks(y_l_unoffset));

    r_l = conv(y_l_unoffset, p);

    if (length(r_l) < N_bits * f_se)
        r_l = [r_l zeros(1,N_bits*f_se - length(r_l))];
    end

    r = downsample(r_l(f_se:N_bits*f_se), f_se);
    trame = r >= 0;
    
    adresse_test = decodage_adresse(trame)
    DF = bin2dec(num2str(trame(1:5)))

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
        registre = struct('immatriculation', [], 'adresse', [], 'airline', [], 'categorie', [], 'pays', [], 'format', [], 'type', [], ...
                          'nom', [], 'altitude', [], 'vitesse_air', [], 'vitesse_sol', [], 'taux', [], 'cap', [], 'timeFlag', [], ...
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

%         if (~isempty(registres(i).plot1) && ~isempty(registres(i).plot2) && ~isempty(registres(i).plot3))
%             % on enlève ce qui a d?j? ?t? trac?
%             delete(registres(i).plot1);
%             delete(registres(i).plot2);
%             delete(registres(i).plot3);
%         end

        % si l'avion n'a pas d'immatriculation, on affiche son adresse
        if (~isempty(registres) && ~isempty(registres(i).immatriculation))
            Id_airplane = registres(i).immatriculation;
        else
            Id_airplane = registres(i).adresse;
        end

%        points = fnplt(cscvn([longitudes;latitudes;altitudes]));

        % finalement, on affiche les informations n?cessaires
%         registres(i).plot1 = plot3(points(1,:),points(2,:), points(3,:), 'b:');
%         registres(i).plot2 = plot3(PLANE_LON,PLANE_LAT,PLANE_ALT,'*b', 'MarkerSize', 8);
%         registres(i).plot3 = text(PLANE_LON+0.1,PLANE_LAT, PLANE_ALT, Id_airplane,'color','b');
    end
end