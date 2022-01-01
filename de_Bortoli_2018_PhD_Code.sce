//Les paramètres à modifier dans le code selon l'étude de cas peuvent être repérés avec un contrôle f "//Paramètre"

//Lancement du compteur de temps de calcul
tic();


//MODULE - DEFINITION DU SYSTEME DE REFERENCE
DVT_chaussee=39;//Paramètre
//Année de début d'évaluation = à laquelle on veut savoir quel entretien réaliser quand
Annee(1)=2017; //Paramètre
for i = 2:DVT_chaussee,
    Annee(i) = Annee(1) + i - 1;
end

//Tronçon - définition du type de route, de la géométrie, et appel des données d'IRI par l'évaluateur
nb_voies = 2; //Paramètre //Ici l'utilisateur indique le nombre de voies de son tronçon. Sur RD de voies < 3.5m, on entre 0
longueur = 10.54; //Paramètre // Ici l'utilisateur indique la longueur de son tronçon en km
//Charger les données d'IRI et les nommer
FichierIRI = readxls('C:\Users\anne.de-bortoli\Dropbox\LVMT\Rédaction\Partie 3\Calculs_Etude_Cas\Donnees\A81_Troncon1_Donnees_VECTRA_IRI.xls');//associe le fichier avec chemin (voir "propriétés" du tableur) et le nomme. Attention, format XLS2003 ou antérieur pris en charge
FeuilleIRI=FichierIRI(1);//Pointe sur la feuille 1
ValeursIRI=FeuilleIRI.value; //Récupère les données numériques
//Créer les vecteurs de localisation et d'IRI bi-trace et moyennés
IRIg=ValeursIRI(:,3);
IRId=ValeursIRI(:,4);
IRI0=(IRIg+IRId)/2.;
    
//Trafic - Définition du parc et du trafic, calcul d'évolution du TMJA
//TMJA
TMJA0 = 10728; //Paramètre //trafic 2014, données VINCI
croissante_trafic=0.44/100; //Paramètre //croissance de trafic sur le réseau Cofiroute
TMJA1=TMJA0*(1+(Annee(1)-2014)*croissante_trafic); //calcul trafic 2017
%VP=9158/TMJA0; //Paramètre //Part du trafic VP sur le tronçon considéré, (format 1=100%)), données VINCI
%VUL=434/TMJA0; //Id
%PPL=123/TMJA0; //Id
%GPL=1013/TMJA0; //Id
%VL=%VP+%VUL;
%PL=%PPL+%GPL;

TMJA(1) = TMJA1 ;
for i = 2:DVT_chaussee,
    TMJA(i) = TMJA(i-1)*(1+croissante_trafic);
end
//Vitesses
Vmoy_RA_VL=118;//Paramètre
Vmoy_RA_PL=88;//Paramètre

//MODULE - POLITIQUE DE RESURFACAGE

//Type de revêtement de resurfaçage choisi
RESURFACAGE = ['BBSG' ; 'BBM';'BBTM'; 'BBUM'; 'ECF monocouche'; 'ECF bicouche';'ESU bicouche'; 'ESU bicouche pregravillonne'];
TYPE_RESURFACAGE = RESURFACAGE(3); //Paramètre

//Cycles de resurfaçage //Paramètre
DV_surface_invest_min=DVT_chaussee/2;
DV_surface_ref=DVT_chaussee/3;
DV_surface_invest_plus=DVT_chaussee/4;
DV_surface_max_terrain=DVT_chaussee/5;
DV_surface_invest_max=DVT_chaussee/7;

//Choix_scenario
DVS_scenario = [ DV_surface_invest_min, DV_surface_ref ,DV_surface_invest_plus ,DV_surface_max_terrain , DV_surface_invest_max  ];//durée de vie de la surface, j'arrondis à l'entier le plus proche, sinon on a des décimales que l'on ne peut pas identifier comme colonne d'IRI annuelle après
calcul_scenario=2;//Paramètre
Noms_scenario = [ "DV_surface_invest_min", "DV_surface_ref" ,"DV_surface_invest_plus" ,"DV_surface_max_terrain" ,"DV_surface_invest_max"];
DVS=DVS_scenario(calcul_scenario);

//EVOLUTION ETAT CHAUSSEE

//Calcul la matrice d'évolution d'IRI(t) selon le moment de resurfaçage tR, (on considère ici que l'impact du resurfaçage ne dépend pas de la technique(or épaisseur BBTM inférieure donc effet différent)), avec t de 1 à 50, par pas de 1 an
Pente_IRI_annuelle=0.05; //peut varier, choix arbitraire selon étude biblio, serait intéressant de faire un travail stat sur données réelles
a_resurf=0.3; //adaptation de Wang et al 2013 pour l'effet d'un resurfaçage avec revêtement américain entre 3cm et 7.5cm d'épaisseur
b_resurf=0.15;  //adaptation de Wang et al 2013, étude XLS/IRI A81
IRI(:,1) = a_resurf*IRI0+b_resurf+0.5*Pente_IRI_annuelle;//au lieu d'approximer l'état de surface de l'année 1 à celui juste après resurfaçage, on calcule la moyenne de l'état de surface sur l'année 1
//Calcul de la matrice d'IRI en scénario S1 IRI_S1
for j = 2:DVT_chaussee,
    if j < round(DVS)+1
        IRI(:,j) = IRI(:,1)+(j-1)*Pente_IRI_annuelle ;
    end
end
IRI(:,round(DVS)+1)=a_resurf*(IRI(:,round(DVS)+1-1)+0.5*Pente_IRI_annuelle)+b_resurf+0.5*Pente_IRI_annuelle;//en 6 mois, on compte une demi-pente annuelle pour calculer l'état de surface en fin de cycle, puis on calcule là-dessus l'effet des travaux, puis on calcule l'état moyen sur l'année après resurfaçage
for j = round(DVS)+1+1:DVT_chaussee,
    if j<round(2*DVS)+1,
        IRI(:,j) = IRI(:,round(DVS)+1)+(j-round(DVS)+1)*Pente_IRI_annuelle ;
    end
end
IRI(:,round(2*DVS)+1)=a_resurf*(IRI(:,round(2*DVS)+1-1)+0.5*Pente_IRI_annuelle)+b_resurf+0.5*Pente_IRI_annuelle;
for j = round(2*DVS)+1+1:DVT_chaussee,
    if j<round(3*DVS)+1,
        IRI(:,j) = IRI(:,round(2*DVS)+1)+(j-round(2*DVS)+1)*Pente_IRI_annuelle ;
    end
end
IRI(:,round(3*DVS)+1)=a_resurf*(IRI(:,round(3*DVS)+1-1)+0.5*Pente_IRI_annuelle)+b_resurf+0.5*Pente_IRI_annuelle;
for j = round(3*DVS)+1+1:DVT_chaussee,
    if j<round(4*DVS)+1,
        IRI(:,j) = IRI(:,round(3*DVS)+1)+(j-round(3*DVS)+1)*Pente_IRI_annuelle ;
    end
end
IRI(:,round(4*DVS)+1)=a_resurf*(IRI(:,round(4*DVS)+1-1)+0.5*Pente_IRI_annuelle)+b_resurf+0.5*Pente_IRI_annuelle;
for j = round(4*DVS)+1+1:DVT_chaussee,
    if j<round(5*DVS)+1,
        IRI(:,j) = IRI(:,round(4*DVS)+1)+(j-round(4*DVS)+1)*Pente_IRI_annuelle ;
    end
end
IRI(:,round(5*DVS)+1)=a_resurf*(IRI(:,round(5*DVS)+1-1)+0.5*Pente_IRI_annuelle)+b_resurf+0.5*Pente_IRI_annuelle;
for j = round(5*DVS)+1+1:DVT_chaussee,
    if j<round(6*DVS)+1,
        IRI(:,j) = IRI(:,round(5*DVS)+1)+(j-round(5*DVS)+1)*Pente_IRI_annuelle ;
    end
end
IRI(:,round(6*DVS)+1)=a_resurf*(IRI(:,round(6*DVS)+1-1)+0.5*Pente_IRI_annuelle)+b_resurf+0.5*Pente_IRI_annuelle;
for j = round(6*DVS)+1+1:DVT_chaussee,
    if j<round(7*DVS)+1,
        IRI(:,j) = IRI(:,round(6*DVS)+1)+(j-round(6*DVS)+1)*Pente_IRI_annuelle ;
    end
end
IRI=IRI(1:length(IRI0),1:DVT_chaussee);
//MODULE - DEPENSES TRAVAUX

//Coûts financiers TTC, en euros courants 2017 /m²
cout_RESURFACAGE(1)=18; //BBSG
cout_RESURFACAGE(2)=14; //BBM
cout_RESURFACAGE(3)=10; //BBTM
cout_RESURFACAGE(4)=8; //BBUM, coût pifométrique
cout_RESURFACAGE(5)=5; //ECF monocouche
cout_RESURFACAGE(6)=5;//ECF bicouche
cout_RESURFACAGE(7)=3; //ESU bicouche
cout_RESURFACAGE(8)=3;//ESU bicouche pregravillonne

// surface de chaussée du tronçon en m2, avc 1m de bande dérasée et 3m de BAU
surface = (nb_voies * 3.5 + 1 + 3) * longueur * 1000 ;//en m²

//Gestion chantier - on devra continuer à développer ce module plus tard, pour l'instant on n'indique que ce qui nous intéresse
GESTION_CHANTIER = ['NUIT' ; 'JOUR';'3x8'];
TYPE_GESTION_CHANTIER = GESTION_CHANTIER(2); //Paramètre, mais code à adapter par la suite pour nuit et 3x8
nb_jours_1resurfacage=longueur/0.8;//Paramètre
Vreduite=90; //Réduction de la vitesse maximale à 90km/h pendant les travaux //paramètre

//Gêne aux usagers par les travaux de resurfaçage - dans notre cas autoroutier les PL ne ralentissent pas, mais il faudra développer le cas général
for i=1:DVT_chaussee,
    if round(i*DVS)+1<DVT_chaussee then
        TMJA_travaux(i) =TMJA(round(i*DVS)+1);
    end
end
tps_perdu_travaux_VL=nb_jours_1resurfacage*2*sum(TMJA_travaux(1:length(TMJA_travaux)))*(%VP+%VUL)*longueur*(1/Vreduite-1/Vmoy_RA_VL);//En nombre d'heures - ATTENTION, on met un facteur 2 car on considère que le trafic est basculé dans l'autre sens, et que donc les deux sens sont impactés par la réduction de vitesse (on considère le même trafic))

//MODULE : CONSOMMATIONS VEHICULAIRES

//PNEUMATIQUES

//Modèle d'usure physique
//Nombre de pneus par type de véhicule
nb_roue_VP=4;
nb_roue_VUL=4;
nb_roue_PPL=4;//paramètre
nb_roue_GPL=10;//Paramètre

//Durées de Vie Typiques DVT en km à IRI=1m/km
DVT_pneu_RA_VP=47383;
DVT_pneu_RA_VUL=35413;
DVT_pneu_RA_PPL=177757;
DVT_pneu_RA_GPL=191244;

//Lois d'usure pneumatique en fonction de l'IRI sur réseau autoroutier (RA) français selon l’IRI(ajouter les autres lois RE et RN/RD plus tard)
function y=SP_VP_RA(x) ; y=0.0169*x+0.9812 ;
endfunction
function y=SP_VUL_RA(x) ; y=0.0102*x+0.9927 ;
endfunction
function y=SP_PPL_RA(x) ; y=0.0122*x+0.9866 ;
endfunction
function y=SP_GPL_RA(x) ; y=0.0089*x+0.9917 ;
endfunction

//Nombres de pneumatiques usés sur la période par type
//calcul de la matrice des facteurs d'usure pneumatiques de chaque type de pneu par an entre Annee(1) et Annee(50)
FUP_VP_RA=SP_VP_RA(IRI);//Facteur d'usure des VP sur RA selon la matrice d'IRI (par sous-tronçon en ligne et par an en colonnes)
FUP_VUL_RA=SP_VUL_RA(IRI); //id VUL
FUP_PPL_RA=SP_PPL_RA(IRI); //id
FUP_GPL_RA=SP_GPL_RA(IRI); //id

//calcul de la matrice de consommation de pneus par type de véhicule (VP, VUL, PPL, GPL) par sous-tronçon (lignes)et sur un jour par an (colonnes)
for j=1:DVT_chaussee,
    CP_VP_RA(:,j) = nb_roue_VP/DVT_pneu_RA_VP*10/1000*TMJA(j)*%VP*FUP_VP_RA(:,j);//nombre de pneus VP usés 
    CP_VUL_RA(:,j) = nb_roue_VUL/DVT_pneu_RA_VUL*10/1000*TMJA(j)*%VUL*FUP_VUL_RA(:,j);
    CP_PPL_RA(:,j) = nb_roue_PPL/DVT_pneu_RA_PPL*10/1000*TMJA(j)*%PPL*FUP_PPL_RA(:,j);
    CP_GPL_RA(:,j) = nb_roue_GPL/DVT_pneu_RA_GPL*10/1000*TMJA(j)*%GPL*FUP_GPL_RA(:,j);
end

//Calcul de la somme des pneus consommés par catégorie de véhicule et par an
for i=1:DVT_chaussee,
    Nb_pneus_VP_RA(i) = 365*sum(CP_VP_RA(:,i));
    Nb_pneus_VUL_RA(i) = 365*sum(CP_VUL_RA(:,i));
    Nb_pneus_PPL_RA(i) = 365*sum(CP_PPL_RA(:,i));
    Nb_pneus_GPL_RA(i) = 365*sum(CP_GPL_RA(:,i));
end

//Modèle financier
//Fonctions de coûts kilométriques en Euros2017 en dépenses pneumatique par type de véhicule
function y=ckm_pneu_VP_RA(x) ; y=0.0003*x+0.019 ;
endfunction
function y=ckm_pneu_VUL_RA(x) ; y=0.0001*x+0.0126 ;
endfunction
function y=ckm_pneu_PPL_RA(x) ; y=0.0002*x+0.0133 ;
endfunction
function y=ckm_pneu_GPL_RA(x) ; y=0.0003*x+0.0311 ;
endfunction
//calcul de la matrice des facteurs de coûts d'entretien en pneumatiques de chaque type de pneu par an entre Annee(1) et Annee(50)
FCP_VP_RA=ckm_pneu_VP_RA(IRI);//Facteur de coûts d'entretien en pneumatiques des VP sur RA selon la matrice d'IRI (par sous-tronçon en ligne et par an en colonnes)
FCP_VUL_RA=ckm_pneu_VUL_RA(IRI); //id VUL
FCP_PPL_RA=ckm_pneu_PPL_RA(IRI); //id
FCP_GPL_RA=ckm_pneu_GPL_RA(IRI); //id

//calcul de la matrice de coûts journaliers de pneus par type de véhicule (VP, VUL, PPL, GPL) par sous-tronçon (lignes) par an (colonnes)
for j=1:DVT_chaussee,
    CJP_VP_RA(:,j) = 10/1000*TMJA(j)*%VP*FCP_VP_RA(:,j);//nombre de pneus VP usés 
    CJP_VUL_RA(:,j) = 10/1000*TMJA(j)*%VUL*FCP_VUL_RA(:,j);
    CJP_PPL_RA(:,j) = 10/1000*TMJA(j)*%PPL*FCP_PPL_RA(:,j);
    CJP_GPL_RA(:,j) = 10/1000*TMJA(j)*%GPL*FCP_GPL_RA(:,j);
end

//Calcul de la somme des cout en entretien pneus par catégorie de véhicule et par an en euros 2017
for i=1:DVT_chaussee,
    cout_pneus_VP_RA(i) = 365*sum(CJP_VP_RA(:,i));
    cout_pneus_VUL_RA(i) = 365*sum(CJP_VUL_RA(:,i));
    cout_pneus_PPL_RA(i) = 365*sum(CJP_PPL_RA(:,i));
    cout_pneus_GPL_RA(i) = 365*sum(CJP_GPL_RA(:,i));
    cout_pneus(i)=cout_pneus_VP_RA(i)+cout_pneus_VUL_RA(i)+cout_pneus_PPL_RA(i)+cout_pneus_GPL_RA(i);
end

//ENTRETIEN & SUSPENSIONS
//NC pour notre étude autoroutière puisque max(IRI)=3.065


//CARBURANT

//Consommations et émissions moyennes de nos catégories de véhicules à IRI moyen, selon l'année, calculés avec le logiciel CopCETE
BDD_CopCETE = readxls('C:\Users\anne.de-bortoli\Dropbox\LVMT\Rédaction\Partie 3\Calculs_Etude_Cas\Donnees\BDD_Conso_Emissions.xls');
for i = 1:39,
    if Annee(i) < 2030 then 
        CopCETE(Annee(i)).Table = BDD_CopCETE(Annee(i)-2015);//Pointe sur la feuille de la bonne année
    else CopCETE(Annee(i)).Table = BDD_CopCETE(15);//id
    end
end

//Calcul des vecteurs des consommations annuelles moyennes par type de véhicule
for i=1:DVT_chaussee,
    C_VP_diesel_moy_RA(i)=CopCETE(Annee(i)).Table(24,4); //g/km; travailler avec CopCETE
    C_VP_essence_moy_RA(i)=CopCETE(Annee(i)).Table(25,4);
    C_VUL_diesel_moy_RA(i)=CopCETE(Annee(i)).Table(28,4);
    C_VUL_essence_moy_RA(i)=CopCETE(Annee(i)).Table(29,4);
    C_PL_diesel_moy_RA(i)=CopCETE(Annee(i)).Table(31,4);
end

//Lois de SurConsommation et Emissions sur réseau autoroutier (RA) français selon l’IRI (ajouter les autres lois RE et RN/RD plus tard)
function y=SCE_VP_RA(x) ; y=0.0233*x+0.975 ;
endfunction
function y=SCE_VUL_RA(x) ; y=0.00710*x+0.996 ;
endfunction
function y=SCE_PPL_RA(x) ; y=0.00870*x+0.992 ;
endfunction
function y=SCE_GPL_RA(x) ; y=0.0170*x+0.981 ;
endfunction

//Litres de carburant (diesel, pétrole) consommés sur la période par type
//calcul de la matrice des facteurs de consommation pour chaque type de véhicules par an entre Annee(1) et Annee(50)
FCE_VP_RA=SCE_VP_RA(IRI);//Facteur de consommation des VP sur RA selon la matrice d'IRI (par sous-tronçon en ligne et par an en colonnes) par rapport à un IRI=1m/km
FCE_VUL_RA=SCE_VUL_RA(IRI); //id VUL
FCE_PPL_RA=SCE_PPL_RA(IRI); //id
FCE_GPL_RA=SCE_GPL_RA(IRI); //id

//calcul de la matrice de consommation de carburant en g par type de véhicule (VP, VUL, PPL, GPL), par type de carburant et par sous-tronçon (lignes)et sur un jour par an (colonnes)
IRImoy_RA=0.77;//on le prend égal à l'IRI moyen de toute l'A81 et on considère qu'il est fixe au cours du temps, ce qui n'est probablement pas vrai (selon politiques d'investissement)
for j=1:DVT_chaussee,
    CC_VP_diesel_RA(:,j) = C_VP_diesel_moy_RA(j)/SCE_VP_RA(IRImoy_RA)*10/1000*TMJA(j)*%VP*FCE_VP_RA(:,j);//on reprend la formule cahier algo : C(IRI)=SC(IRI)*Cmoy(année)/SC(IRImoy)
    CC_VP_essence_RA(:,j) = C_VP_essence_moy_RA(j)/SCE_VP_RA(IRImoy_RA)*10/1000*TMJA(j)*%VP*FCE_VP_RA(:,j);//
     CC_VUL_diesel_RA(:,j) = C_VUL_diesel_moy_RA(j)/SCE_VUL_RA(IRImoy_RA)*10/1000*TMJA(j)*%VUL*FCE_VUL_RA(:,j);//
    CC_VUL_essence_RA(:,j) = C_VUL_essence_moy_RA(j)/SCE_VUL_RA(IRImoy_RA)*10/1000*TMJA(j)*%VUL*FCE_VUL_RA(:,j);//
    CC_PPL_diesel_RA(:,j) = C_PL_diesel_moy_RA(j)/SCE_PPL_RA(IRImoy_RA)*10/1000*TMJA(j)*%PPL*FCE_PPL_RA(:,j);//
    CC_GPL_diesel_RA(:,j) = C_PL_diesel_moy_RA(j)/SCE_GPL_RA(IRImoy_RA)*10/1000*TMJA(j)*%GPL*FCE_GPL_RA(:,j);//
end

//Calcul des volumes de carburants consommés sur notre tronçon, par an et par type 

//densité des carburants
d_diesel=0.85; //kg/L
d_essence=0.75;//+/-20%, source AFNOR  "NF EN 228" traduction de la norme européenne EN 228

//Sommation des tronçons et des jours et passage de g/tronçon aux L/tronçon
for i=1:DVT_chaussee,
    V_diesel_VL(i) = 365*(sum(CC_VP_diesel_RA(:,i))+sum(CC_VUL_diesel_RA(:,i)))/1000/d_diesel;//passage de g aux L
    V_essence_VL(i) = 365*(sum(CC_VP_essence_RA(:,i))+sum(CC_VUL_essence_RA(:,i)))/1000/d_essence;
    V_diesel_PL(i) = 365*(sum(CC_PPL_diesel_RA(:,i))+sum(CC_GPL_diesel_RA(:,i)))/1000/d_diesel;
    V_carburant_VP(i)=365*(sum(CC_VP_diesel_RA(:,i))+sum(CC_VP_essence_RA(:,i)))/1000/d_diesel;
    V_carburant_VUL(i)=365*(sum(CC_VUL_diesel_RA(:,i))+sum(CC_VUL_essence_RA(:,i)))/1000/d_diesel;//Besoin pour calculer les temps passés à faire le plein, par type de veh
    V_carburant_PPL(i) = 365*(sum(CC_PPL_diesel_RA(:,i)))/1000/d_diesel;
    V_carburant_GPL(i) = 365*(sum(CC_GPL_diesel_RA(:,i)))/1000/d_diesel;    
end

//Calcul des 26 types d'émissions
//Type d'émissions
EMISSION = ['CO2';'CO';'NOx';'COV';'Benzène';'PM';'SO2';'Pb';'Cd';'CH4';'COVNM';'N2O';'NH3';'HAP';'Cu';'Cr';'Ni';'Se';'Zn';'Ba';'As';'Acroleine';'Formaldehyde';'Butadiene';'Acetaldehyde';'Benzoapyrene'];

//Calcul des émissions annuelles moyennes de type j par type de véhicule par km et selon l'année i
for j=1:26,
    for i=1:DVT_chaussee,
        Emission(j).VP(i)=CopCETE(Annee(i)).Table(24,j+4)+CopCETE(Annee(i)).Table(25,j+4); //en g/km ou mg/km 
        Emission(j).VUL(i)=CopCETE(Annee(i)).Table(28,j+4)+CopCETE(Annee(i)).Table(29,j+4);
        Emission(j).PL(i)=CopCETE(Annee(i)).Table(31,j+4);
    end
end

//Emissions totales par type libérées par an par type

//calcul de la matrice pour chaque type d'émission j de la masse émise en g ou mg sur un jour : ligne = sous-tronçon ; colonnes = année d'évaluation
for j=1:26,
    for i=1:DVT_chaussee,
        M_Emission(j).Table(:,i) = Emission(j).VP(i)/SCE_VP_RA(IRImoy_RA)*10/1000*TMJA(i)*%VP*FCE_VP_RA(:,i)+Emission(j).VUL(i)/SCE_VUL_RA(IRImoy_RA)*10/1000*TMJA(i)*%VUL*FCE_VUL_RA(:,i)+Emission(j).PL(i)/SCE_PPL_RA(IRImoy_RA)*10/1000*TMJA(i)*%PPL*FCE_PPL_RA(:,i)+Emission(j).PL(i)/SCE_GPL_RA(IRImoy_RA)*10/1000*TMJA(i)*%GPL*FCE_GPL_RA(:,i);//on reprend la formule cahier algo : C(IRI)=SC(IRI)*Cmoy(année)/S//C(IRImoy);
    end
end

//Calcul des émissions sur notre tronçon, par an i et par type j

//Sommation des tronçons et des jours
for j=1:26,
    for i=1:DVT_chaussee,
     Mtot_Emission(j,i) = 365*(sum(M_Emission(j).Table(:,i)));
     end
end

//MODULE - CALCULS INDICATEURS


//INDICATEUR environnementaux

//Charger les impacts environnementaux EndPoints et les nommer
BDD_Env = readxls('C:\Users\anne.de-bortoli\Dropbox\LVMT\Rédaction\Partie 3\Calculs_Etude_Cas\Donnees\BDD_ACV.xls');//associe le fichier avec chemin (voir "propriétés" du tableur) et le nomme. Attention, format XLS2003 ou antérieur pris en charge
Impact_ACV=BDD_Env(1);//Pointe sur la feuille 1
Valeurs_ACV=Impact_ACV.value; //Récupère les données numériques

//Bilan environnemental - travaux chaussée, selon la technique i (cf chaine "resurfaçage")

for i=1:8,
    sante_RESURFACAGE(i) = Valeurs_ACV(4,12+i)*surface*(DVT_chaussee/DVS-1);
    biodiversite_RESURFACAGE(i) = Valeurs_ACV(5,12+i)*surface*(DVT_chaussee/DVS-1);
    ressource_RESURFACAGE(i) = Valeurs_ACV(6,12+i)*surface*(DVT_chaussee/DVS-1);
end

//Bilan environnemental - pneumatiques usés par an
for i=1:DVT_chaussee,
    sante_pneu_VP(i) = Valeurs_ACV(4,7)*Nb_pneus_VP_RA(i)/nb_roue_VP;
    sante_pneu_VUL(i) = Valeurs_ACV(4,8)*Nb_pneus_VUL_RA(i)/nb_roue_VUL;
    sante_pneu_PPL(i) = Valeurs_ACV(4,9)*Nb_pneus_PPL_RA(i)/nb_roue_PPL;
    sante_pneu_GPL(i) = Valeurs_ACV(4,10)*Nb_pneus_GPL_RA(i)/nb_roue_GPL;
    biodiversite_pneu_VP(i) = Valeurs_ACV(5,7)*Nb_pneus_VP_RA(i)/nb_roue_VP;
    biodiversite_pneu_VUL(i) = Valeurs_ACV(5,8)*Nb_pneus_VUL_RA(i)/nb_roue_VUL;
    biodiversite_pneu_PPL(i) = Valeurs_ACV(5,9)*Nb_pneus_PPL_RA(i)/nb_roue_PPL;
    biodiversite_pneu_GPL(i) = Valeurs_ACV(5,10)*Nb_pneus_GPL_RA(i)/nb_roue_GPL;
    ressource_pneu_VP(i) = Valeurs_ACV(6,7)*Nb_pneus_VP_RA(i)/nb_roue_VP;
    ressource_pneu_VUL(i) = Valeurs_ACV(6,8)*Nb_pneus_VUL_RA(i)/nb_roue_VUL;
    ressource_pneu_PPL(i) = Valeurs_ACV(6,9)*Nb_pneus_PPL_RA(i)/nb_roue_PPL;
    ressource_pneu_GPL(i) = Valeurs_ACV(6,10)*Nb_pneus_GPL_RA(i)/nb_roue_GPL;
end

//INDICATEURS de coûts

//Taux d'actualisation //Paramètre
T_act_societe=0.025;
T_act_Etat=0.01;
T_act_menages=0.01;
T_act_SCA=0.08; //A choisir par le gestionnaire? ici, valeurs Cofiroute
//calcul des coefficients d'actualisation
for i=1:DVT_chaussee,
    coef_act_societe(i)=1/(1+T_act_societe)^(i-1);
    coef_act_Etat(i)=1/(1+T_act_Etat)^(i-1);
    coef_act_menages(i)=1/(1+T_act_menages)^(i-1);
    coef_act_SCA(i)=1/(1+T_act_SCA)^(i-1);
end

//Indicateurs gestionnaire

//calcul des dépenses (courantes et constantes), TTC
inflation_IPC=0.014;//Inflation annuelle calculée avec les tendances de l'IPC depuis 1996, données INSEE
technique=find(RESURFACAGE==TYPE_RESURFACAGE);
cout_travaux=zeros(39,1);//monnaie courante
cout_travaux_2017=zeros(39,1);//monnaie constante
cout_travaux(1) = surface*cout_RESURFACAGE(technique);
cout_travaux_2017(1)=surface*cout_RESURFACAGE(technique);
for i=1:DVT_chaussee/DVS-1,
    cout_travaux(round(i*DVS)+1)=surface*cout_RESURFACAGE(technique)*(1+round(i*DVS)*inflation_IPC);
    cout_travaux_2017(round(i*DVS)+1)=surface*cout_RESURFACAGE(technique);
end

cout_travaux_act_SCA=cout_travaux.*coef_act_SCA;
IS_invest_gestionnaire=sum(cout_travaux_act_SCA(2:DVT_chaussee));

cout_travaux_act_societe=(0.8*cout_travaux_2017).*coef_act_societe;//HT
IS_invest_travaux_societe=sum(cout_travaux_act_societe(2:DVT_chaussee));

//Indicateur d'indisponibilité - nombre de jour d'indisponibilité moyen par an sur la DVT de chaussée
indisponibilite_infra=nb_jours_1resurfacage*(DVT_chaussee/DVS-1);

//Coûts aux usagers
TVA=0.2; //Paramètre
//cout pneumatiques
infl_maintenance=0.5/100*12;//taux d'inflation linéaire annuel (insee 1998-2015) //Paramètre
for i=1:DVT_chaussee,
    cout_pneus_infl_VP(i)=cout_pneus_VP_RA(i)*(1+0.5/100*12*(i-1));
    cout_pneus_infl_VUL(i)=cout_pneus_VUL_RA(i)*(1+0.5/100*12*(i-1));
    cout_pneus_infl_PPL(i)=cout_pneus_PPL_RA(i)*(1+0.5/100*12*(i-1));
    cout_pneus_infl_GPL(i)=cout_pneus_GPL_RA(i)*(1+0.5/100*12*(i-1));
    cout_pneus_infl(i)=(cout_pneus_infl_VP(i)+cout_pneus_infl_VUL(i)+cout_pneus_infl_PPL(i)+cout_pneus_infl_GPL(i))*(1+0.5/100*12*(i-1));
end

//cout en carburant utilisé en euros2017
prix_diesel_2017=1.27;//INSEE 2018 //Paramètre
prix_essence_2017=1.48;//INSEE 2018 //Paramètre
TICPE_diesel_2017=0.5307;//Paramètre
TICPE_essence_2017=0.6507;//Paramètre
prix_diesel_HT_2017=prix_diesel_2017*(1-TVA)-TICPE_diesel_2017;//INSEE 2018
prix_essence_HT_2017=prix_essence_2017*(1-TVA)-TICPE_essence_2017;//INSEE 2018
//fiscalité carbone
TICPE_convergence_2022_diesel=4.33/100;//taxes jusqu'à 2022, en euros/L
TICPE_convergence_2022_essence=2.02/100;
taxe_carbone_2023=1.78/100;
//Modèle de prix des carburants avec évolution fiscalité carbone et rattrapage TICPE diesel/essence
inflation_carburant=0.11;//inflation prix HT diesel et essence en euros courants par litre
for i=1:DVT_chaussee,
    if Annee(i)<2023,
        Prix_diesel(i)=prix_diesel_2017+((Annee(i)-2017)*inflation_carburant+TICPE_convergence_2022_diesel*(Annee(i)-2017))*(1+TVA);//Au litre, prix 2017 puis ajustement TICPE et inflation annuelle HT (+0.011 eurosHT/an), xTVA
        Prix_essence(i)=prix_essence_2017+((Annee(i)-2017)*inflation_carburant+TICPE_convergence_2022_essence*(Annee(i)-2017))*(1+TVA);//id
    else 
        Prix_diesel(i)=prix_diesel_2017+((Annee(i)-2017)*inflation_carburant+TICPE_convergence_2022_diesel*(2022-2017)+taxe_carbone_2023*(Annee(i)-2022))*(1+TVA);//Au litre
        Prix_essence(i)=prix_essence_2017+((Annee(i)-2017)*inflation_carburant+TICPE_convergence_2022_essence*(2022-2017)+taxe_carbone_2023*(Annee(i)-2022))*(1+TVA);
    end
end
//Coûts annuels
remboursement_TICPE_PL=11.42/100; //En euros par L (car facteur 100 pour l'hectolitre
for i=1:DVT_chaussee,
    cout_carburants(i)=(Prix_diesel(i)-remboursement_TICPE_PL)*V_diesel_PL(i)+Prix_diesel(i)*V_diesel_VL(i)+Prix_essence(i)*V_essence_VL(i);//TTC courant
    cout_carburants_HT_2017(i)=prix_diesel_HT_2017*(V_diesel_PL(i)+V_diesel_VL(i))+prix_essence_HT_2017*V_essence_VL(i);//HT 2017
end

//Indicateur de dépenses actualisées
for i=1:DVT_chaussee,
    cout_usagers(i)=cout_carburants(i)+cout_pneus_infl(i)+0;
    cout_usagers_2017_HT(i)=cout_carburants_HT_2017(i)+cout_pneus(i)*(1-TVA)+0;
end
cout_usagers_act=cout_usagers.*coef_act_menages;
IS_cout_usagers=sum(cout_usagers_act(1:DVT_chaussee));//TTC courant actualisé

//cout societe
cout_usagers_societe_act=cout_usagers_2017_HT.*coef_act_societe;
IS_cout_usagers_societe=sum(cout_usagers_societe_act(1:DVT_chaussee));

//Cout global
IS_cout_global=IS_cout_usagers_societe+IS_invest_travaux_societe;

//Finances publiques
//carburant
//TICPE
for i=1:DVT_chaussee,
    if Annee(i)<2023,
    TICPE_essence(i)=TICPE_essence_2017+(Annee(i)-2017)*TICPE_convergence_2022_essence;//En Euros/L, Tendances Ministère +2 cent/an
    TICPE_diesel_VL(i)=TICPE_diesel_2017+(Annee(i)-2017)*TICPE_convergence_2022_diesel;
    TICPE_diesel_PL(i)=TICPE_diesel_2017+(Annee(i)-2017)*TICPE_convergence_2022_diesel-remboursement_TICPE_PL;//Abattement forfaitaire 2017 de 11.42 euros par hectolitre
    
    else  TICPE_essence(i)=TICPE_essence_2017+(2022-2017)*TICPE_convergence_2022_essence+(Annee(i)-2022)*taxe_carbone_2023;
    TICPE_diesel_VL(i)=TICPE_diesel_2017+(2022-2017)*TICPE_convergence_2022_diesel+(Annee(i)-2022)*taxe_carbone_2023;
    TICPE_diesel_PL(i)=TICPE_diesel_2017+(2022-2017)*TICPE_convergence_2022_diesel+(Annee(i)-2022)*taxe_carbone_2023-remboursement_TICPE_PL;
    TICPE_carburant(i)=TICPE_essence(i)+TICPE_diesel_VL(i)+TICPE_diesel_PL(i);
    end
end
for i=1:DVT_chaussee,
    Recette_TICPE_carburant(i)=TICPE_essence(i)*V_essence_VL(i).*coef_act_Etat(i)+TICPE_diesel_VL(i)*V_diesel_VL(i).*coef_act_Etat(i)+TICPE_diesel_PL(i)*V_diesel_PL(i).*coef_act_Etat(i);//recettes actualisées par an, en euros courants
end

//TVA
for i=1:DVT_chaussee,
    Recette_TVA_essence(i)=Prix_essence(i).*V_essence_VL(i).*coef_act_Etat(i)*TVA;
    Recette_TVA_diesel(i)=Prix_diesel(i).*(V_diesel_PL(i)+V_diesel_VL(i)).*coef_act_Etat(i)*TVA;
end

//Taxes sur les carburants
IS_recettes_fiscales_carburant=sum(Recette_TICPE_carburant(1:DVT_chaussee))+sum(Recette_TVA_essence(1:DVT_chaussee))+sum(Recette_TVA_diesel(1:DVT_chaussee));//En euros courants actualisés

//Autres : travaux routiers=0 TVA, entretien en garage (main d'oeuvre + pièces pneus-suspension) : 20% pour les VP
cout_suspension=zeros(39,1);
for i=1:DVT_chaussee,
    Recette_TVA_suspension(i)=cout_suspension(i).*coef_act_Etat(i)*TVA;
end
for i=1:DVT_chaussee,
    Recette_TVA_pneu(i)=cout_pneus_infl_VP(i).*coef_act_Etat(i)*TVA;
end
IS_recettes_fiscales_entretien=sum(Recette_TVA_pneu(1:DVT_chaussee))+sum(cout_suspension(1:DVT_chaussee));

//Somme des recettes fiscales
IS_recettes_fiscales=IS_recettes_fiscales_carburant+IS_recettes_fiscales_entretien;

//Données Compta Nat - Input-Output

//Branches(=colonne) de la matrice "Coeff_Tech": travaux=>"génie civil"=n°77, entretien=>"Commerce et réparation d'automobiles et de motocycles" =n°79, carburant=>"Commerce de gros, à l’exception des automobiles et des motocycles"=n°80
//Matrices de Leontief
MatriceA = readxls('C:\Users\anne.de-bortoli\Dropbox\LVMT\Rédaction\Partie 3\Calculs_Etude_Cas\Donnees\Matrice_A_Leontief.xls');
Coeff_Tech=MatriceA(1).value;
Matrice_Inv_Leontief=inv(eye(138,138)-Coeff_Tech);

//Temps perdu exploitation
//Temps unitaires
tps_chgmt_pneus_1VP=120;//En minutes pour un véhicule (4 ou 10 pneus)
tps_chgmt_pneus_1VUL=150;
tps_chgmt_pneus_1PPL=150;
tps_chgmt_pneus_1GPL=480;

tps_plein_carburant_1VP=40;//En minutes pour 100L
tps_plein_carburant_1VUL=25;
tps_plein_carburant_1PPL=1.9;
tps_plein_carburant_1GPL=1.1;

//Temps perdu par an et par opération/véhicule en minutes
for i=1:DVT_chaussee,
    tps_perdu_pneus_VP(i) = tps_chgmt_pneus_1VP*Nb_pneus_VP_RA(i)/nb_roue_VP;
    tps_perdu_pneus_VUL(i) = tps_chgmt_pneus_1VUL*Nb_pneus_VUL_RA(i)/nb_roue_VUL;
    tps_perdu_pneus_PPL(i) = tps_chgmt_pneus_1PPL*Nb_pneus_PPL_RA(i)/nb_roue_PPL;
    tps_perdu_pneus_GPL(i) = tps_chgmt_pneus_1GPL*Nb_pneus_GPL_RA(i)/nb_roue_GPL;
    
    tps_perdu_carburant_VP(i) = tps_plein_carburant_1VP*V_carburant_VP(i)/100;//Divisé par 100L car les temps sont par 100L
    tps_perdu_carburant_VUL(i) = tps_plein_carburant_1VUL*V_carburant_VUL(i)/100;
    tps_perdu_carburant_PPL(i) = tps_plein_carburant_1PPL*V_carburant_PPL(i)/100;
    tps_perdu_carburant_GPL(i) = tps_plein_carburant_1GPL*V_carburant_GPL(i)/100;
end

//CALCULS INDICATEURS FINAUX

//Temps usagers
IS_tps_travaux_VL=tps_perdu_travaux_VL/24;//En nombre de jours
IS_tps_travaux_PL=0;
IS_tps_pneus_VP=sum(tps_perdu_pneus_VP(1:DVT_chaussee))/60/24;//en jours
IS_tps_pneus_VUL=sum(tps_perdu_pneus_VUL(1:DVT_chaussee))/60/24;
IS_tps_pneus_PL=(sum(tps_perdu_pneus_PPL(1:DVT_chaussee))+sum(tps_perdu_pneus_GPL(1:DVT_chaussee)))/60/24;
IS_tps_carburant_VP=sum(tps_perdu_carburant_VP(1:DVT_chaussee))/60/24;
IS_tps_carburant_VUL=sum(tps_perdu_carburant_VUL(1:DVT_chaussee))/60/24;
IS_tps_carburant_PL=(sum(tps_perdu_carburant_PPL(1:DVT_chaussee))+sum(tps_perdu_carburant_GPL(1:DVT_chaussee)))/60/24;
IS_tps_passe=IS_tps_travaux_VL+IS_tps_travaux_PL+IS_tps_pneus_VP+IS_tps_pneus_VUL+IS_tps_pneus_PL+IS_tps_carburant_VP+IS_tps_carburant_VUL++IS_tps_carburant_PL;//en jours passés

//Economie
//Coefficients de passage entre prix de base et prix d'acquisition par branche
Coeff_base_acq_travaux=8/100;//Au prix HT on enlève 8% pour trouve la production au prix de base //paramètre
//vecteur de la demande
f=zeros(138,1);//création d'un vecteur de 138 éléments égaux à 0
f_travaux=zeros(138,1);//id
f_garage=zeros(138,1);//id
f_carburant=zeros(138,1);//id
f_travaux(77,1)= sum(cout_travaux_2017(2:DVT_chaussee))*(1-(TVA+Coeff_base_acq_travaux));//Demande travaux resurfaçage HT, euros2017, génie civil 
f(77,1)=f_travaux(77,1);
f_garage(79,1)=(1-TVA)*sum(cout_pneus(1:DVT_chaussee))+sum(cout_suspension(1:DVT_chaussee))*(1-TVA);//Demande pneus + suspensions (id) = commerce & réparation de véhicules //Il manque la prise en considération de la marge => selon les tableaux de l'INSEE, elle est négative (bénéfices négatifs)???. HT, en euros constants 2017
f(79,1)=f_garage(79,1);
f_carburant(80,1)=sum(cout_carburants_HT_2017(1:DVT_chaussee));////Demande carburant en euros courants 2017 HT
f(80,1)=f_carburant(80,1);
Vecteur_production_travaux=Matrice_Inv_Leontief*f_travaux;//A multiplier par la demande HT puis sommer les termes pour obtenir la production totale engendrée
IS_production_travaux=sum(Vecteur_production_travaux);
Vecteur_production_garage=Matrice_Inv_Leontief*f_garage;
IS_production_garage=sum(Vecteur_production_garage);
Vecteur_production_carburant=Matrice_Inv_Leontief*f_carburant;
IS_production_carburant=sum(Vecteur_production_carburant);
Vecteur_production_totale=Matrice_Inv_Leontief*f;
IS_production_totale=sum(Vecteur_production_totale);

//emploi industries
//Vecteur du nombre de milliers d'emploi intérieurs totaux par branche en nombre d'équivalents temps plein (données INSEE 2015 en 88 branches éclatés linéairement en 138 branches selon la VA=>masse salariale). Base 2010???
VectETP = readxls('C:\Users\anne.de-bortoli\Dropbox\LVMT\Rédaction\Partie 3\Calculs_Etude_Cas\Donnees\ETP_138.xls');
ETP=VectETP(1).value;
ETP_138=ETP(1:138);
//Vecteur du nombre de milliers d'emploi intérieurs totaux par million d'euros de production (intérieure et extérieure)
Vectproduction = readxls('C:\Users\anne.de-bortoli\Dropbox\LVMT\Rédaction\Partie 3\Calculs_Etude_Cas\Donnees\Prod_2013.xls');
production=Vectproduction(1).value;
production_138=production(1:138);
Contenu_emploi=ETP_138./production_138*1000/1000000;//nb d'équivalent temps plein par euro de production
IS_emploi_direct_industrie_routes=sum(f_travaux(1:138))*Contenu_emploi(77);
IS_emploi_direct_garage=sum(f_garage(1:138))*Contenu_emploi(79);
IS_emploi_direct_industrie_carburant=sum(f_carburant(1:138))*Contenu_emploi(80);
for i=1:138,
    emploi_industrie_routes(i)=Vecteur_production_travaux(i)*Contenu_emploi(i);
    emploi_garage(i)=Vecteur_production_garage(i)*Contenu_emploi(i);
    emploi_industrie_carburant(i)=Vecteur_production_carburant(i)*Contenu_emploi(i);
end
IS_emploi_industrie_routes=sum(emploi_industrie_routes(1:138));
IS_emploi_garage=sum(emploi_garage(1:138));
IS_emploi_industrie_carburant=sum(emploi_industrie_carburant(1:138));

//Coefficients multiplicateurs
IS_Coefficient_multiplicateur=IS_production_totale/sum(f(1:138));
Coeff_eco_travaux=IS_production_travaux/sum(f_travaux(1:138));
Coeff_eco_garage=IS_production_garage/sum(f_garage(1:138));
Coeff_eco_carburant=IS_production_carburant/sum(f_carburant(1:138));
Coeff_emploi_travaux=IS_emploi_industrie_routes/sum(f_travaux(1:138))*1000000;
Coeff_emploi_direct_travaux=IS_emploi_direct_industrie_routes/sum(f_travaux(1:138))*1000000;
Coeff_emploi_garage=IS_emploi_garage/sum(f_garage(1:138))*1000000;
Coeff_emploi_carburant=IS_emploi_garage/sum(f_carburant(1:138))*1000000;


//Environnement
//pneus et suspensions
IS_ressources_pneus=sum(ressource_pneu_VP(1:DVT_chaussee))+sum(ressource_pneu_VUL(1:DVT_chaussee))+sum(ressource_pneu_PPL(1:DVT_chaussee))+sum(ressource_pneu_GPL(1:DVT_chaussee));
IS_ressources_suspensions=0;
IS_ressources_travaux=ressource_RESURFACAGE(2);
IS_biodiversite_pneus=sum(biodiversite_pneu_VP(1:DVT_chaussee))+sum(biodiversite_pneu_VUL(1:DVT_chaussee))+sum(biodiversite_pneu_PPL(1:DVT_chaussee))+sum(biodiversite_pneu_GPL(1:DVT_chaussee));
IS_biodiversite_suspensions=0;
IS_biodiversite_travaux=biodiversite_RESURFACAGE(2);
IS_sante_pneus=sum(sante_pneu_VP(1:DVT_chaussee))+sum(sante_pneu_VUL(1:DVT_chaussee))+sum(sante_pneu_PPL(1:DVT_chaussee))+sum(sante_pneu_GPL(1:DVT_chaussee));
IS_sante_suspensions=0;
IS_sante_travaux=sante_RESURFACAGE(2);

//Bilan environnemental - carburant - consommation et émissions
//Calculer pour chaque période à évaluer la consommation totale en diesel et essence (unité?) et les émissions (en g ou mg), entrer les valeurs dans le procédé OpenLCA créé et sortir les indicateurs Santé, biodiversite et ressource avec IW+ et ReCiPe (les stocker dans un tableur excel propre)
//Bilan environnemental - carburant - consommation et émissions
//ICV
masse_diesel=d_diesel*(sum(V_diesel_VL(1:DVT_chaussee))+sum(V_diesel_PL(1:DVT_chaussee)));
masse_essence=d_essence*sum(V_essence_VL(1:DVT_chaussee));
for j=1:26
    masse_Emission(j)=sum(Mtot_Emission(j,1:DVT_chaussee));//En g ou mg
end
//Impacts
//Emissions
for j=1:26
    sante_emission(j)= masse_Emission(j)*Valeurs_ACV(4,j+22);
    biodiversite_emission(j)= masse_Emission(j)*Valeurs_ACV(5,j+22);
    ressources_emission(j)= masse_Emission(j)*Valeurs_ACV(6,j+22);
end
IS_sante_echappement=sum(sante_emission(1:26));
IS_biodiversite_echappement=sum(biodiversite_emission(1:26));
IS_ressources_echappement=sum(ressources_emission(1:26));
//carburant
IS_sante_dispo_carburant= [masse_diesel*Valeurs_ACV(4,21) + masse_essence*Valeurs_ACV(4,22)]*1000;//Vérifier grammes ou kg... Impact de la mise à dispo du carburant
IS_biodiversite_dispo_carburant=[masse_diesel*Valeurs_ACV(5,21) + masse_essence*Valeurs_ACV(5,22)]*1000;
IS_ressources_dispo_carburant=[masse_diesel*Valeurs_ACV(6,21) + masse_essence*Valeurs_ACV(6,22)]*1000;
//Impacts environnementaux totaux : on somme les impacts de la mise à disposition du carburant et de son utilisation/sa combustion
IS_sante_carburant=IS_sante_echappement+IS_sante_dispo_carburant;
IS_biodiversite_carburant=IS_biodiversite_echappement+IS_biodiversite_dispo_carburant;
IS_ressources_carburant=IS_ressources_echappement+IS_ressources_dispo_carburant;

//Bruit
//Composante moteur
Lw_m_moteur_1PL_RA=51*ones(DVT_chaussee,1);//niveau de puissance acoustique moteur par mètre de ligne source
Lw_m_moteur_1VL_RA=43*ones(DVT_chaussee,1);
//Composante roulement
Lw_m_roulement_1PL_RA=ones(DVT_chaussee,1);
Lw_m_roulement_1VL_RA=ones(DVT_chaussee,1);
if or(TYPE_RESURFACAGE==["BBM" "BBTM" "BBUM" "ECF monocouche" "ECF bicouche"])
    then Lw_m_roulement_1PL_RA(1)=63;
         Lw_m_roulement_1VL_RA(1)=56;
         coef_increment_1PL=1.6;
         coef_increment_1VL=2.7;
         choix_fonction=0;//permet de choisir une fonction en log ou en linéaire
    elseif or(TYPE_RESURFACAGE==["BBSG" "ESU bicouche" "ESU bicouche pregravillonne"])
    then Lw_m_roulement_1PL_RA(1)=64;
         Lw_m_roulement_1VL_RA(1)=58;
         coef_increment_1PL=0.125;
         coef_increment_1VL=0.2;
         choix_fonction=1;
end
Lw_m_roulement_1PL_RA(2)=Lw_m_roulement_1PL_RA(1);
Lw_m_roulement_1VL_RA(2)=Lw_m_roulement_1VL_RA(1);
//Niveaux de puissance sonore composante roulement en vieillissement sur le 1er cycle de resurfaçage après la phase de stabilisation des 2 ans
for j = 3:DVT_chaussee,
    if j < round(DVS)+1,
    then Lw_m_roulement_1PL_RA(j) = Lw_m_roulement_1PL_RA(2)+ coef_increment_1PL*(-log((j-2+0.5)^(choix_fonction-1))+choix_fonction*(j-3+0.5)) ;//0.5 car c'est la moyenne de l'incrément à appliquer sur la 3eme année après resurfaçage (moyenne entre niveau acoustique après 2 ans et après 3 ans)
        Lw_m_roulement_1VL_RA(j) = Lw_m_roulement_1VL_RA(2)+coef_increment_1VL*(-log((j-2+0.5)^(choix_fonction-1))+choix_fonction*(j-3+0.5)) ;
    end
end
for j=10:round(DVS),
    Lw_m_roulement_1PL_RA(j) = Lw_m_roulement_1PL_RA(9)+ coef_increment_1PL*(-log((1+0.5)^(choix_fonction-1)+choix_fonction*(0.5))) ;//stabilisation du niveau sonore à surface=10 ans pour les revêtements R3
    Lw_m_roulement_1VL_RA(j) = Lw_m_roulement_1VL_RA(9)+ coef_increment_1VL*(-log((1+0.5)^(choix_fonction-1)+choix_fonction*(0.5))) ;
end
//Calcul des niveaux de puissance sonore composante roulement sur les autres cycles successifs entre 2 resurfaçages
for i=2:DVT_chaussee/DVS,
    for j=round((i-1)*DVS)+1:round(i*DVS),
        if round(i*DVS)<=DVT_chaussee,
            then Lw_m_roulement_1PL_RA(j)=Lw_m_roulement_1PL_RA(j-round((i-1)*DVS));
                 Lw_m_roulement_1VL_RA(j)=Lw_m_roulement_1VL_RA(j-round((i-1)*DVS));
        end
     end
end

//Addition des composantes moteur et roulement de la ligne de route étudiée
for i=1:DVT_chaussee,
    Lw_m_1PL_RA(i)=10*log10(10^(Lw_m_roulement_1PL_RA(i)/10)+10^(Lw_m_moteur_1PL_RA(i)/10));
    Lw_m_1VL_RA(i)=10*log10(10^(Lw_m_roulement_1VL_RA(i)/10)+10^(Lw_m_moteur_1VL_RA(i)/10));
end

//Addition des composantes moteur et roulement de la ligne de route dans le sens non étudié : considération de la moyenne acoustique à l'âge du revêtement moyen
age_moyen_surface=round(14/2);//Paramètre //donnée Cofiroute
Lw_m_1PL_RAmoy=10*log10(10^(Lw_m_roulement_1PL_RA(age_moyen_surface)/10)+10^(Lw_m_moteur_1PL_RA(age_moyen_surface)/10));
Lw_m_1VL_RAmoy=10*log10(10^(Lw_m_roulement_1VL_RA(age_moyen_surface)/10)+10^(Lw_m_moteur_1VL_RA(age_moyen_surface)/10));
//Calcul des trafics horaires
coef_Q_VL_den_jour_RA=17;
coef_Q_PL_den_jour_RA=20;
coef_Q_VL_den_soir_RA=19;
coef_Q_PL_den_soir_RA=20;
coef_Q_VL_den_nuit_RA=82;
coef_Q_PL_den_nuit_RA=39;
coef_Q_VL_jour_RA=18;
coef_Q_PL_jour_RA=20;
coef_Q_VL_nuit_RA=82;
coef_Q_PL_nuit_RA=39;
Q_VL_den_jour=TMJA.*%VL/coef_Q_VL_den_jour_RA;
Q_PL_den_jour=TMJA.*%PL/coef_Q_PL_den_jour_RA;
Q_VL_den_soir=TMJA.*%VL/coef_Q_VL_den_soir_RA;
Q_PL_den_soir=TMJA.*%PL/coef_Q_PL_den_soir_RA;
Q_VL_den_nuit=TMJA.*%VL/coef_Q_VL_den_nuit_RA;
Q_PL_den_nuit=TMJA.*%PL/coef_Q_PL_den_nuit_RA;
Q_VL_jour=TMJA.*%VL/coef_Q_VL_jour_RA;
Q_PL_jour=TMJA.*%PL/coef_Q_PL_jour_RA;
Q_VL_nuit=TMJA.*%VL/coef_Q_VL_nuit_RA;
Q_PL_nuit=TMJA.*%PL/coef_Q_PL_nuit_RA;
//Calcul de densité linéaire de chaque type de véhicule
d_VL_den_jour=Q_VL_den_jour./Vmoy_RA_VL/1000;
d_PL_den_jour=Q_PL_den_jour./Vmoy_RA_PL/1000;
d_VL_den_soir=Q_VL_den_soir./Vmoy_RA_VL/1000;
d_PL_den_soir=Q_PL_den_soir./Vmoy_RA_PL/1000;
d_VL_den_nuit=Q_VL_den_nuit./Vmoy_RA_VL/1000;
d_PL_den_nuit=Q_PL_den_nuit./Vmoy_RA_PL/1000;
d_VL_jour=Q_VL_jour./Vmoy_RA_VL/1000;
d_PL_jour=Q_PL_jour./Vmoy_RA_PL/1000;
d_VL_nuit=Q_VL_nuit./Vmoy_RA_VL/1000;
d_PL_nuit=Q_PL_nuit./Vmoy_RA_PL/1000;
//Calcul de la puissance acoustique linéique de chaque ligne source
//Ligne source non étudiée, valeurs moyennes
Lw_m_den_jour_RAmoy=10*log10(d_VL_den_jour*10^(Lw_m_1VL_RAmoy/10)+d_PL_den_jour*10^(Lw_m_1PL_RAmoy/10));
Lw_m_den_soir_RAmoy=10*log10(d_VL_den_soir*10^(Lw_m_1VL_RAmoy/10)+d_PL_den_soir*10^(Lw_m_1PL_RAmoy/10));
Lw_m_den_nuit_RAmoy=10*log10(d_VL_den_nuit*10^(Lw_m_1VL_RAmoy/10)+d_PL_den_nuit*10^(Lw_m_1PL_RAmoy/10));
Lw_m_jour_RAmoy=10*log10(d_VL_jour*10^(Lw_m_1VL_RAmoy/10)+d_PL_jour*10^(Lw_m_1PL_RAmoy/10));
Lw_m_nuit_RAmoy=10*log10(d_VL_nuit*10^(Lw_m_1VL_RAmoy/10)+d_PL_nuit*10^(Lw_m_1PL_RAmoy/10));
//Ligne source étudiée
for i=1:DVT_chaussee,
    Lw_m_den_moy_jour(i)=10*log10(d_VL_den_jour(i)*10^(Lw_m_1VL_RA(i)/10)+d_PL_den_jour(i)*10^(Lw_m_1PL_RA(i)/10));
    Lw_m_den_moy_soir(i)=10*log10(d_VL_den_soir(i)*10^(Lw_m_1VL_RA(i)/10)+d_PL_den_soir(i)*10^(Lw_m_1PL_RA(i)/10));
    Lw_m_den_moy_nuit(i)=10*log10(d_VL_den_nuit(i)*10^(Lw_m_1VL_RA(i)/10)+d_PL_den_nuit(i)*10^(Lw_m_1PL_RA(i)/10));
    Lw_m_moy_jour(i)=10*log10(d_VL_jour(i)*10^(Lw_m_1VL_RA(i)/10)+d_PL_jour(i)*10^(Lw_m_1PL_RA(i)/10));
    Lw_m_moy_nuit(i)=10*log10(d_VL_nuit(i)*10^(Lw_m_1VL_RA(i)/10)+d_PL_nuit(i)*10^(Lw_m_1PL_RA(i)/10));
end
//Somme des deux lignes sources
for i=1:DVT_chaussee,
Lw_m_den_jour_total(i)=10*log10(10^(Lw_m_den_jour_RAmoy(i)/10)+10^(Lw_m_den_moy_jour(i)/10));
Lw_m_den_soir_total(i)=10*log10(10^(Lw_m_den_soir_RAmoy(i)/10)+10^(Lw_m_den_moy_soir(i)/10));
Lw_m_den_nuit_total(i)=10*log10(10^(Lw_m_den_nuit_RAmoy(i)/10)+10^(Lw_m_den_moy_nuit(i)/10));
Lw_m_jour_total(i)=10*log10(10^(Lw_m_jour_RAmoy(i)/10)+10^(Lw_m_moy_jour(i)/10));
Lw_m_nuit_total(i)=10*log10(10^(Lw_m_nuit_RAmoy(i)/10)+10^(Lw_m_moy_nuit(i)/10));
end
//Indicateur pondéré en jour et nuit
for i=1:DVT_chaussee,
Lw_m_den=10*log10(12*10^(Lw_m_den_jour_total/10)+4*10^((Lw_m_den_soir_total+5)/10)+8*10^((Lw_m_den_nuit_total+10)/10));
end
IS_Bruit_Lw_m_den=sum(Lw_m_den(1:DVT_chaussee))/DVT_chaussee;//En dB(A))


//Impact sanitaire du bruit
//Facteurs de caractérisation de l'impact sanaitaire du bruit routier, Meyer 2017, méthode générique
FC_jour=6.61E-7;//en DALY/J(A)
FC_nuit=1.25E-5;//en DALY/J(A)
//Calcul de puissance émise à partir du niveau sonore
for i=1:DVT_chaussee,
W_m_jour(i)=10E-12*10^(Lw_m_jour_total(i)/10);
W_m_nuit(i)=10E-12*10^(Lw_m_nuit_total(i)/10);
end
W_jour=W_m_jour*longueur*1000;
W_nuit=W_m_nuit*longueur*1000;
Bruit_jour_sante=W_jour*3600*365*16*FC_jour;
Bruit_nuit_sante=W_nuit*3600*365*8*FC_nuit;
IS_sante_bruit_total=sum(Bruit_jour_sante(1:DVT_chaussee))+sum(Bruit_nuit_sante(1:DVT_chaussee));


//Renvoi les sous-indicateurs dans l'ordre de mon tableur excel
//Changer l'ordre de la fonction disp (arguments dans le bon sens)

disp_zkw3p = disp; 
function disp(varargin), disp_zkw3p(varargin($:-1:1)), endfunction;

disp(IS_cout_global,IS_cout_usagers,IS_cout_usagers_societe,IS_invest_gestionnaire,IS_invest_travaux_societe,IS_recettes_fiscales_carburant,IS_recettes_fiscales_entretien,IS_tps_travaux_VL,IS_tps_travaux_PL,IS_tps_pneus_VP,IS_tps_pneus_VUL,IS_tps_pneus_PL,IS_tps_carburant_VP,IS_tps_carburant_VUL,IS_tps_carburant_PL,IS_emploi_industrie_routes,IS_emploi_garage,IS_emploi_industrie_carburant,IS_emploi_direct_industrie_routes,IS_emploi_direct_garage,IS_emploi_direct_industrie_carburant,IS_production_travaux,IS_production_garage,IS_production_carburant,IS_ressources_carburant,IS_ressources_pneus,IS_ressources_suspensions,IS_ressources_travaux,IS_biodiversite_carburant,IS_biodiversite_pneus,IS_biodiversite_suspensions,IS_biodiversite_travaux,IS_sante_carburant,IS_sante_pneus,IS_sante_suspensions,IS_sante_travaux,IS_Bruit_Lw_m_den,IS_sante_bruit_total)

disp(Coeff_eco_travaux,Coeff_eco_garage,Coeff_eco_carburant,Coeff_emploi_travaux,Coeff_emploi_garage,Coeff_emploi_carburant)

//Création d'un vecteur avec les indicateurs et sous-indicateurs désagrégés
Indicateurs = [IS_cout_global,IS_cout_usagers,IS_cout_usagers_societe,IS_invest_gestionnaire,IS_invest_travaux_societe,IS_recettes_fiscales_carburant,IS_recettes_fiscales_entretien,IS_tps_travaux_VL,IS_tps_travaux_PL,IS_tps_pneus_VP,IS_tps_pneus_VUL,IS_tps_pneus_PL,IS_tps_carburant_VP,IS_tps_carburant_VUL,IS_tps_carburant_PL,IS_emploi_industrie_routes,IS_emploi_garage,IS_emploi_industrie_carburant,IS_emploi_direct_industrie_routes,IS_emploi_direct_garage,IS_emploi_direct_industrie_carburant,IS_production_travaux,IS_production_garage,IS_production_carburant,IS_ressources_carburant,IS_ressources_pneus,IS_ressources_suspensions,IS_ressources_travaux,IS_biodiversite_carburant,IS_biodiversite_pneus,IS_biodiversite_suspensions,IS_biodiversite_travaux,IS_sante_carburant,IS_sante_pneus,IS_sante_suspensions,IS_sante_travaux,IS_Bruit_Lw_m_den,IS_sante_bruit_total];

//Création d'un fichier CVS avec les valeurs du scenario étudié
csvWrite(Indicateurs, strcat(Noms_scenario(calcul_scenario)+TYPE_RESURFACAGE));

//Fermeture du compteur de temps de calcul 
toc()
