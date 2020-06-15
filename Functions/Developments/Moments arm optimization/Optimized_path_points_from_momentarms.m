%% Optimisation des bras de levier

%load('/home/clivet/Documents/Thèse/Developpement_CusToM/thesis/Fichiers_tests/Donnees a traiter/Ana Lucia Data - Sbj 1 - Trial 1 - Forearm model/BiomechanicalModel.mat')
load('BiomechanicalModel.mat')
%name_mus='Brachioradialis';
%name_mus='ExtensorDigitorum';
%name_mus='FlexorDigitorumSuperior';

temp={BiomechanicalModel.Muscles.name};
for k=1:length(temp)
    temp2=temp{k};
    temp{k}=temp2(2:end);
end
all_muscles=unique(temp);

%% Stockage dans un fichier texte


all_muscles= {'ExtensorDigitorum'};
for i=1:length(all_muscles)
    
    %% Ajout des champs utiles pour l'ExtensorDigitorum
    
    
    name_mus=all_muscles{i};
    Sign={'R','L'};
    for k=1:2
        [~,num_muscle(k)]=intersect({BiomechanicalModel.Muscles.name},[Sign{k},name_mus]);
        BiomechanicalModel.Muscles(num_muscle(k)).lmax=306e-3; %ExtensorDigitorum
      %  BiomechanicalModel.Muscles(num_muscle(k)).lmax=276e-3; %Brachioradialis
    end
    
    
    
    MomentsArmRegression=MomentsArmRegression_creation();
    
    [Pts,involved_solids,num_markersprov,BiomechanicalModel]=MomentArmOptimisation(name_mus,BiomechanicalModel,MomentsArmRegression);
   
    fileID = fopen('via_points.txt','a');
    
    solid_interet=involved_solids{1};
    markers_interet=num_markersprov{1};
    
    for k=1:length(solid_interet)
        temp1=solid_interet(k);
        temp2=markers_interet(k);
        nom_pt_passage=BiomechanicalModel.OsteoArticularModel(temp1).anat_position{temp2,1};
        pt_passage=BiomechanicalModel.OsteoArticularModel(temp1).anat_position{temp2,2};
        nom_pt_passage=nom_pt_passage(2:end);
        fprintf(fileID,'[Signe ''%6s''], [%6.4f ; %6.4f ; %6.4f] ;... \n',nom_pt_passage,pt_passage);
    end
    
    fclose(fileID);
    
end