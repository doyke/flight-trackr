function [registres, id] = bits2registres(trames, lon_ref, lat_ref)

    % La fonction bits2registres permet de décoder les trames binaires et
    % les stocke sous forme de registres. Elle prend en argument :
    %       trames          les nouvelles trames détectées
    %       LON_REF         la longitude de référence
    %       LAT_REF         la latitude de référence

    registres = [];
    id = [];

    % Contrôle CRC
    trames(controle_crc(trames),:) = [];
    
    % Contrôle du format
    if (~isempty(trames))
        format = 17;
        trames(bin_dec(trames(:,1:5)) ~= format) = [];
    end
    
    if (~isempty(trames))
        % Nombre de trames restantes
        n = size(trames,1);
        registres = repmat(init_var(1), [n,1]);

        % Adresses
        [id, adresses] = decodage_adresse(trames);
        adresses = cellstr(adresses);
        id = num2cell(id);
        [registres.adresse] = deal(adresses{:});
        [registres.id] = deal(id{:});
        id = [];

        % Types
        types = bin_dec(trames(:,33:37));
        types_cell = num2cell(types);
        [registres.type] = deal(types_cell{:});

        % Noms
        cond = (types > 0 & types < 5);
        if (sum(cond))
            noms = cellstr(decodage_noms(trames(cond,:)));
            [registres(cond).nom] = deal(noms{:});
        end

        % Vitesse
        cond = (types == 19);
        if (sum(cond))
            subtype = decodage_subtypes(trames(cond,:));
            [vitesse_air, vitesse_sol, cap] = decodage_vitesse(trames(cond,:), subtype);
            [registres(cond).vitesse_air] = deal(vitesse_air{:});
            [registres(cond).vitesse_sol] = deal(vitesse_sol{:});
            [registres(cond).cap] = deal(cap{:});

            % Taux de montée / descente
            signes = -2 * trames(cond,69) + 1;
            taux = bin_dec(trames(cond,70:78)) * 64 - 64;
            taux = num2cell(taux .* signes);
            [registres(cond).taux] = deal(taux{:});
        end

        % Position
        cond = ((types > 4 & types < 9) | (types > 8 & types ~= 19 & types < 23));
        if (sum(cond))
            [latitudes, longitudes, CPR] = decodage_latitude_longitude(trames(cond,:), lat_ref, lon_ref);
            altitudes = decodage_altitude(trames(cond,:));

            [registres(cond).latitude] = deal(latitudes{:});
            [registres(cond).longitude] = deal(longitudes{:});
            [registres(cond).altitude] = deal(altitudes{:});
            [registres(cond).cprFlag] = deal(CPR{:});

            % Récupération des avions nécessitant une mise à jour sur la carte
            id = unique([registres(cond).id]);
        end
    end
end

function erreur = controle_crc(vecteur)
    h = crc.detector([ones(1,13), 0, 1, zeros(1,6), 1, 0, 0, 1]);
    [~, erreur] = detect(h, transpose(vecteur));
end
function [id, adresse_hex] = decodage_adresse(vecteur)
    id = bin_dec(vecteur(:,9:32));
    adresse_hex = dec2hex(bin_dec(vecteur(:,9:32)),6);
end
function nom = decodage_noms(vecteur)
    n = size(vecteur,1);
    vecteur = vecteur(:,41:88);
    codes = bin_dec(transpose(reshape(vecteur', 6, 8*n)));
    caracteres = char((codes < 26) * 64 + codes);
    nom = transpose(reshape(caracteres, 8, n));
end
function [vitesse_air, vitesse_sol, cap_cell] = decodage_vitesse(vecteur, subtype)
    vitesse_sol = cell(size(subtype));
    vitesse_air = cell(size(subtype));
    cap_cell = cell(size(subtype));
    
    % Vitesse sol
    cond = (subtype == 1 | subtype == 2);
    vitesse_EW = bin_dec(vecteur(cond,47:56))-1;
    vitesse_NS = bin_dec(vecteur(cond,58:67))-1;
    
    vitesse_sol(cond) = num2cell(sqrt(vitesse_EW.^2 + vitesse_NS.^2));
    
    direction_EW = vecteur(cond,46);
    direction_NS = vecteur(cond,57);
    
    angle = atan(vitesse_NS./vitesse_EW) * 180 / pi;
    
    subcond = (direction_EW == 0) & (direction_NS == 0);
    cap(subcond) = 90 - angle(subcond);
    
    subcond = (direction_EW == 0) & (direction_NS == 1);
    cap(subcond) = 90 + angle(subcond);
    
    subcond = (direction_EW == 1) & (direction_NS == 1);
    cap(subcond) = 270 - angle(subcond);
    
    subcond = (direction_EW == 1) & (direction_NS == 0);
    cap(subcond) = 270 + angle(subcond);
    
    cap_cell(cond) = num2cell(cap);
    
    % Vitesse air
    cond = (subtype == 3 | subtype == 4);
    vitesse_air(cond) = num2cell(bin_dec(vecteur(cond,58:67)) - 1);
    status = vecteur(cond, 46);
    cond = (status == 1);
    cap_cell(cond) = num2cell(bin_dec(vecteur(cond,47:56))*360/1024);

end
function subtypes = decodage_subtypes(trames)
    subtypes = bin_dec(trames(:,38:40));
end
function [lat, lon, CPR] = decodage_latitude_longitude(trames, lat_ref, lon_ref)
    r_lat = trames(:,55:71);
    r_lon = trames(:,72:88);
    bit_CPR = trames(:,54);

    LAT = bin_dec(r_lat);
    LON = bin_dec(r_lon);
    N_Z = 15;
    N_b = 17;
    
    % Latitude
    D_lat_i = 360 ./ (4*N_Z - bit_CPR);
    j = calcul2(lat_ref, D_lat_i, LAT, N_b);
    lat = calcul3(D_lat_i, LAT, j, N_b);
    
    % Longitude
    N_L_lat_i = cprNL(lat) - bit_CPR;
    D_lon_i = 360 * ones(size(N_L_lat_i));
    D_lon_i(N_L_lat_i > 0) = 360 ./ N_L_lat_i;
    m = calcul2(lon_ref, D_lon_i, LON, N_b);
    lon = calcul3(D_lon_i, LON, m, N_b);
    
    lat = num2cell(lat);
    lon = num2cell(lon);
    CPR = num2cell(bit_CPR);
end
function alt  = decodage_altitude(trames)
    bits_altitude = trames(:,41:52);
    r_a = bin_dec(bits_altitude(:,[1:7,9:12]));
    alt = 25 * r_a - 1000;
    alt = num2cell(alt);
end

function mod = MOD(x,y)
    mod = x - y .* floor(x./y);
end
function lettre = calcul2(ref, D, L, N_b)
    lettre = floor(ref./D) + floor(1/2 + MOD(ref, D) ./ D - L/(2^N_b));
end
function l = calcul3(D, L, lettre, N_b)
    l = D .* (lettre + L / 2^N_b);
end
function n = cprNL(lat)
    lat = abs(lat);
    n = ones(size(lat));
    n(lat < 87.00000000) = 2;
    n(lat < 86.53536998) = 3;
    n(lat < 85.75541621) = 4;
    n(lat < 84.89166191) = 5;
    n(lat < 83.99173563) = 6;
    n(lat < 83.07199445) = 7;
    n(lat < 82.13956981) = 8;
    n(lat < 81.19801349) = 9;
    n(lat < 80.24923213) = 10;
    n(lat < 79.29428225) = 11;
    n(lat < 78.33374083) = 12;
    n(lat < 77.36789461) = 13;
    n(lat < 76.39684391) = 14;
    n(lat < 75.42056257) = 15;
    n(lat < 74.43893416) = 16;
    n(lat < 73.45177442) = 17;
    n(lat < 72.45884545) = 18;
    n(lat < 71.45986473) = 19;
    n(lat < 70.45451075) = 20;
    n(lat < 69.44242631) = 21;
    n(lat < 68.42322022) = 22;
    n(lat < 67.39646774) = 23;
    n(lat < 66.36171008) = 24;
    n(lat < 65.31845310) = 25;
    n(lat < 64.26616523) = 26;
    n(lat < 63.20427479) = 27;
    n(lat < 62.13216659) = 28;
    n(lat < 61.04917774) = 29;
    n(lat < 59.95459277) = 30;
    n(lat < 58.84763776) = 31;
    n(lat < 57.72747354) = 32;
    n(lat < 56.59318756) = 33;
    n(lat < 55.44378444) = 34;
    n(lat < 54.27817472) = 35;
    n(lat < 53.09516153) = 36;
    n(lat < 51.89342469) = 37;
    n(lat < 50.67150166) = 38;
    n(lat < 49.42776439) = 39;
    n(lat < 48.16039128) = 40;
    n(lat < 46.86733252) = 41;
    n(lat < 45.54626723) = 42;
    n(lat < 44.19454951) = 43;
    n(lat < 42.80914012) = 44;
    n(lat < 41.38651832) = 45;
    n(lat < 39.92256684) = 46;
    n(lat < 38.41241892) = 47;
    n(lat < 36.85025108) = 48;
    n(lat < 35.22899598) = 49;
    n(lat < 33.53993436) = 50;
    n(lat < 31.77209708) = 51;
    n(lat < 29.91135686) = 52;
    n(lat < 27.93898710) = 53;
    n(lat < 25.82924707) = 54;
    n(lat < 23.54504487) = 55;
    n(lat < 21.02939493) = 56;
    n(lat < 18.18626357) = 57;
    n(lat < 14.82817437) = 58;
    n(lat < 10.47047130) = 59;
end