function [Human_model]=BoneView(DataXSens,Human_model,BiomechanicalModel,ModelParameters,Segment)




if ~DataXSens
% scaling factors.
if isfield(BiomechanicalModel,'GeometricalCalibration') && isfield(BiomechanicalModel.GeometricalCalibration,'k_calib') && ~isfield(BiomechanicalModel.GeometricalCalibration,'k_markers')
    k_calib = BiomechanicalModel.GeometricalCalibration.k_calib;
    k = (ModelParameters.Size/1.80)*k_calib;
else
    k = repmat((ModelParameters.Size/1.80),[numel(Human_model),1]);
end
bonespath=which('ModelGeneration.m');
bonespath = fullfile(fileparts(bonespath),'Visual');
for ii=intersect(find([Human_model.Visual]),Segment)
    if isfield(Human_model,'visual_file')
        if numel(Human_model(ii).visual_file) % a visual could be associated to this solid
            if exist(fullfile(bonespath,Human_model(ii).visual_file),'file') % this visual exists
                load(fullfile(bonespath,Human_model(ii).visual_file)); %#ok<LOAD>
                nb_faces=4500;
                if length(t)>nb_faces
                    bone.faces=t;
                    bone.vertices=p;
                    
                    bone_red=reducepatch(bone,nb_faces);
                    Human_model(ii).V=1.2063*k(ii)*bone_red.vertices;
                    Human_model(ii).F=bone_red.faces;
                else
                    Human_model(ii).V=k(ii)*p;
                    Human_model(ii).F=t;
                end
            end
        end
    end
    %             if isfield(Human_model,'Geometry') && ~isempty(Human_model(ii).Geometry)
    %                 bonepath=fullfile(bonespath,['Geometries_' Human_model(ii).Geometry]);
    %             else
    %                 bonepath=fullfile(bonespath,'Geometries');
    %             end
    %             try
    %                 load(fullfile(bonepath, Human_model(ii).name)) %#ok<LOAD>
    %                 nb_faces=4500;
    %                 if length(t)>nb_faces
    %                     bone.faces=t;
    %                     bone.vertices=p;
    %
    %                     bone_red=reducepatch(bone,nb_faces);
    %                     Human_model(ii).V=1.2063*k(ii)*bone_red.vertices;
    %                     Human_model(ii).F=bone_red.faces;
    %                 else
    %                     Human_model(ii).V=k(ii)*p;
    %                     Human_model(ii).F=t;
    %                 end
    %             catch
    %                 error(['3D Mesh not found of ' Human_model(ii).name]);
    %             end
end
else
    for ii=find([Human_model.Visual])
        load(['Visual/' Human_model(ii).name]); %#ok<LOAD>
        Human_model(ii).V = p;
        Human_model(ii).F=t;
    end
end



end