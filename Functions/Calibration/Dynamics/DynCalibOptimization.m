function [Human_model] = DynCalibOptimization(ModelParameters, AnalysisParameters, BiomechanicalModel)
% Calibration of the inertial parameters
%   Inertial parameters (mass, local position of the center of mass and
%   inertia of each solid) are subject-specific calibrated from motion
%   capture data and force platforms data
%
%   INPUT
%   - ModelParameters: parameters of the musculoskeletal model, automatically
%   generated by the graphic interface 'GenerateParameters' 
%   - AnalysisParameters: parameters of the musculoskeletal analysis
%   automatically generated by the graphic interface 'Analysis'
%   - BiomechanicalModel: musculoskeletal model
%   OUTPUT
%   - Human_model: subject-specific calibrated osteo-articular model
%   (see the Documentation for the structure)  
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________

%% Variables
Human_model = BiomechanicalModel.OsteoArticularModel;
filename = AnalysisParameters.filename{1};
load([filename(1:end-4) '/InverseKinematicsResults.mat']); %#ok<LOAD>
q = InverseKinematicsResults.JointCoordinates;
q6dof = InverseKinematicsResults.FreeJointCoordinates;
load([filename(1:end-4) '/ExperimentalData.mat']); %#ok<LOAD>
freq = 1/ExperimentalData.Time(2);
load([filename(1:end-4) '/ExternalForcesComputationResults.mat']); %#ok<LOAD>
external_forces = ExternalForcesComputationResults.ExternalForcesExperiments;
nb_frame_opti = AnalysisParameters.CalibID.Frames.NbFrames;
KinematicsError = InverseKinematicsResults.ReconstructionError;

%% Param�tres d'opti
CalibOptiParameters.DeltaR0 = 0.3; % % de variation des rayons (Radius variation)
CalibOptiParameters.DeltaR1 = 0.3;
CalibOptiParameters.DeltaM = 0.2;
alpha = 0.1; % contrainte de sym�trie / symmetry constraint

%% Initialisation des param�tres pour la dynamique inverse

q6dof=q6dof';
q=q';
% Gravit�
g=[0 0 -9.81]';
% on enl�ve la liaison 6 ddl ajout�e par la cin�matique inverse
% Get rid of the 6DOF joint: between human body and global reference frame
Human_model_dyn=Human_model(1:(numel(Human_model)-6));

% D�finition des vitesses / acc�l�rations articulaires
% Speed and acceleration for every joint
dt=1/freq;
dq=derivee2(dt,q);  % vitesses
ddq=derivee2(dt,dq);  % acc�l�rations
nbframe=size(q,1);

% D�finition des donn�es cin�matiques du pelvis
% (position / vitesse / acc�l�ration / orientation / vitesse angulaire / acc�l�ration angulaire)
% Kinematical data for Pelvis (Position/speed/acceleration/angles/angular speed/angular acceleration)
p_pelvis=q6dof(:,1:3);  % frame i : p_pelvis(i,:)
r_pelvis=cell(size(q6dof,1),1);
for i=1:size(q6dof,1)
    r_pelvis{i}=Rodrigues([1 0 0]',q6dof(i,4))*Rodrigues([0 1 0]',q6dof(i,5))*Rodrigues([0 0 1]',q6dof(i,6)); % matrice de rotation en fonction des rotations successives (x,y,z) : frame i : r_pelvis{i}
end

%dR
dR=zeros(3,3,nbframe);
for ligne=1:3
    for colonne=1:3
        dR(ligne,colonne,:)=derivee2(dt,cell2mat(cellfun(@(b) b(ligne,colonne),r_pelvis,'UniformOutput',false)));
        dR(ligne,colonne,:)=derivee2(dt,cell2mat(cellfun(@(b) b(ligne,colonne),r_pelvis,'UniformOutput',false)));
        dR(ligne,colonne,:)=derivee2(dt,cell2mat(cellfun(@(b) b(ligne,colonne),r_pelvis,'UniformOutput',false)));
    end
end
w=zeros(nbframe,3);
for i=1:nbframe
   wmat=dR(:,:,i)*r_pelvis{i}';
   w(i,:)=[wmat(3,2),wmat(1,3),wmat(2,1)];
end

% v0
v=derivee2(dt,p_pelvis);
vw=zeros(nbframe,3);
for i=1:nbframe
    vw(i,:)=cross(p_pelvis(i,:),w(i,:));
end
v0=v+vw;
% dv0
dv0=derivee2(dt,v0);
% dw
dw=derivee2(dt,w);

%% Initialisation des param�tres d'optimisation 
%% Definition of optimization parameters
% list_symmetry = [19 25; 20 26; 22 28; 31 38; 33 40; 35 42];
%list_symmetry = [19 25; 20 26; 22 28; 31 38; 35 42];
list_symmetry = AnalysisParameters.CalibID.Symmetry;

X0 = [];
for i=1:numel(Human_model_dyn)
    if numel(Human_model_dyn(i).L) ~= 0 % Pour les solides poss�dant le champ "L"
        X0=[X0;Human_model_dyn(i).ParamAnthropo.r0;Human_model_dyn(i).ParamAnthropo.r1;Human_model_dyn(i).ParamAnthropo.t0;Human_model_dyn(i).ParamAnthropo.t1]; %#ok<AGROW>
    end
end

% initialisation des limites
% setting of boundaries
lb=zeros(size(X0));
ub=Inf(size(X0));

% Contraintes suppl�mentaires
% Other constraints
i=1;
while i<=numel(X0)
    lb(i)=(1-CalibOptiParameters.DeltaR0)*X0(i);
    i=i+1;
    lb(i)=(1-CalibOptiParameters.DeltaR1)*X0(i);
    i=i+1;
    lb(i)=0;
    i=i+1;
    lb(i)=0;
    i=i+1;
end

i=1;
while i<=numel(X0)
    ub(i)=(CalibOptiParameters.DeltaR0+1)*X0(i);
    i=i+1;
    ub(i)=(CalibOptiParameters.DeltaR1+1)*X0(i);
    i=i+1;
    ub(i)=Inf;
    i=i+1;
    ub(i)=Inf;
    i=i+1;
end

% lb(5:5:num_solid_opti)=900/100000;
% ub=0.5*ones(size(X0));
% ub(5:5:num_solid_opti)=1100/100000;

%% Conditions suppl�mentaires A.x=b

% % Initialisation
% A=zeros(numel(X0),numel(X0));
% b=zeros(numel(X0),1);
% % on utilise des tronc de c�nes
% Truncated cones are used
% if CalibOptiParameters.TroncCone
%     for i=1:num_solid_opti
%         A((i-1)*5+3,(i-1)*5+3)=1; % t0
%         A((i-1)*5+4,(i-1)*5+4)=1; % t1
%     end
% end
% 
% % On bloque la g�om�trie des mains, des pieds et de la t�te (pas d'enfant)
% % Geometry of hands, feet and head are fixed
% if CalibOptiParameters.FixExtremLimbs
%     i=0;
%     for j=1:numel(Human_model_dyn)
%         if numel(Human_model_dyn(j).L) ~= 0 % Pour les solides poss�dant le champ "L"
%             i=i+1;
%             if ~Human_model_dyn(j).child
%                 A((i-1)*5+1,(i-1)*5+1)=1; % r0
%                 A((i-1)*5+2,(i-1)*5+2)=1; % r1
%                 A((i-1)*5+3,(i-1)*5+3)=1; % t0
%                 A((i-1)*5+4,(i-1)*5+4)=1; % t1
% 
%                 b((i-1)*5+1,1)=X0((i-1)*5+1,1); % r0
%                 b((i-1)*5+2,1)=X0((i-1)*5+2,1); % r1
%                 b((i-1)*5+3,1)=X0((i-1)*5+3,1); % t0
%                 b((i-1)*5+4,1)=X0((i-1)*5+4,1); % t1
% 
%             end
%         end
%     end
% end

H=ModelParameters.Size;
BW=sum([Human_model_dyn.m]);

%% Identification Solide sym�trie
%% Identifying of symmetrical solids
solid=[];
for i=1 : numel(Human_model)
    if numel(Human_model(i).L) ~= 0
        solid=[solid;i];
    end
end

%% Conditions suppl�mentaires Aeq.x<=beq
%% Supplemental constraints
beq=zeros(numel(X0)/2 + 8*size(list_symmetry,1),1);
Aeq=zeros(numel(X0)/2 + 8*size(list_symmetry,1),numel(X0));

% for i=(numel(X0)/2)+1 : (numel(X0)/2 + 8*size(list_symmetry,1))
%     beq(i,1)=alpha*X0(i);
% end

k=1;
while k <= numel(X0)/2
    Aeq(k,(k-1)*2+1)=-1;
    Aeq(k,(k-1)*2+3)=1;
    k=k+1;
    Aeq(k,(k-2)*2+2)=-1;
    Aeq(k,(k-2)*2+4)=1;
    k=k+1;
end

l=numel(X0)/2 +1;
for i=1 : size(list_symmetry,1)
    pos_k1=find(list_symmetry(i,1)==solid,1);
    pos_k2=find(list_symmetry(i,2)==solid,1);
    
    %Contrainte sur t_0
    Aeq(l,(4*(pos_k1-1)+3))=1;
    Aeq(l,(4*(pos_k2-1)+3))=-1;
    beq(l,1)=alpha*X0(4*(pos_k2-1)+1);
    l=l+1;
    Aeq(l,(4*(pos_k1-1)+3))=-1;
    Aeq(l,(4*(pos_k2-1)+3))=1;
    beq(l,1)=alpha*X0(4*(pos_k2-1)+1);
    l=l+1;
    
    %Contraine sur t_1
    Aeq(l,(4*(pos_k1-1)+4))=1;
    Aeq(l,(4*(pos_k2-1)+4))=-1;
    beq(l,1)=alpha*X0(4*(pos_k2-1)+2);
    l=l+1;
    Aeq(l,(4*(pos_k1-1)+4))=-1;
    Aeq(l,(4*(pos_k2-1)+4))=1;
    beq(l,1)=alpha*X0(4*(pos_k2-1)+2);
    l=l+1;
    
    %Contrainte sur r_0
    Aeq(l,(4*(pos_k1-1)+1))=1;
    Aeq(l,(4*(pos_k2-1)+1))=-1;
    beq(l,1)=alpha*X0(4*(pos_k2-1)+1);
    l=l+1;
    Aeq(l,(4*(pos_k1-1)+1))=-1;
    Aeq(l,(4*(pos_k2-1)+1))=1;
    beq(l,1)=alpha*X0(4*(pos_k2-1)+1);
    l=l+1;
    
    %Contrainte sur r_1
    Aeq(l,(4*(pos_k1-1)+2))=1;
    Aeq(l,(4*(pos_k2-1)+2))=-1;
    beq(l,1)=alpha*X0(4*(pos_k2-1)+2);
    l=l+1;
    Aeq(l,(4*(pos_k1-1)+2))=-1;
    Aeq(l,(4*(pos_k2-1)+2))=1;
    beq(l,1)=alpha*X0(4*(pos_k2-1)+2);
    l=l+1;
    
end

%% Optimisation

% num�ro des frames que l'on utilise 
% Number of frames used for calibration procedure
        frame_opti = FindFrameDynCalibration(KinematicsError,nb_frame_opti);

% optimization
% options = optimoptions(@fmincon,'Algorithm','sqp','Display','off','GradObj','off','PlotFcns',@optimplotfval,'GradConstr','off','TolFun',1e-2,'TolX',1e-4);
options = optimoptions(@fmincon,'Algorithm','sqp','Display','off','GradObj','off','GradConstr','off','TolFun',1e-2,'TolX',1e-4);
%[X,fval,exitflag,output] = fmincon(@(X) DynCalibOptimization_costfunction(X,Human_model_dyn,frame_opti,q,dq,ddq,p_pelvis,r_pelvis,v0,w,dv0,dw,BW,H,external_forces,g,nbframe),X0,[],[],A,b,lb,ub,@(X) nonlcon_DynCalib(X,X0,Human_model_dyn,CalibOptiParameters,list_symmetry),options)
[X] = fmincon(@(X) DynCalibOptimization_costfunction1(X,Human_model_dyn,frame_opti,q,dq,ddq,p_pelvis,r_pelvis,v0,w,dv0,dw,BW,H,external_forces,g,nbframe),X0,Aeq,beq,[],[],lb,ub,@(X) nonlcon_DynCalib1(X,X0,Human_model_dyn,CalibOptiParameters,list_symmetry),options);

% Actualisation du mod�le
% Model update
num_i=0;
for i=1:numel(Human_model)
    if numel(Human_model(i).L) ~= 0 % Pour les solides poss�dant le champ "L"
        num_i=num_i+1;
        [Masse,Zc,Ix,Iy,Iz]=DynParametersComputation(1000,X(4*(num_i-1)+1),X(4*(num_i-1)+3),X(4*(num_i-1)+2),X(4*(num_i-1)+4),Human_model_dyn(i).ParamAnthropo.h);
        % Masse
        Human_model(i).m=Masse;
        % Centre de masse
        if Human_model(i).ParamAnthropo.Typ == 1
        	DeltaZc = (Zc - Human_model(i).ParamAnthropo.Zc);
        else
        	DeltaZc = -(Zc - Human_model(i).ParamAnthropo.Zc);
        end
        Cy=Human_model(i).c(2) + DeltaZc;
        Human_model(i).c(2) = Cy;
        % Inertie
        Human_model(i).I = [Ix 0 0; 0 Iy 0; 0 0 Iz]; 
        % anat_position (d�fini par rapport au centre de masse / wrt center of mass)
        for m=1:size(Human_model(i).anat_position)
            Human_model(i).anat_position{m, 2} = Human_model(i).anat_position{m, 2} - [0 DeltaZc 0]';
        end
    end
end

Human_model = rmfield(Human_model, 'ParamAnthropo');

end