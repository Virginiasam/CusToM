function [animStruct]=AnimationFramebyFrame(ax,filename,AnalysisParameters,ModelParameters,AnimateParameters,Human_model,DataXSens,q,q6dof,PelvisPosition,PelvisOrientation,Markers_set,f_affich,Muscles,animStruct,real_markers,BiomechanicalModel)

















[AnatLandmark,Segment,seg_anim,bone_anim,mass_centers_anim,Global_mass_center_anim,Force_Prediction_points,muscles_anim,ellipsoid_anim,wrap_anim,mod_marker_anim,exp_marker_anim,external_forces_anim,external_forces_p,forceplate,BoS]=OptionsChoices(BiomechanicalModel,AnimateParameters);
[NbPointsPrediction,nb_ms,fmk,C_mk,C_ms,C_pt_p,num_s_mass_center,color0,color1,Prediction,Aopt,external_forces,color_vect_force,external_forces_pred,color_vect_force_p,lmax_vector_visual,coef_f_visual,ForceplatesData]=ColorsAnimation(filename,Muscles,AnimateParameters,Human_model,ModelParameters,AnalysisParameters,external_forces_anim,forceplate,mass_centers_anim, mod_marker_anim ,exp_marker_anim,Markers_set,Force_Prediction_points,muscles_anim,external_forces_p);


for f=f_affich
    
    if isfield(AnimateParameters,'Mode')  && (isequal(AnimateParameters.Mode, 'Figure') || isequal(AnimateParameters.Mode, 'Picture'))
        clf  % just for figure
        ax = gca;
        axis equal
        set(ax,'visible','off')
        camlight(ax, 'headlight');
        xlim(AnimateParameters.xlim);
        ylim(AnimateParameters.ylim);
        zlim(AnimateParameters.zlim);
        view(AnimateParameters.view);
    end
    
    %Initialization animStruct
    animStruct.Handles{f}=[];
    animStruct.Props{f}={};
    animStruct.Set{f}={};
    if  isfield(AnimateParameters,'Mode')  && ~isequal(AnimateParameters.Mode, 'GenerateAnimate') && ~isequal(AnimateParameters.Mode, 'GenerateParameters')
        hold on
    end
    
    %% forward kinematics
    if DataXSens
        qf = q(:,f);
        Human_model(1).p = PelvisPosition{f};
        Human_model(1).R = PelvisOrientation{f};
        [Human_model_bis] = ForwardKinematicsAnimation8XSens(Human_model,qf,1);
    else
        qf(1,:)=q6dof(6,f);
        qf(2:size(q,1),:)=q(2:end,f);
        qf((size(q,1)+2):(size(q,1)+6),:)=q6dof(1:5,f);
        [Human_model_bis,Muscles_test, Markers_set_test]=...
            ForwardKinematicsAnimation8(Human_model,Markers_set,Muscles,qf,find(~[Human_model.mother]),...
            seg_anim,muscles_anim,mod_marker_anim);
    end
    
    
    
    
    
    
    
    %% Segments
    if seg_anim
        V_seg=[];
        F_seg=[];
        if ~AnatLandmark
            liste=find([Human_model_bis.Visual]);
        else
            if  isempty(Segment)
                liste=find([Human_model_bis.Visual]);
            else
                liste=intersect(find([Human_model_bis.Visual]),Segment)';
            end
        end
        for j=liste
            pts = Human_model_bis(j).pos_pts_anim';
            if size(pts,1)>1
                F_seg =[F_seg; nchoosek(1:size(pts,1),2)+length(V_seg)]; %#ok<AGROW> %need to be done before V_seg !
            else
                F_seg =[F_seg; length(V_seg) length(V_seg)+1]; %#ok<AGROW> %need to be done before V_seg !
            end
            V_seg = [V_seg; pts];  %#ok<AGROW>
        end
        if isfield(AnimateParameters,'Mode')  && (isequal(AnimateParameters.Mode, 'Figure') ...
                || isequal(AnimateParameters.Mode, 'GenerateParameters') ...
                || isequal(AnimateParameters.Mode, 'GenerateAnimate'))
            finv = figure('visible','off');
            h_seg = gpatch(F_seg,V_seg,[],0.4*[1 1 1],1,4);
            copyobj(h_seg,ax);
            close(finv);
        elseif f==f_affich(1)
            h_seg = gpatch(F_seg,V_seg,[],0.4*[1 1 1],1,4);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} h_seg];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'}; %#ok<*CCAT>
        animStruct.Set{f} = {animStruct.Set{f}{:},V_seg};
    end
    
    %% Bones
    if bone_anim % To do % to concatenate bones;
        if isfield(Human_model_bis,'V')
            X=[];
            Fbones=[];
            
            jj=find(cellfun(@(x) numel(x), {Human_model_bis.V}));
            for j=1:length(jj)
                jjj=jj(j);
                cur_nb_V=length(Human_model_bis(jjj).V);
                cur_nb_F=length(Human_model_bis(jjj).F);
                tot_nb_F=length(Fbones);
                tot_nb_V=length(X);
                Fbones((1:cur_nb_F)+tot_nb_F,:)=Human_model_bis(jjj).F+tot_nb_V; %#ok<AGROW>
                onearray = ones([1,cur_nb_V]);
                if isempty(Human_model_bis(jjj).V)
                    temp=[];
                else
                    temp=(Human_model_bis(jjj).Tc_R0_Ri*...
                        [Human_model_bis(jjj).V';onearray ])';
                end
                X = [ X ;...
                    temp]; %#ok<AGROW>
            end
            if isfield(AnimateParameters,'Mode')  && (isequal(AnimateParameters.Mode, 'Figure') ...
                    || isequal(AnimateParameters.Mode, 'GenerateParameters') ...
                    || isequal(AnimateParameters.Mode, 'GenerateAnimate'))
                finv = figure('visible','off');
                hc = gpatch(Fbones,X(:,1:3),[227 218 201]/255*0.9,'none');
                copyobj(hc,ax);
                close(finv);
            elseif f==f_affich(1)
                hc = gpatch(Fbones,X(:,1:3),[227 218 201]/255*0.9,'none');
            end
            animStruct.Handles{f}=[animStruct.Handles{f} hc];
            animStruct.Props{f}={ animStruct.Props{f}{:}, 'Vertices'};
            animStruct.Set{f}={animStruct.Set{f}{:},X(:,1:3)};
        else
            if isfield(AnimateParameters,'Mode')  && ~isequal(AnimateParameters.Mode, 'Figure')
                warning('No osteo-articular bone model is available');
            end
        end
    end
    
    
    
    
    %% Markers
    % Mod�le
    if mod_marker_anim || exp_marker_anim
        Vsmk=[];
        if mod_marker_anim %% Markers on the model
            for i_m = 1:numel(Markers_set_test)
                cur_Vs=Markers_set_test(i_m).pos_anim';
                Vsmk=[Vsmk;cur_Vs]; %#ok<AGROW>
            end
        end
        % XP
        if exp_marker_anim %% Experimental markers
            for i_m = 1:numel(Markers_set_test)
                cur_Vs=real_markers(i_m).position(f,:);
                Vsmk=[Vsmk;cur_Vs]; %#ok<AGROW>
            end
        end
        if f==f_affich(1) || (isfield(AnimateParameters,'Mode')  && isequal(AnimateParameters.Mode, 'Figure'))
            m = patch(ax,'Faces',fmk,'Vertices',Vsmk,'FaceColor','none','FaceVertexCData',C_mk,'EdgeColor','none');
            m.Marker='o';
            m.MarkerFaceColor='flat';
            m.MarkerEdgeColor='k';
            m.MarkerSize=6;
        end
        animStruct.Handles{f}=[animStruct.Handles{f} m];
        animStruct.Props{f}={ animStruct.Props{f}{:},'Vertices'};
        animStruct.Set{f}={animStruct.Set{f}{:},Vsmk};
    end
    
    
    
    
    %% Anatomical landmarks
    
    if AnatLandmark
        scale=0.5;
        if ~isempty(Segment)
            anat_pointsold=[];
            labels=[];
            p1=[];p2=[];p3=[];
            R11=[];R12=[];R13=[];R21=[];R22=[];R23=[];R31=[];R32=[];R33=[];
            for index=Segment'
                if ~isempty( BiomechanicalModel.OsteoArticularModel(index).anat_position)
                    anat_points=BiomechanicalModel.OsteoArticularModel(index).anat_position(:,2);
                    for each_pt=1:size(anat_points,1)
                        anat_points{each_pt}=Human_model_bis(index).R*(anat_points{each_pt}+BiomechanicalModel.OsteoArticularModel(index).c)+Human_model_bis(index).p;
                    end
                    anat_pointsold = [anat_pointsold ; anat_points];
                end
                
                p1=[p1 Human_model_bis(index).p(1)];
                p2=[p2 Human_model_bis(index).p(2)];
                p3=[p3 Human_model_bis(index).p(3)];
                
                R11=[R11 Human_model_bis(index).R(1,1) ];
                R12=[R12 Human_model_bis(index).R(1,2)];
                R13=[R13 Human_model_bis(index).R(1,3)];
                
                
                R21=[R21 Human_model_bis(index).R(2,1) ];
                R22=[R22 Human_model_bis(index).R(2,2)];
                R23=[R23 Human_model_bis(index).R(2,3)];
                
                
                R31=[R31 Human_model_bis(index).R(3,1) ];
                R32=[R32 Human_model_bis(index).R(3,2)];
                R33=[R33 Human_model_bis(index).R(3,3)];
                
                labels=[labels; BiomechanicalModel.OsteoArticularModel(index).anat_position(:,1)];
                
            end
            
            
            C_col_p=repmat([253,108,168]/255,[size(anat_pointsold,1) 1]);
            
            an=[anat_pointsold{:}]';
            if f==f_affich(1)
                hanat = patch(ax,'Faces',1:size(anat_pointsold,1),'Vertices',[anat_pointsold{:}]','FaceColor','none','FaceVertexCData',C_col_p,'EdgeColor','none');
                hanat.Marker='o';
                hanat.MarkerFaceColor='flat';
                hanat.MarkerEdgeColor='k';
                hanat.MarkerSize=6;
                hframe=PlotFrame(Human_model_bis(index).p,Human_model_bis(index).R,scale);
                htext=text(an(:,1),an(:,2),an(:,3),labels);
            end
            
            animStruct.Handles{f} = [animStruct.Handles{f} hanat];
            animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'}; %#ok<*CCAT>
            
            animStruct.Set{f} = {animStruct.Set{f}{:},an};
            
            
            
            animStruct.Handles{f} = [animStruct.Handles{f} hframe(1) hframe(1) hframe(1) hframe(1) hframe(1) hframe(1) ];
            animStruct.Handles{f} = [animStruct.Handles{f} hframe(2) hframe(2) hframe(2) hframe(2) hframe(2) hframe(2)];
            animStruct.Handles{f} = [animStruct.Handles{f} hframe(3) hframe(3) hframe(3) hframe(3) hframe(3) hframe(3) ];
            animStruct.Props{f} = {animStruct.Props{f}{:},'XData','YData','ZData','UData','VData','WData'}; %#ok<*CCAT>
            animStruct.Props{f} = {animStruct.Props{f}{:},'XData','YData','ZData','UData','VData','WData'}; %#ok<*CCAT>
            animStruct.Props{f} = {animStruct.Props{f}{:},'XData','YData','ZData','UData','VData','WData'}; %#ok<*CCAT>
            
            animStruct.Set{f} = {animStruct.Set{f}{:},p1,p2,p3,R11 ,R12,R13};
            animStruct.Set{f} = {animStruct.Set{f}{:},p1,p2,p3,R21,R22,R23};
            animStruct.Set{f} = {animStruct.Set{f}{:},p1,p2,p3,R31,R32,R33};
            
            
            animStruct.Handles{f} = [animStruct.Handles{f} hframe(4) hframe(4) hframe(4)  ];
            animStruct.Handles{f} = [animStruct.Handles{f} hframe(5) hframe(5) hframe(5)  ];
            animStruct.Handles{f} = [animStruct.Handles{f} hframe(6) hframe(6) hframe(6)  ];
            animStruct.Props{f} = {animStruct.Props{f}{:},'Position','String','FontWeight'}; %#ok<*CCAT>
            animStruct.Props{f} = {animStruct.Props{f}{:},'Position','String','FontWeight'}; %#ok<*CCAT>
            animStruct.Props{f} = {animStruct.Props{f}{:},'Position','String','FontWeight'}; %#ok<*CCAT>
            animStruct.Set{f} = {animStruct.Set{f}{:},[p1+R11*scale, p2+R12*scale, p3+R13*scale],repmat('x',size(p1,2),1),repmat('bold',size(p1,2),1)};
            animStruct.Set{f} = {animStruct.Set{f}{:},[p1+R21*scale, p2+R22*scale, p3+R23*scale],repmat('y',size(p1,2),1),repmat('bold',size(p1,2),1)};
            animStruct.Set{f} = {animStruct.Set{f}{:},[p1+R31*scale, p2+R32*scale, p3+R33*scale],repmat('z',size(p1,2),1),repmat('bold',size(p1,2),1)};

            
            for tt=1:size(htext,1)
                animStruct.Handles{f} = [animStruct.Handles{f} htext(tt) htext(tt)];
                animStruct.Props{f} = {animStruct.Props{f}{:},'Position','String'}; %#ok<*CCAT>
                animStruct.Set{f} = {animStruct.Set{f}{:},an(tt,:),labels(tt)};
            end
            
            
            
        end
    end
    
    %% Mass Centers
    if mass_centers_anim
        Vsms=[];
        if ~AnatLandmark
            liste=num_s_mass_center;
        else
            if  isempty(Segment)
                liste=num_s_mass_center;
            else
                liste=intersect(num_s_mass_center,Segment)';
            end
        end
        for j=liste
            X = (Human_model_bis(j).Tc_R0_Ri(1:3,4))';
            Vsms=[Vsms;X]; %#ok<AGROW>
        end
        temp_nb_ms=length(liste);
        if f==f_affich(1) || (isfield(AnimateParameters,'Mode')  && isequal(AnimateParameters.Mode, 'Figure'))
            hmass = patch(ax,'Faces',1:temp_nb_ms,'Vertices',Vsms,'FaceColor','none','FaceVertexCData',C_ms(1:temp_nb_ms,:),'EdgeColor','none');
            hmass.Marker='o';
            hmass.MarkerFaceColor='flat';
            hmass.MarkerEdgeColor='k';
            hmass.MarkerSize=6;
        end
        animStruct.Handles{f}=[animStruct.Handles{f} hmass];
        animStruct.Props{f}={animStruct.Props{f}{:}, 'Vertices'};
        animStruct.Set{f}={animStruct.Set{f}{:},Vsms};
    end
    
    %% Global Mass Centers
    if Global_mass_center_anim
        CoM = CalcCoM(Human_model_bis);
        X = CoM';
        if f==f_affich(1) || (isfield(AnimateParameters,'Mode')  &&  isequal(AnimateParameters.Mode, 'Figure'))
            hGmass=patch(ax,'Faces',1,'Vertices',X,'FaceColor','none','FaceVertexCData',[34,139,34]/255,'EdgeColor','none');
            hGmass.Marker='o';
            hGmass.MarkerFaceColor='flat';
            hGmass.MarkerEdgeColor='k';
            hGmass.MarkerSize=10;
        end
        animStruct.Handles{f}=[animStruct.Handles{f} hGmass];
        animStruct.Props{f}={animStruct.Props{f}{:}, 'Vertices'};
        animStruct.Set{f}={animStruct.Set{f}{:},X};
    end
    
    %% Force Prediction points
    if Force_Prediction_points
        Vpt_p=[];
        for j=1:NbPointsPrediction
            i_so=Prediction(j).num_solid;
            num_m=Prediction(j).num_markers;
            pt_pred=Human_model_bis(i_so).anat_position{num_m,2};
            X = Human_model_bis(i_so).Tc_R0_Ri*[pt_pred;1];
            Vpt_p=[Vpt_p;X(1:3)']; %#ok<AGROW>
        end
        if f==f_affich(1) || isequal(AnimateParameters.Mode, 'Figure')
            hmass = patch(ax,'Faces',1:NbPointsPrediction,'Vertices',Vpt_p,'FaceColor','none','FaceVertexCData',C_pt_p,'EdgeColor','none');
            hmass.Marker='o';
            hmass.MarkerFaceColor='flat';
            hmass.MarkerEdgeColor='k';
            hmass.MarkerSize=6;
        end
        animStruct.Handles{f}=[animStruct.Handles{f} hmass];
        animStruct.Props{f}={animStruct.Props{f}{:}, 'Vertices'};
        animStruct.Set{f}={animStruct.Set{f}{:},Vpt_p};
    end
    
    %% Scapulo-thoracic Ellipsoid
    if ellipsoid_anim
        %&& sum(cellfun(@isempty,[Muscles.wrap]'))==0
        Fe=[];
        CEe=[];
        Ve=[];
        num_solid=7;
        
        for i_w = 1:2
            pos_ell=Human_model_bis(7).anat_position{8+i_w, 2};
            T_Ri_Rw=[eye(3,3), pos_ell;[0 0 0],1];
            X = Human_model_bis(num_solid).Tc_R0_Ri*T_Ri_Rw;
            [xel1,yel1,zel1]=ellipsoid(0,0,0,1.8/1.7*0.07,1.8/1.7*0.15,1.8/1.7*0.07);
            [Fel1,Vel1]=surf2patch(xel1,yel1,zel1);
            Vell_R0= (X*[Vel1';ones(1,length(Vel1))])';
            
            tot_nb_F=length(Fe);
            cur_nb_F=length(Fel1);
            tot_nb_V=length(Ve);
            Fe((1:cur_nb_F)+tot_nb_F,:)=Fel1+tot_nb_V;
            Ve=[Ve ;Vell_R0(:,1:3)]; %#ok<AGROW>
        end
        if isfield(AnimateParameters,'Mode')  &&  (isequal(AnimateParameters.Mode, 'Figure') ...
                || isequal(AnimateParameters.Mode, 'GenerateParameters') ...
                || isequal(AnimateParameters.Mode, 'GenerateAnimate'))
            finv = figure('visible','off');
            he=gpatch(Fe,Ve,'c','none',0.3);
            copyobj(he,ax);
            close(finv);
        elseif f==f_affich(1)
            he=gpatch(Fe,Ve,'c','none',0.3);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} he];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'};
        animStruct.Set{f} = {animStruct.Set{f}{:},Ve};
    end
    
    %% Muscle wraps
    if wrap_anim && isfield(Human_model,'wrap') && numel([Human_model.wrap])>0
        %&& sum(cellfun(@isempty,[Muscles.wrap]'))==0
        Fw=[];
        CEw=[];
        Vw=[];
        Wraps = [Human_model.wrap];
        
        for i_w = 1:numel(Wraps)
            num_solid=Wraps(i_w).num_solid;
            T_Ri_Rw=[Wraps(i_w).orientation,Wraps(i_w).location;[0 0 0],1];
            X = Human_model_bis(num_solid).Tc_R0_Ri*T_Ri_Rw;
            [Fcyl,Vcyl]=PlotCylinder(Wraps(i_w).R,Wraps(i_w).h);
            Vcyl_R0= (X*[Vcyl';ones(1,length(Vcyl))])';
            tot_nb_F=length(Fw);
            cur_nb_F=length(Fcyl);
            tot_nb_V=length(Vw);
            Fw((1:cur_nb_F)+tot_nb_F,:)=Fcyl+tot_nb_V;
            Vw=[Vw ;Vcyl_R0(:,1:3)]; %#ok<AGROW>
        end
        if isfield(AnimateParameters,'Mode')  && (isequal(AnimateParameters.Mode, 'Figure') ...
                || isequal(AnimateParameters.Mode, 'GenerateParameters') ...
                || isequal(AnimateParameters.Mode, 'GenerateAnimate'))
            finv = figure('visible','off');
            hw=gpatch(Fw,Vw,'c','none',0.75);
            copyobj(hw,ax);
            close(finv);
        elseif f==f_affich(1)
            hw=gpatch(Fw,Vw,'c','none',0.75);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} hw];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'};
        animStruct.Set{f} = {animStruct.Set{f}{:},Vw};
    end
    
    %% Muscles
    if muscles_anim && ~isempty(Muscles) && sum([Muscles.exist])
        Fmu=[];
        CEmu=[];
        Vmu=[];
        color_mus = color0 + Aopt(:,f)*(color1 - color0);
        ind_mu=find([Muscles_test.exist]==1);
        for i_mu = 1:numel(ind_mu)
            mu=ind_mu(i_mu);
            pts_mu = Muscles_test(mu).pos_pts';
            nbpts_mu = size(pts_mu,1);
            if ~isempty(Muscles(mu).wrap) && ~isempty(Muscles(mu).wrap{1})
                % find the wrap
                Wrap = [Human_model.wrap]; names = {Wrap.name}'; [~,ind]=intersect(names,Muscles(mu).wrap{1});
                cur_Wrap=Wrap(ind);
                % wrap object
                T_Ri_Rw=[cur_Wrap.orientation,cur_Wrap.location;[0 0 0],1];
                T_R0_Rw = Human_model_bis(cur_Wrap.num_solid).Tc_R0_Ri*T_Ri_Rw;
                % pts in Rw
                pts_mu_inRw=T_R0_Rw\[pts_mu';ones(1,nbpts_mu)];
                % verify if wrap.
                for imw=1:nbpts_mu-1
                    if Intersect_line_cylinder(pts_mu_inRw(1:3,imw)', pts_mu_inRw(1:3,imw+1)', cur_Wrap.R)
                        [L(f),~,~,pt_wrap_inRw(:,:,imw)]=CylinderWrapping(pts_mu_inRw(1:3,imw), pts_mu_inRw(1:3,imw+1), cur_Wrap.R);
                        tmp=T_R0_Rw*[pt_wrap_inRw(:,:,imw)';ones(1,size(pt_wrap_inRw,1))];
                        pt_wrap(:,:,imw)=tmp(1:3,:)';
                        % add the wrapping points
                        nb_added_pts=size([pts_mu(imw,:);pt_wrap(:,:,imw)],1);
                        cur_Fmu = repmat([1 2],[nb_added_pts-1 1])+(0:nb_added_pts-2)'+size(Vmu,1);
                        Vmu=[Vmu;pts_mu(imw,:);pt_wrap(:,:,imw)];
                        Fmu =[Fmu; cur_Fmu]; %#ok<AGROW>
                        CEmu=[CEmu; repmat(color_mus(mu,:),[nb_added_pts 1])]; %#ok<AGROW>
                    else
                        if imw>1
                            cur_Fmu = [1 2]+size(Vmu,1);
                            Fmu =[Fmu; cur_Fmu]; %#ok<AGROW>
                        end
                        Vmu=[Vmu ;pts_mu(imw,:)]; %#ok<AGROW>
                        CEmu=[CEmu; color_mus(mu,:)]; %#ok<AGROW>
                    end
                end
                cur_Fmu = repmat([0 1],[1 1])+size(Vmu,1);
                Fmu =[Fmu; cur_Fmu]; %#ok<AGROW>
                Vmu=[Vmu ;pts_mu(end,:)]; %#ok<AGROW>
                CEmu=[CEmu; color_mus(mu,:)]; %#ok<AGROW>
            else
                cur_Fmu = repmat([1 2],[nbpts_mu-1 1])+(0:nbpts_mu-2)'+size(Vmu,1);
                Fmu =[Fmu; cur_Fmu]; %#ok<AGROW>
                Vmu=[Vmu ;pts_mu]; %#ok<AGROW>
                CEmu=[CEmu; repmat(color_mus(mu,:),[nbpts_mu 1])]; %#ok<AGROW>
            end
            
        end
        if isfield(AnimateParameters,'Mode')  && (isequal(AnimateParameters.Mode, 'Figure') ...
                || isequal(AnimateParameters.Mode, 'GenerateParameters') ...
                || isequal(AnimateParameters.Mode, 'GenerateAnimate'))
            finv = figure('visible','off');
            hmu=gpatch(Fmu,Vmu,[],CEmu,1,2);
            copyobj(hmu,ax);
            close(finv);
        elseif f==f_affich(1)
            hmu=gpatch(Fmu,Vmu,[],CEmu,1,2);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} hmu hmu hmu];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Faces','Vertices','FaceVertexCData'};
        animStruct.Set{f} = {animStruct.Set{f}{:},Fmu,Vmu,CEmu};
    end
    
    %% Vectors of external forces issued from experimental data
    if external_forces_anim
        extern_forces_f = external_forces(f).Visual;
        F_ef=[];V_ef=[];
        for i_for=1:size(extern_forces_f,2)
            if norm(extern_forces_f(4:6,i_for)) > 50
                X_array=[extern_forces_f(1,i_for),...
                    extern_forces_f(1,i_for) + extern_forces_f(4,i_for)/coef_f_visual];
                Y_array=[extern_forces_f(2,i_for),...
                    extern_forces_f(2,i_for) + extern_forces_f(5,i_for)/coef_f_visual];
                Z_array=[extern_forces_f(3,i_for),...
                    extern_forces_f(3,i_for) + extern_forces_f(6,i_for)/coef_f_visual];
                F_ef = [F_ef; [1 2]+size(V_ef,1)]; %#ok<AGROW>
                V_ef = [V_ef; [X_array' Y_array' Z_array']]; %#ok<AGROW>
            end
        end
        if isfield(AnimateParameters,'Mode')  && (isequal(AnimateParameters.Mode, 'Figure') ...
                || isequal(AnimateParameters.Mode, 'GenerateParameters') ...
                || isequal(AnimateParameters.Mode, 'GenerateAnimate'))
            finv = figure('visible','off');
            Ext = gpatch(F_ef,V_ef,[],color_vect_force,1,4);
            copyobj(Ext,ax);
            close(finv);
        elseif f==f_affich(1)
            Ext = gpatch(F_ef,V_ef,[],color_vect_force,1,4);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} Ext];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'};
        animStruct.Set{f} = {animStruct.Set{f}{:},V_ef};
    end
    
    %% Vectors of external forces issued from prediction
    if external_forces_p
        extern_forces_f = external_forces_pred(f).Visual;
        F_efp=[];V_efp=[];
        for i_for=1:size(extern_forces_f,2)
            if norm(extern_forces_f(4:6,i_for)) > 50
                X_array=[extern_forces_f(1,i_for),...
                    extern_forces_f(1,i_for) + extern_forces_f(4,i_for)/coef_f_visual];
                Y_array=[extern_forces_f(2,i_for),...
                    extern_forces_f(2,i_for) + extern_forces_f(5,i_for)/coef_f_visual];
                Z_array=[extern_forces_f(3,i_for),...
                    extern_forces_f(3,i_for) + extern_forces_f(6,i_for)/coef_f_visual];
                F_efp = [F_efp; [1 2]+size(V_efp,1)]; %#ok<AGROW>
                V_efp = [V_efp; [X_array' Y_array' Z_array']]; %#ok<AGROW>
            end
        end
        if isfield(AnimateParameters,'Mode')  && (isequal(AnimateParameters.Mode, 'Figure') ...
                || isequal(AnimateParameters.Mode, 'GenerateParameters') ...
                || isequal(AnimateParameters.Mode, 'GenerateAnimate'))
            finv = figure('visible','off');
            Extp = gpatch(F_efp,V_efp,[],color_vect_force_p,1,4);
            copyobj(Extp,ax);
            close(finv);
        elseif f==f_affich(1)
            Extp = gpatch(F_efp,V_efp,[],color_vect_force_p,1,4);
        end
        animStruct.Handles{f} = [animStruct.Handles{f} Extp];
        animStruct.Props{f} = {animStruct.Props{f}{:},'Vertices'};
        animStruct.Set{f} = {animStruct.Set{f}{:},V_efp};
    end
    
    %% Display force plates position
    if forceplate
        if isequal(AnalysisParameters.ExternalForces.Method, @DataInC3D)
            x_fp = []; y_fp = []; z_fp = [];
            for i=1:numel(ForceplatesData)
                if ~isequal(AnalysisParameters.ExternalForces.Options{i}, 'NoContact')
                    x_fp = [x_fp ForceplatesData(i).corners(1,:)'/1000]; %#ok<AGROW> % mm -> m
                    y_fp = [y_fp ForceplatesData(i).corners(2,:)'/1000]; %#ok<AGROW> % mm -> m
                    z_fp = [z_fp ForceplatesData(i).corners(3,:)'/1000]; %#ok<AGROW> % mm -> m
                end
            end
        elseif isequal(AnalysisParameters.ExternalForces.Method, @PF_IRSST)
            x_fp = ExperimentalData.CoinsPF(1,:)/1000; % mm -> m
            y_fp = ExperimentalData.CoinsPF(2,:)/1000; % mm -> m
            z_fp = ExperimentalData.CoinsPF(3,:)/1000; % mm -> m
        end
        patch(ax,x_fp,y_fp,z_fp,[1 1 1]);
    end
    
    %% Base of support
    if BoS
        if numel(InverseKinematicsResults.BoS{1,f})
            x_bos = InverseKinematicsResults.BoS{1,f}(1,:);
            y_bos = InverseKinematicsResults.BoS{1,f}(2,:);
            z_bos = InverseKinematicsResults.BoS{1,f}(3,:);
            patch(ax,x_bos,y_bos,z_bos,[1 .4 0]);
        end
    end
    
    %% Save figure
    if isfield(AnimateParameters,'Mode')  && isequal(AnimateParameters.Mode, 'Figure')
        % drawing an saving
        drawnow;
        M(f) = getframe(fig); %#ok<AGROW>
    end
    
    if isfield(AnimateParameters,'Mode')  && isequal(AnimateParameters.Mode, 'Picture')
        saveas(fig,[filename '_' num2str(f)],'png');
        close(fig);
    end
    
end

end