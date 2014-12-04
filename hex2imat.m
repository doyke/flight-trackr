function [immatriculation] = hex2imat(adresse_hex)
    
    data = fopen('icao24plus.txt');

    while(~feof(data))
        line = fgetl(data);
        A = sscanf(line, '%d');
        
        if (A(1) == adresse_hex)
            immatriculation = line;
            immatriculation = immatriculation(find(isspace(immatriculation))+1:end);
            immatriculation = immatriculation(1:find(isspace(immatriculation))-1);
            break;
        end
    end
           
    fclose(data);

end

