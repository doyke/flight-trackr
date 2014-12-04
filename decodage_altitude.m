function [alt] = decodage_altitude(bits_altitude)

    r_a = bits_altitude([1:7,9:12]);
    r_a = bin2dec(num2str(r_a));
    alt = 25*r_a - 1000;
    alt = num2str(alt);

end