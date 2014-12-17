function [lat, lon] = decodage_latitude_longitude(r_lat, r_lon, lat_ref, lon_ref, bit_CPR)

    LAT = bin2dec(num2str(r_lat));
    LON = bin2dec(num2str(r_lon));
    N_Z = 15;
    N_b = 17;
    
    %% Latitude
    % 1- calcul de la grandeur D_lat_i
    D_lat_i = 360 / (4*N_Z - bit_CPR);
    
    % 2- calcul de j
    j = floor(lat_ref/D_lat_i) + floor(1/2 + MOD(lat_ref, D_lat_i) / D_lat_i - LAT /(2^N_b));
    
    % 3- calcul de la latitude
    lat_num = troisieme_calcul(D_lat_i, LAT, j, N_b);
    lat = num2str(lat_num);
    
    %% Longitude
    % 1- calcul de D_lon_i
    N_L_lat_i = cprNL(lat_num) - bit_CPR;
    
    if (N_L_lat_i > 0)
        D_lon_i = 360 / N_L_lat_i;
    elseif (N_L_lat_i == 0)
        D_lon_i = 360;
    end
    
    % 2- calcul de m
    m = floor(lon_ref/D_lon_i) + floor(1/2 + MOD(lon_ref, D_lon_i) / D_lon_i - LON /(2^N_b));
    
    % 3- calcul de la longitude
    lon = troisieme_calcul(D_lon_i, LON, m, N_b);
    lon = num2str(lon);
end

function [mod] = MOD(x,y)
    mod = x - y * floor(x/y);
end

function [l] = troisieme_calcul(D, L, lettre, N_b)
    l = D * (lettre + L / 2^N_b);
end