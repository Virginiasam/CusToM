function [ExternalForcesComputationResults] = DataInC3D(filename, BiomechanicalModel, AnalysisParameters)
% Computation of the external forces
%   From a c3d file, external forces are extracted, filtered and shaped
%   into an adapted structure
%
%   INPUT
%   - filename: name of the c3d file to process (character string)
%   - BiomechanicalModel: musculoskeletal model
%   - AnalysisParameters: parameters of the musculoskeletal analysis,
%   automatically generated by the graphic interface 'Analysis' 
%   OUTPUT
%   - ExternalForcesComputationResults: results of the external forces
%   computation (see the Documentation for the structure)
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________  

Human_model = BiomechanicalModel.OsteoArticularModel;
load([filename '/ExperimentalData.mat']); %#ok<LOAD>
time = ExperimentalData.Time;
% Firstframe = ExperimentalData.FirstFrame;
% Lastframe = ExperimentalData.LastFrame;

nbframe=numel(time);
f_mocap=1/time(2);

% Initialisation
for f=1:nbframe
    for n=1:numel(Human_model)
        external_forces(f).fext(n).fext=zeros(3,2); %#ok<AGROW,*SAGROW>
    end
end

% Ajout des plate-forme
h = btkReadAcquisition([filename '.c3d']);
[Forceplates, ForceplatesInfo] = btkGetForcePlatforms(h);

% Pour chaque plateforme : resample pour troncature
% for each platform change of sampling frequency
for i=1:numel(Forceplates)
    for j=1:6
        FieldsName = fieldnames(Forceplates(i).channels);
        Data(i).FullData(:,j)=resample(eval(['Forceplates(i).channels.' FieldsName{j}]),f_mocap,ForceplatesInfo(i).frequency);
        Data(i).RawData(:,j) = Data(i).FullData(:,j);
    end
end
% Changement d'unit� pour les couples : Nmm --> Nm
for i=1:numel(Data)
    Data(i).RawData(:,4:6) = Data(i).RawData(:,4:6)/1000;
end

% Filtrage
if AnalysisParameters.ExternalForces.FilterActive
    for i=1:numel(Data)
        Data(i).Data = filt_data(Data(i).RawData,AnalysisParameters.ExternalForces.FilterCutOff,f_mocap);
    end
else
    for i=1:numel(Data)
        Data(i).Data = Data(i).RawData;
    end
end

% Ajout des efforts de la plateforme dans la variable external_forces
% Platform forces are added in variable external_forces
for i=1:numel(Forceplates)
    if ~strcmp(AnalysisParameters.ExternalForces.Options{i},'NoContact')
        Origin = mean(Forceplates(i).corners,2)/1000;
        x = ((Forceplates(i).corners(:,4) + Forceplates(i).corners(:,1))/2) - ((Forceplates(i).corners(:,2) + Forceplates(i).corners(:,3))/2); x=x/norm(x);
        y = ((Forceplates(i).corners(:,1) + Forceplates(i).corners(:,2))/2) - ((Forceplates(i).corners(:,3) + Forceplates(i).corners(:,4))/2); y=y/norm(y);
        z = cross(x,y); z = z/norm(z);
        y = cross(z,x);
        Solid_name = AnalysisParameters.ExternalForces.Options{i}; % nom du solide li� � la plateforme
        Rplatform = [x y z]'; 
        Solid=find(strcmp({Human_model.name},Solid_name));
        [external_forces] = addPlatformForces_WithoutCoP(external_forces, Solid, Origin, Rplatform, Data(i).Data);  % enrichissement de la variable "external_forces"
    end
end

% Sauvegarde des donn�es (data saving)
if exist([filename '/ExternalForcesComputationResults.mat'],'file')
    load([filename '/ExternalForcesComputationResults.mat']);
end
ExternalForcesComputationResults.ExternalForcesExperiments = external_forces;


end