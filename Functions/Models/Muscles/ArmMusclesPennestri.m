function [Muscles]=ArmMusclesPennestri(Muscles,Signe)
% Definition of an arm muscle model
%   This model contains 22 muscles
%
%	Based on:
%	- Pennestrì, E. , Stefanelli, R. , Valentini, P. P. , Vita, L.
%	Virtual musculo-skeletal model for the biomechanical
% analysis of the upper limb, Pennestrì2007

%   INPUT
%   - Muscles: set of muscles (see the Documentation for the structure)
%   - Signe: side of the arm model ('R' for right side or 'L' for left side)
%   OUTPUT
%   - Muscles: new set of muscles (see the Documentation for the structure)
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________


if strcmp(Signe,'Right')
    Signe = 'R';
else
    Signe = 'L';
end

s=cell(0);

s=[s;{
    [Signe 'Coracobrachialis'],63,0.200,[],[],[],{[Signe 'Scapula_Coracobrachialis_o'];[Signe 'Humerus_Coracobrachialis_i']};...
    [Signe 'Deltoid'],240,0.170,[],[],[],{[Signe 'Scapula_Deltoid_o'];[Signe 'Humerus_Deltoid_i']};...
    [Signe 'LatissumusDorsi'],260,0.135,[],[],[],{[ 'Pelvis_LatissumusDorsi_o'];[Signe 'Humerus_LatissumusDorsi_i']};...
    [Signe 'PectoralisMajor'],210,0.190,[],[],[],{['Thorax_PectoralisMajor_o'];[Signe 'Humerus_PectoralisMajor_i']};...
    [Signe 'Supraspinatus'],98,0.090,[],[],[],{[Signe 'Scapula_Supraspinatus_o'];[Signe 'Humerus_Supraspinatus_i']};...
    [Signe 'Infraspinatus'],210,0.105,[],[],[],{[Signe 'Scapula_Infraspinatus_o'];[Signe 'Humerus_Infraspinatus_i']};...
    [Signe 'CubitalisAnterior'],35,0.255,[],[],[],{[Signe 'Humerus_CubitalisAnterior_o'];[Signe 'Hand_CubitalisAnterior_i']};...
    [Signe 'FlexorCarpiUlnaris'],51,0.255,[],[],[],{[Signe 'Humerus_FlexorCarpiUlnaris_o'];[Signe 'Hand_FlexorCarpiUlnaris_i']};...
    [Signe 'ExtensorCarpiUlnaris'],42,0.210,[],[],[],{[Signe 'Humerus_ExtensorCarpiUlnaris_o'];[Signe 'Hand_ExtensorCarpiUlnaris_i']};...
    [Signe 'ExtensorDigitorum'],46,0.225,[],[],[],{[Signe 'Humerus_ExtensorDigitorum_o'];[Signe 'Hand_ExtensorDigitorum_i']};...
    [Signe 'FlexorDigitorumSuperior'],45,0.220,[],[],[],{[Signe 'Humerus_FlexorDigitorumSuperior_o'];[Signe 'Hand_FlexorDigitorumSuperior_i']};...
    [Signe 'FlexorCarpiRadialis'],72,0.235,[],[],[],{[Signe 'Humerus_FlexorCarpiRadialis_o'];[Signe 'Hand_FlexorCapriRadialis_i']};...
    [Signe 'PronatorQuadrus'],78,0.045,[],[],[],{[Signe 'Ulna_PronatorQuadrus_o'];[Signe 'Radius_PronatorQuadrus_i']};...
    [Signe 'SupinatorBrevis'],30,0.050,[],[],[],{[Signe 'Ulna_SupinatorBrevis_o'];[Signe 'Radius_SupinatorBrevis_i']};...
    [Signe 'AbductorDigitiV'],36,0.140,[],[],[],{[Signe 'Ulna_AbductorDigitiV_o'];[Signe 'Hand_AbductorDigitiV_i']};...
    % Conservation du modèle de Holzbaur
% on conserve les biceps du modèle de Holzbaur sauf qu'on part de la
    % scapula pour le biceps short et glénoïde pour le biceps long
    [Signe 'BicepsL'],624.3,0.1157,4,0.2723,0,{[Signe 'Scapula_BicepsL_o'];[Signe 'Scapula_BicepsL_via1'];[Signe 'Humerus_BicepsL_via2'];[Signe 'Humerus_BicepsL_via3'];[Signe 'Humerus_BicepsL_via4'];[Signe 'Humerus_BicepsL_via5'];[Signe 'Humerus_BicepsL_via6'];[Signe 'Humerus_Biceps_via7'];[Signe 'Ulna_Biceps_i']};... arm26.osim       
    [Signe 'BicepsS'],435.56,0.1321,4,0.1923,0,{[Signe 'Scapula_BicepsS_o'];[Signe 'Scapula_BicepsS_via1'];[Signe 'Humerus_BicepsS_via2'];[Signe 'Humerus_BicepsS_via3'];[Signe 'Humerus_Biceps_via7'];[Signe 'Ulna_Biceps_i']};... arm26.osim    
    % on conserve les biceps du modèle de Holzbaur sauf qu'on part de la
    % scapula pour le triceps long
       [Signe 'TricepsLg'],798.5,0.134,4,0.143,0.209,{[Signe 'Scapula_Triceps_o'];[Signe 'Humerus_TricepsLg_via1'];[Signe 'Humerus_Triceps_via2'];[Signe 'Humerus_Triceps_via3'];[Signe 'Humerus_Triceps_via4'];[Signe 'Ulna_Triceps_via5'];[Signe 'Ulna_Triceps_i']};...       arm26.osim    
    [Signe 'TricepsLat'],624.3,0.114,4,0.098,0.157,{[Signe 'Humerus_TricepsLat_o'];[Signe 'Humerus_TricepsLat_via1'];[Signe 'Humerus_Triceps_via2'];[Signe 'Humerus_Triceps_via3'];[Signe 'Humerus_Triceps_via4'];[Signe 'Ulna_Triceps_via5'];[Signe 'Ulna_Triceps_i']};... arm26.osim   
    [Signe 'TricepsMed'],624.3,0.114,4,0.098,0.157,{[Signe 'Humerus_TricepsMed_o'];[Signe 'Humerus_TricepsMed_via1'];[Signe 'Humerus_Triceps_via2'];[Signe 'Humerus_Triceps_via3'];[Signe 'Humerus_Triceps_via4'];[Signe 'Ulna_Triceps_via5'];[Signe 'Ulna_Triceps_i']};... arm26.osim     
     [Signe 'Brachialis'],987.3,0.0858,4,0.0535,0,{[Signe 'Humerus_Brachialis_o'];[Signe 'Radius_Brachialis']};...
        [Signe 'PronatorTeres'],566.2,[],[],[],[],{[Signe 'Humerus_PronatorTeres_o'];[Signe 'Radius_PronatorTeres_i']};...
    }];


% Structure generation
Muscles=[Muscles;struct('name',{s{:,1}}','f0',{s{:,2}}','l0',{s{:,3}}',...
    'Kt',{s{:,4}}','ls',{s{:,5}}','alpha0',{s{:,6}}','path',{s{:,7}}')]; %#ok<CCAT1>

end