function r = bit2registre(vecteur, r, lon_ref, lat_ref)

    % Immatriculation, Compagnie aérienne, Catégorie, Pays
    if (isempty(r.immatriculation) || isempty(r.airline) || isempty(r.categorie))
        [r.immatriculation, r.airline, r.categorie, r.pays] = adresse2immat(r.adresse);
    end

    % Type
    type = bin_dec(vecteur(33:37));
    r.type = type;

    if (type > 0 && type < 5)

        % message d'identification : on identifie l'avion
        r.nom = decodage_nom(vecteur);

    elseif (type == 19)

        % message de vitesse en vol
        subtype = bin_dec(vecteur(38:40));
        [r.vitesse_air, r.vitesse_sol, r.cap] = decodage_vitesse(vecteur, subtype);

        % taux de montée/descente
        if (bin_dec(vecteur(70:78)))
            taux = bin_dec(vecteur(70:78)) * 64 - 64;
            signe = vecteur(69);
            if (signe == 1)
                taux = -taux;
            end
            r.taux = taux;
        end

    elseif ((type > 4 && type < 9) || (type > 8 && type ~= 19 && type < 23))

        r.timeFlag = bin_dec(vecteur(53));
        bit_CPR = vecteur(54);
        r.cprFlag = bit_CPR;
        [lat, lon] = decodage_latitude_longitude(vecteur(55:71), vecteur(72:88), lat_ref, lon_ref, bit_CPR);

        if (type > 4 && type < 9)
            % message de position au sol
            alt = 0;
        elseif (type > 8 && type ~= 19 && type < 23)
            % message de position
            alt = decodage_altitude(vecteur(41:52));
        end

        r.trajectoire = [r.trajectoire, [lon; lat; alt * 0.3048]];
        r.longitude = lon;
        r.latitude = lat;
        r.altitude = alt;

    end
end

% Décodage de l'altitude
function alt  = decodage_altitude(bits_altitude)
    r_a = bits_altitude([1:7,9:12]);
    r_a = bin_dec(r_a);
    alt = 25 * r_a - 1000;
end

% Décodage du nom
function nom = decodage_nom(vecteur)
    caracteres = bin_dec(transpose(reshape((vecteur(41:88)), 6, 8)));
    nom = transpose(char((caracteres < 26) * 64 + caracteres));
    nom(isspace(nom)) = '';
end

% Décodage de la latitude et de la longitude
function [lat, lon] = decodage_latitude_longitude(r_lat, r_lon, lat_ref, lon_ref, bit_CPR)
    LAT = bin_dec(r_lat);
    LON = bin_dec(r_lon);
    N_Z = 15;
    N_b = 17;
    
    % Latitude
    D_lat_i = 360 / (4*N_Z - bit_CPR);
    j = calcul2(lat_ref, D_lat_i, LAT, N_b);
    lat = calcul3(D_lat_i, LAT, j, N_b);
    
    % Longitude
    N_L_lat_i = cprNL(lat) - bit_CPR;
    if (N_L_lat_i > 0)
        D_lon_i = 360 / N_L_lat_i;
    elseif (N_L_lat_i == 0)
        D_lon_i = 360;
    end
    m = calcul2(lon_ref, D_lon_i, LON, N_b);
    lon = calcul3(D_lon_i, LON, m, N_b);
end

function mod = MOD(x,y)
    mod = x - y * floor(x/y);
end

function lettre = calcul2(ref, D, L, N_b)
    lettre = floor(ref/D) + floor(1/2 + MOD(ref, D) / D - L/(2^N_b));
end

function l = calcul3(D, L, lettre, N_b)
    l = D * (lettre + L / 2^N_b);
end

function n = cprNL(lat)
    if (lat < 0)
        lat = -lat;
    end

    if (lat < 10.47047130)
        n = 59;
    elseif (lat < 14.82817437)
        n = 58;
    elseif (lat < 18.18626357)
        n = 57;
    elseif (lat < 21.02939493)
        n = 56;
    elseif (lat < 23.54504487)
        n = 55;
    elseif (lat < 25.82924707)
        n = 54;
    elseif (lat < 27.93898710)
        n = 53;
    elseif (lat < 29.91135686)
        n = 52;
    elseif (lat < 31.77209708)
        n = 51;
    elseif (lat < 33.53993436)
        n = 50;
    elseif (lat < 35.22899598)
        n = 49;
    elseif (lat < 36.85025108)
        n = 48;
    elseif (lat < 38.41241892)
        n = 47;
    elseif (lat < 39.92256684)
        n = 46;
    elseif (lat < 41.38651832)
        n = 45;
    elseif (lat < 42.80914012)
        n = 44;
    elseif (lat < 44.19454951)
        n = 43;
    elseif (lat < 45.54626723)
        n = 42;
    elseif (lat < 46.86733252)
        n = 41;
    elseif (lat < 48.16039128)
        n = 40;
    elseif (lat < 49.42776439)
        n = 39;
    elseif (lat < 50.67150166)
        n = 38;
    elseif (lat < 51.89342469)
        n = 37;
    elseif (lat < 53.09516153)
        n = 36;
    elseif (lat < 54.27817472)
        n = 35;
    elseif (lat < 55.44378444)
        n = 34;
    elseif (lat < 56.59318756)
        n = 33;
    elseif (lat < 57.72747354)
        n = 32;
    elseif (lat < 58.84763776)
        n = 31;
    elseif (lat < 59.95459277)
        n = 30;
    elseif (lat < 61.04917774)
        n = 29;
    elseif (lat < 62.13216659)
        n = 28;
    elseif (lat < 63.20427479)
        n = 27;
    elseif (lat < 64.26616523)
        n = 26;
    elseif (lat < 65.31845310)
        n = 25;
    elseif (lat < 66.36171008)
        n = 24;
    elseif (lat < 67.39646774)
        n = 23;
    elseif (lat < 68.42322022)
        n = 22;
    elseif (lat < 69.44242631)
        n = 21;
    elseif (lat < 70.45451075)
        n = 20;
    elseif (lat < 71.45986473)
        n = 19;
    elseif (lat < 72.45884545)
        n = 18;
    elseif (lat < 73.45177442)
        n = 17;
    elseif (lat < 74.43893416)
        n = 16;
    elseif (lat < 75.42056257)
        n = 15;
    elseif (lat < 76.39684391)
        n = 14;
    elseif (lat < 77.36789461)
        n = 13;
    elseif (lat < 78.33374083)
        n = 12;
    elseif (lat < 79.29428225)
        n = 11;
    elseif (lat < 80.24923213)
        n = 10;
    elseif (lat < 81.19801349)
        n = 9;
    elseif (lat < 82.13956981)
        n = 8;
    elseif (lat < 83.07199445)
        n = 7;
    elseif (lat < 83.99173563)
        n = 6;
    elseif (lat < 84.89166191)
        n = 5;
    elseif (lat < 85.75541621)
        n = 4;
    elseif (lat < 86.53536998)
        n = 3;
    elseif (lat < 87.00000000)
        n = 2;
    else
        n = 1;
    end
end