function [ExperimentalData, InverseKinematicResults] = InverseKinematicsLM(filename,AnalysisParameters,BiomechanicalModel)
% Computation of the inverse kinematics step thanks to a Jacobian matrix
%   
%   INPUT
%   - filename: name of the file to process (character string)
%   - AnalysisParameters: parameters of the musculoskeletal analysis, automatically generated by the graphic interface 'Analysis'
%   - BiomechanicalModel: musculoskeletal model
%   OUTPUT
%   - ExperimentalData: motion capture data(see the Documentation for the structure)
%   - InverseKinematicResults: results of the inverse kinematics step (see the Documentation for the structure)
%________________________________________________________
%
% Licence
% Toolbox distributed under 3-Clause BSD License
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________

%% Loading useful files
if ~exist(filename,'dir')
    mkdir(filename)
end
disp(['Inverse kinematics (' filename ') ...'])
Human_model = BiomechanicalModel.OsteoArticularModel;
Markers_set = BiomechanicalModel.Markers;

%% Symbolic function generation
% Markers position with respects to the joint coordinates
nbClosedLoop = sum(~cellfun('isempty',{Human_model.ClosedLoop})); %#ok<NASGU>

%% List of markers from the model
list_markers={};
for i=1:numel(Markers_set)
    if Markers_set(i).exist
        list_markers=[list_markers;Markers_set(i).name]; %#ok<AGROW>
    end
end
nb_solid=size(Human_model,2);  % Number of solids

%% Position of the real markers from the c3d file
[real_markers, nb_frame, Firstframe, Lastframe,f_mocap] = Get_real_markers(filename,list_markers,AnalysisParameters); %#ok<ASGLU>

%% Root position
Base_position=cell(nb_frame,1);
Base_rotation=cell(nb_frame,1);
for i=1:nb_frame
    Base_position{i}=zeros(3,1);
    Base_rotation{i}=eye(3,3);
end

%% Initializations

% Linear constraints for the inverse kinematics
Aeq_ik=zeros(nb_solid);  % initialization
beq_ik=zeros(nb_solid,1);
for i=1:nb_solid
   if size(Human_model(i).linear_constraint) ~= [0 0] %#ok<BDSCA>
       Aeq_ik(i,i)=-1;
       Aeq_ik(i,Human_model(i).linear_constraint(1,1))=Human_model(i).linear_constraint(2,1);
   end    
end

%% Inverse kinematics frame per frame

options1 = optimoptions(@fmincon,'Display','off','TolFun',1e-3,'MaxFunEvals',20000,'GradObj','off','GradConstr','off');

q=zeros(nb_solid,nb_frame);

addpath('Symbolic_function')

nb_cut=max([Human_model.KinematicsCut]);

Rcut=zeros(3,3,nb_cut);   % initialization of the position and the rotation of the cut coordinate frames
pcut=zeros(3,1,nb_cut);

list_function=cell(nb_cut,1);
for c=1:max([Human_model.KinematicsCut])
    list_function{c}=str2func(sprintf('f%dcut',c));
end
list_function_markers=cell(numel(list_markers),1);
for m=1:numel(list_markers)
    list_function_markers{m}=str2func(sprintf([list_markers{m} '_Position']));
end

% Joint limits
l_inf1=[Human_model.limit_inf]';
l_sup1=[Human_model.limit_sup]';

% Jacobian matrix loading
Jfq = BiomechanicalModel.Jacob.Jfq;
indexesNumericJfq = BiomechanicalModel.Jacob.indexesNumericJfq;
nonNumericJfq = BiomechanicalModel.Jacob.nonNumericJfq;
Jfcut = BiomechanicalModel.Jacob.Jfcut;
indexesNumericJfcut = BiomechanicalModel.Jacob.indexesNumericJfcut;
nonNumericJfcut = BiomechanicalModel.Jacob.nonNumericJfcut;
Jcutq = BiomechanicalModel.Jacob.Jcutq;
indexesNumericJcutq = BiomechanicalModel.Jacob.indexesNumericJcutq;
nonNumericJcutq = BiomechanicalModel.Jacob.nonNumericJcutq;
Jcutcut = BiomechanicalModel.Jacob.Jcutcut;
indexesNumericJcutcut = BiomechanicalModel.Jacob.indexesNumericJcutcut;
nonNumericJcutcut = BiomechanicalModel.Jacob.nonNumericJcutcut;

% Inverse kinematics parameters
pos_root =find([Human_model.mother]==0); %  root solid position
lambda = 5e-2; % LM


h = waitbar(0,['Inverse Kinematics (' filename ')']);
% 1st frame : classical optimization
q0=zeros(nb_solid,1);   
ik_function_objective=@(qvar)CostFunctionSymbolicIK(qvar,nb_cut,real_markers,1,list_function,list_function_markers,Rcut,pcut);
[q(:,1)] = fmincon(ik_function_objective,q0,[],[],Aeq_ik,beq_ik,l_inf1,l_sup1,[],options1);
waitbar(1/nb_frame)

for f = 2:nb_frame
    % cut evaluation
    for c=1:nb_cut
        [Rcut(:,:,c),pcut(:,:,c)]=list_function{c}(q(:,f-1),pcut,Rcut);
    end
    % dx
    for m=1:numel(list_markers)
        dX((m-1)*3+1:3*m,:) = real_markers(m).position(f,:)'-list_function_markers{m}(q(:,f-1),pcut,Rcut);
    end
    % Jfq
    Jfq(indexesNumericJfq) = nonNumericJfq(q(:,f-1),pcut,Rcut);
    % Jfcut
    Jfcut(indexesNumericJfcut) = nonNumericJfcut(q(:,f-1),pcut,Rcut);
    % Jcutq
    Jcutq(indexesNumericJcutq) = nonNumericJcutq(q(:,f-1),pcut,Rcut);
    % Jcutcut
    Jcutcut(indexesNumericJcutcut) = nonNumericJcutcut(q(:,f-1),pcut,Rcut);
    % J
    J = Jfq + Jfcut*dJcutq(Jcutcut,Jcutq);
    % dq (Levenberg�Marquardt)
    Jt = transpose(J);
    JtJ = Jt*J;
    A=(JtJ+lambda * diag(diag(JtJ)));
    B=Jt*(dX);
    dq = A\B;
    % joint coordinates computation
    q(:,f)=q(:,f-1)+[dq(1:pos_root-1,:);0;dq(pos_root:end,:)];
    waitbar(f/nb_frame)
end
close(h)

%% Data processing
if AnalysisParameters.IK.FilterActive
    % data filtering
    q=filt_data(q',AnalysisParameters.IK.FilterCutOff,f_mocap)';
end

% Error computation
KinematicsError=zeros(numel(list_markers),nb_frame);
nb_cut=max([Human_model.KinematicsCut]);
for f=1:nb_frame
    [KinematicsError(:,f)] = ErrorMarkersIK(q(:,f),nb_cut,real_markers,f,list_markers,Rcut,pcut);
end

q6dof=[q(end-4:end,:);q(1,:)]; 
q=q(1:end-6,:); 
q(1,:)=0;       

time=real_markers(1).time'; 
    
%% Save data
ExperimentalData.FirstFrame = Firstframe;
ExperimentalData.LastFrame = Lastframe;
ExperimentalData.MarkerPositions = real_markers;
ExperimentalData.Time = time;

InverseKinematicResults.JointCoordinates = q;
InverseKinematicResults.FreeJointCoordinates = q6dof;
InverseKinematicResults.ReconstructionError = KinematicsError;
    
disp(['... Inverse kinematics (' filename ') done'])

%% We delete the folder to the path
rmpath('Symbolic_function')
end
