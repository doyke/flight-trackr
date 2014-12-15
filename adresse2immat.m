function [immat] = adresse2immat(adresse_dec)
    
    fd = fopen('icao24.txt');
    
    while (~feof(fd))
        line = fgetl(fd);
        A = sscanf(line, '%x');
        if (A(1) == adresse_dec)
            pos = find(isspace(sscanf(line,'%s%c')));
            
            debut = pos(1)+1;
            
            if (length(pos) == 1)
                fin = length(line);
            else
                fin = pos(2)-1;
            end
            
            immat = line(debut:fin);
            break;
        end
    end
    
    fclose(fd);

end