ADSB
====

## Partie 1 - Couche physique ADS-B ##

### ADSB_part1_1.m ###

- Question 11 - Affichage de s_l(t) pour les 25 premiers bits
- Question 12 - Diagramme de l'oeil de durée 2*T_s pour 100 bits
- Question 13 - DSP de s_l(t) avec DSP théorique

### ADSB_part1_2.m ###

- Question 14 - Calcul du TEB en fonction du SNR variant de 0 à 10dB et valeur théorique de P_b --> OK
- Question 15 - Démonstration pour l'argmax
- Question 16 - Effet Doppler

### ADSB_part1_3.m ###

- Question 17 - Algorithme de synchronisation temps/fréquence et TEB --> TEB à recalculer

## Partie 2 - Traitement / décodage de signaux réels ##

- Question 18 - Valeurs du FTC pour des trames de position de vol / identification
- Question 19 - bit2registre avec CRC
- Question 20 - plot de la position de l'avion grâce aux trames de test
- Question 21 - nom = 'AF255YO', immatriculation = 'F-GMZE' à partir de l'adresse  = '393324'. Grâce à une recherche dans la base de données de flightradar24.com <http://www.flightradar24.com/data/>, l'avion immatriculé F-GMZE est un Airbus A321 appartenant à Air France.
Les trames de positions en vol nous ont permis de tracer sa trajectoire, au décollage à Mérignac :

![plot_position_avion](https://github.com/eftov/ADSB/blob/master/plot_pos_F-GMZE.png)
