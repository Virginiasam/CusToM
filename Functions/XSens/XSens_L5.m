function [OsteoArticularJoint]= XSens_L5(OsteoArticularJoint,tree,Mass,AttachmentPoint,pose)
% Addition of a L5 model
%
%   INPUT
%   - OsteoArticularModel: osteo-articular model of an already existing
%   model (see the Documentation for the structure)
%   - tree: data extracted from a MVNX file
%   - Mass: mass of the solids
%   - AttachmentPoint: name of the attachment point of the model on the
%   already existing model (character string)
%   - name of the pose use to generate the osteo-articular model
%   OUTPUT
%   - OsteoArticularModel: new osteo-articular model (see the Documentation
%   for the structure) 
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________

points = tree.subject.segments.segment;

list_solid={'L5_J1' 'L5_J2' 'L5'};

%% Solids number incrementation

s=size(OsteoArticularJoint,2)+1;  %#ok<NASGU> % number of the 1st solid
for i=1:size(list_solid,2)      % numerotation of each solid
    if i==1
        eval(strcat('s_',list_solid{i},'=s;'))
    else
        eval(strcat('s_',list_solid{i},'=s_',list_solid{i-1},'+1;'))
    end
end

% find the number of the mother from the attachment point name
if ~numel(AttachmentPoint)
    s_mother=0;
    pos_attachment_pt=[0 0 0]';
else
    test=0;
    for i=1:numel(OsteoArticularJoint)
        for j=1:size(OsteoArticularJoint(i).anat_position,1)
            if strcmp(AttachmentPoint,OsteoArticularJoint(i).anat_position{j,1})
               s_mother=i;
               pos_attachment_pt=OsteoArticularJoint(i).anat_position{j,2}+OsteoArticularJoint(s_mother).c;
               test=1;
               break
            end
        end
        if i==numel(OsteoArticularJoint) && test==0
            error([AttachmentPoint ' is no existent'])        
        end       
    end
    if OsteoArticularJoint(s_mother).child == 0      % if the mother has no child
        OsteoArticularJoint(s_mother).child = eval(['s_' list_solid{1}]);    % the child of this mother is this solid
    else
        [OsteoArticularJoint]=sister_actualize(OsteoArticularJoint,OsteoArticularJoint(s_mother).child,eval(['s_' list_solid{1}]));
    end
end

%% Segment orientation

[~,p] = intersect({points.label},list_solid{end});
[~,num_npose] = intersect({tree.subject.frames.frame.type},pose);
quat = tree.subject.frames.frame(num_npose).orientation(1,(p-1)*4+1:p*4);
rotm = quat2rotm(quat);

%% Definition of the anatomical positions 

[~,~,num_solid]=intersect('L5',{points.label});
anatomicalpoints = points(num_solid).points.point;
L5_position_set = cell(numel(anatomicalpoints),2);
FieldNames = fieldnames(anatomicalpoints);
Pos_points = eval(['{anatomicalpoints.' FieldNames{2} '};']);
for i = 1:numel(anatomicalpoints)
    L5_position_set(i,:) = {['L5_' anatomicalpoints(i).label], rotm' * Pos_points{i}'};
end

%% Inertial parameters

% Actualized during the generation of L3
Mass_L5 = 0;
[I_L5] = zeros(6,1); 
c = zeros(3,1);

%% Osteo-articular model generation

num_solid=0;
%% L5
    % L5_J1
    num_solid=num_solid+1;        % solid number
    name=list_solid{num_solid}; % solid name
    eval(['incr_solid=s_' name ';'])  % solid number in the model
    OsteoArticularJoint(incr_solid).name=name;   
    OsteoArticularJoint(incr_solid).sister=0;                
    OsteoArticularJoint(incr_solid).child=s_L5_J2;                   
    OsteoArticularJoint(incr_solid).mother=s_mother;           
    OsteoArticularJoint(incr_solid).a=[0 1 0]';
    OsteoArticularJoint(incr_solid).joint=1;
    OsteoArticularJoint(incr_solid).ActiveJoint=1;
    OsteoArticularJoint(incr_solid).m=0;                 
    OsteoArticularJoint(incr_solid).b=pos_attachment_pt;  
    OsteoArticularJoint(incr_solid).I=zeros(3,3);
    OsteoArticularJoint(incr_solid).c=[0 0 0]';
    OsteoArticularJoint(incr_solid).Visual=0;
    
    % L5_J2
    num_solid=num_solid+1;        % solid number
    name=list_solid{num_solid}; % solid name
    eval(['incr_solid=s_' name ';'])  % solid number in the model
    OsteoArticularJoint(incr_solid).name=name;   
    OsteoArticularJoint(incr_solid).sister=0;                
    OsteoArticularJoint(incr_solid).child=s_L5;                   
    OsteoArticularJoint(incr_solid).mother=s_L5_J1;           
    OsteoArticularJoint(incr_solid).a=[1 0 0]';
    OsteoArticularJoint(incr_solid).joint=1;
    OsteoArticularJoint(incr_solid).ActiveJoint=1;
    OsteoArticularJoint(incr_solid).m=0;                 
    OsteoArticularJoint(incr_solid).b=[0 0 0]';  
    OsteoArticularJoint(incr_solid).I=zeros(3,3);
    OsteoArticularJoint(incr_solid).c=[0 0 0]';
    OsteoArticularJoint(incr_solid).Visual=0;
    
    % L5
    num_solid=num_solid+1;        % solid number
    name=list_solid{num_solid}; % solid name
    eval(['incr_solid=s_' name ';'])  % solid number in the model
    OsteoArticularJoint(incr_solid).name=name;
    OsteoArticularJoint(incr_solid).sister=0;    
    OsteoArticularJoint(incr_solid).child=0;
    OsteoArticularJoint(incr_solid).mother=s_L5_J2;
    OsteoArticularJoint(incr_solid).a=[0 0 1]';
    OsteoArticularJoint(incr_solid).joint=1;
    OsteoArticularJoint(incr_solid).ActiveJoint=1;
    OsteoArticularJoint(incr_solid).m=Mass_L5;
    OsteoArticularJoint(incr_solid).b=[0 0 0]';
    OsteoArticularJoint(incr_solid).I=[I_L5(1) I_L5(4) I_L5(5); I_L5(4) I_L5(2) I_L5(6); I_L5(5) I_L5(6) I_L5(3)];
    OsteoArticularJoint(incr_solid).c= c;
    OsteoArticularJoint(incr_solid).anat_position=L5_position_set;
    OsteoArticularJoint(incr_solid).Visual=1;
    
end