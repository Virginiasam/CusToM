function [OsteoArticularModel] = MVNXModelGeneration(ModelParameters, AnalysisParameters)
% Generation of the osteo-articular model from a MVNX file
%
%   INPUT
%   - ModelParameters: parameters of the musculoskeletal model,
%   automatically generated by the graphic interface 'GenerateParameters';
%   - AnalysisParameters: parameters of the musculoskeletal analysis,
%   automatically generated by the graphic interface 'Analysis'.
%   OUTPUT
%   The osteo-articular model is automatically saved in the variable
%   'BiomechanicalModel'.
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________

%% Mvnx loading    
tree = load_mvnx(AnalysisParameters.filename{1});

%% Model generation

standard_pose = 'npose';

Connectors = cellfun(@(c) strsplit(c,'/'),{tree.subject.joints.joint.connector1}, 'UniformOutput', 0);
% Initialization
OsteoArticularModel=[];
% Trunk
[OsteoArticularModel] = XSens_Pelvis(OsteoArticularModel, tree, ModelParameters.Mass, [], standard_pose);
[OsteoArticularModel] = XSens_L5(OsteoArticularModel, tree, ModelParameters.Mass, [Connectors{1}{1} '_' Connectors{1}{2}], standard_pose);
[OsteoArticularModel] = XSens_L3(OsteoArticularModel, tree, ModelParameters.Mass, [Connectors{2}{1} '_' Connectors{2}{2}], standard_pose);
[OsteoArticularModel] = XSens_T12(OsteoArticularModel, tree, ModelParameters.Mass, [Connectors{3}{1} '_' Connectors{3}{2}], standard_pose);
[OsteoArticularModel] = XSens_T8(OsteoArticularModel, tree, ModelParameters.Mass, [Connectors{4}{1} '_' Connectors{4}{2}], standard_pose);
[OsteoArticularModel] = XSens_Neck(OsteoArticularModel, tree, ModelParameters.Mass, [Connectors{5}{1} '_' Connectors{5}{2}], standard_pose);
[OsteoArticularModel] = XSens_Head(OsteoArticularModel, tree, ModelParameters.Mass, [Connectors{6}{1} '_' Connectors{6}{2}], standard_pose);
% Right arm
[OsteoArticularModel] = XSens_Shoulder(OsteoArticularModel, tree, 'R', ModelParameters.Mass, [Connectors{7}{1} '_' Connectors{7}{2}], standard_pose);
[OsteoArticularModel] = XSens_UpperArm(OsteoArticularModel, tree, 'R', ModelParameters.Mass, [Connectors{8}{1} '_' Connectors{8}{2}], standard_pose);
[OsteoArticularModel] = XSens_ForeArm(OsteoArticularModel, tree, 'R', ModelParameters.Mass, [Connectors{9}{1} '_' Connectors{9}{2}], standard_pose);
[OsteoArticularModel] = XSens_Hand(OsteoArticularModel, tree, 'R', ModelParameters.Mass, [Connectors{10}{1} '_' Connectors{10}{2}], standard_pose);
% Left arm
[OsteoArticularModel] = XSens_Shoulder(OsteoArticularModel, tree, 'L', ModelParameters.Mass, [Connectors{11}{1} '_' Connectors{11}{2}], standard_pose);
[OsteoArticularModel] = XSens_UpperArm(OsteoArticularModel, tree, 'L', ModelParameters.Mass, [Connectors{12}{1} '_' Connectors{12}{2}], standard_pose);
[OsteoArticularModel] = XSens_ForeArm(OsteoArticularModel, tree, 'L', ModelParameters.Mass, [Connectors{13}{1} '_' Connectors{13}{2}], standard_pose);
[OsteoArticularModel] = XSens_Hand(OsteoArticularModel, tree, 'L', ModelParameters.Mass, [Connectors{14}{1} '_' Connectors{14}{2}], standard_pose);
% Right Leg
[OsteoArticularModel] = XSens_UpperLeg(OsteoArticularModel, tree, 'R', ModelParameters.Mass, [Connectors{15}{1} '_' Connectors{15}{2}], standard_pose);
[OsteoArticularModel] = XSens_LowerLeg(OsteoArticularModel, tree, 'R', ModelParameters.Mass, [Connectors{16}{1} '_' Connectors{16}{2}], standard_pose);
[OsteoArticularModel] = XSens_Foot(OsteoArticularModel, tree, 'R', ModelParameters.Mass, [Connectors{17}{1} '_' Connectors{17}{2}], standard_pose);
[OsteoArticularModel] = XSens_Toe(OsteoArticularModel, tree, 'R', ModelParameters.Mass, [Connectors{18}{1} '_' Connectors{18}{2}], standard_pose);
% Left Leg
[OsteoArticularModel] = XSens_UpperLeg(OsteoArticularModel, tree, 'L', ModelParameters.Mass, [Connectors{19}{1} '_' Connectors{19}{2}], standard_pose);
[OsteoArticularModel] = XSens_LowerLeg(OsteoArticularModel, tree, 'L', ModelParameters.Mass, [Connectors{20}{1} '_' Connectors{20}{2}], standard_pose);
[OsteoArticularModel] = XSens_Foot(OsteoArticularModel, tree, 'L', ModelParameters.Mass, [Connectors{21}{1} '_' Connectors{21}{2}], standard_pose);
[OsteoArticularModel] = XSens_Toe(OsteoArticularModel, tree, 'L', ModelParameters.Mass, [Connectors{22}{1} '_' Connectors{22}{2}], standard_pose);

BiomechanicalModel.OsteoArticularModel = OsteoArticularModel;

if ~nargout
    save('BiomechanicalModel','BiomechanicalModel');
end

%% Visual pre-generation
XSens_Visual(OsteoArticularModel, tree);

end






