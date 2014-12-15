function [immatriculation] = hex2imat(adresse_hex)
    
    adresse_hex = str2num(adresse_hex);
    data = fopen('icao_imat.txt');

    while(~feof(data))
        line = fgetl(data);
        A = sscanf(line, '%x');
        
        if (A(1) == adresse_hex)
            immatriculation = line;
            immatriculation = immatriculation(find(isspace(immatriculation))+1:end);
            immatriculation = immatriculation(1:find(isspace(immatriculation))-1);
            break;
        end
    end
           
    fclose(data);

end
