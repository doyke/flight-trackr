function [found, immat, airline, category] = flightradar_reader(adresse)
    
    found = 0;
    immat = [];
    airline = [];
    category = [];
    
    try
        data = loadjson(urlread(['http://www.flightradar24.com/data/_ajaxcalls/autocomplete_airplanes.php?&term=', adresse]));

        if (~isempty(data))
            found = 1;
            % si on a trouve qque ch
            struct = data{1};
            %disp(struct);
            immat = struct.id;
            label = struct.label;

            separator = strfind(label, ' - ');
            airline = label(separator(2)+3:separator(3)-1);

            category = label(separator(3)+3:end);
            separator_category = strfind(category, ' (');
            category = category(1:separator_category-1);
        end
    catch
    end
end