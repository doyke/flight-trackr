clear all;
close all;

% exemple
trames = load('projet_adsb/trames_20141120.mat');
trame_test = trames.trames_20141120;
trame_test = transpose(trame_test(:,9));

registre = struct('adresse', [], 'format', [], 'type', [], 'nom', [], 'altitude',[], ...
                  'timeFlag', [], 'cprFlag', [], 'latitude', [], 'longitude', [], 'trajectoire', []);

registre_maj = bit2registre(trame_test, registre);

adresse_hex = 393324;
immat = hex2imat(adresse_hex);


