function [filename,DataXSens,q,q6dof,Markers_set,Muscles,real_markers,PelvisPosition,PelvisOrientation,EnableModel,Human_model,AnalysisParameters,InverseKinematicsResults,ExperimentalData,BiomechanicalModel]=DataExtractionForAnimation(AnimateParameters,ModelParameters)
% Extraction of useful data for animation
%
%   INPUT
%   - AnimateParameters : parameters of the animation, automatically
%   generated by the graphic interface 'GenerateAnimate'
%
%   OUTPUT
%   - filename : nameof the used file
%   - DataXSens : binary number to know if we are using XSens Data
%   - q :  current coordinates of the model
%   - q6dof : current coordinates of the 6 dof joint
%   - Markers_set : markers set (see the Documentation for the structure);
%   - Muscles: muscles set (see the Documentation for the structure);
%   - real_markers : Position of markers in experimental data
%   - PelvisPosition : Position of the pelvis
%   - PelvisOrientation : Orientation of the pelvis
%    - EnableModel: for each body part, this variable evaluates the
%   possibility to add the associated model (used for the graphic
%   interface 'GenerateParameters').
%   - Human_model : osteo-articular model (see the Documentation for the structure)
%   - AnalysisParameters : parameters of the analysis
%   - InverseKinematicsResults :  results of inverse kinematics
%   - ExperimentalData : experimental data
%   - BiomechanicalModel : complete model (see the Documentation for the structure)
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________



DataXSens = 0;
PelvisPosition=[];
PelvisOrientation=[];
Markers_set=[];
Muscles=[];
real_markers=[];
q6dof=[];
EnableModel=[];
AnalysisParameters=[];
InverseKinematicsResults=[];
ExperimentalData=[];
BiomechanicalModel=[];
filename=[];

if (isfield(AnimateParameters,'Mode') && isequal(AnimateParameters.Mode, 'GenerateParameters'))
    [Human_model, Markers_set, Muscles, EnableModel] = ModelGeneration(ModelParameters);
    [Human_model] = Add6dof(Human_model);
    [Markers_set]=VerifMarkersOnModel(Human_model,Markers_set);
    q6dof = [0 0 0 0 -110*pi/180 0]'; % rotation for visual
    q = zeros(numel(Human_model)-6,1);
else
    if ( isfield(AnimateParameters,'Noc3d') &&  AnimateParameters.Noc3d )
        load('AnalysisParameters.mat'); %#ok<LOAD>
        num_ext = numel(AnalysisParameters.General.Extension)-1;
        load('BiomechanicalModel.mat'); %#ok<LOAD>
        Human_model = BiomechanicalModel.OsteoArticularModel;
        if isempty(intersect({BiomechanicalModel.OsteoArticularModel.name},'root0'))  
                [Human_model] = Add6dof(Human_model);
        end
        Markers_set = BiomechanicalModel.Markers;
        Muscles = BiomechanicalModel.Muscles;
       q6dof = [0 0 0 pi -pi/2 pi/2]'; % rotation for visual
        q = zeros(numel(Human_model)-6,1);       
        if isfield(AnimateParameters,'sol_anim')
            q(AnimateParameters.sol_anim)=AnimateParameters.angle*pi/180;
        end
    else
        load('AnalysisParameters.mat'); %#ok<LOAD>
        num_ext = numel(AnalysisParameters.General.Extension)-1;
        % Filename
        filename = AnimateParameters.filename(1:end-num_ext);
        % Files loading
        load('BiomechanicalModel.mat'); %#ok<LOAD>
        Human_model = BiomechanicalModel.OsteoArticularModel;
        load([filename '/InverseKinematicsResults.mat']); %#ok<LOAD>
        q = InverseKinematicsResults.JointCoordinates;
        load([filename '/ExperimentalData.mat']); %#ok<LOAD>
        if isfield(InverseKinematicsResults,'FreeJointCoordinates')
            q6dof = InverseKinematicsResults.FreeJointCoordinates;
            Markers_set = BiomechanicalModel.Markers;
            Muscles = BiomechanicalModel.Muscles;
            real_markers = ExperimentalData.MarkerPositions;
        else
            DataXSens = 1;
            PelvisPosition = InverseKinematicsResults.PelvisPosition;
            PelvisOrientation = InverseKinematicsResults.PelvisOrientation;
        end
    end
end

% exclude non used markers
if ~DataXSens
    Markers_set=Markers_set(find([Markers_set.exist])); %#ok<FNDSB>
end

end