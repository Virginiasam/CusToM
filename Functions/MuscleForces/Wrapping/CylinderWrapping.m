function [L,Q,T,AnimPt_in_Rw]=CylinderWrapping(P,S,R)
% Provide the length wrapping around a cylinder
%   Based on:
%   -B.A. Garner and M.G. Pandy, The obstacle-set method for 
%   representing muscle paths in musculoskeletal models, 
%   Comput. Methods Biomech. Biomed. Engin. 3 (2000), pp. 1�30.
%
%   INPUT
%   - P1: array 3x1 position of the first point
%   - P2: array 3x1 position of the second point
%   - R: radius of the cylinder
%   OUTPUT
%   - L: minimal Length between P and S wrapping around the cylinder.
%________________________________________________________
%
% Licence
% Toolbox distributed under GPL 3.0 Licence
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________
if size(P,1)<3 || size(S,1)<3 
    error('P or S need to 3x1 arrays');
end


%%% Cartesian coordiantes of Q and T in xy plan
Qx1 = (P(1)*R^2-R*P(2)*sqrt(P(1)^2+P(2)^2-R^2))/(P(1)^2+P(2)^2);
Qy1 = (P(2)*R^2+R*P(1)*sqrt(P(1)^2+P(2)^2-R^2))/(P(1)^2+P(2)^2);
Qx2 = (P(1)*R^2+R*P(2)*sqrt(P(1)^2+P(2)^2-R^2))/(P(1)^2+P(2)^2);
Qy2 = (P(2)*R^2-R*P(1)*sqrt(P(1)^2+P(2)^2-R^2))/(P(1)^2+P(2)^2);

Q1_xy = [Qx1; Qy1];
Q2_xy = [Qx2; Qy2];


Tx1 = (S(1)*R^2+R*S(2)*sqrt(S(1)^2+S(2)^2-R^2))/(S(1)^2+S(2)^2);
Ty1 = (S(2)*R^2-R*S(1)*sqrt(S(1)^2+S(2)^2-R^2))/(S(1)^2+S(2)^2);
Tx2 = (S(1)*R^2-R*S(2)*sqrt(S(1)^2+S(2)^2-R^2))/(S(1)^2+S(2)^2);
Ty2 = (S(2)*R^2+R*S(1)*sqrt(S(1)^2+S(2)^2-R^2))/(S(1)^2+S(2)^2);

T1_xy = [Tx1; Ty1];
T2_xy = [Tx2; Ty2];

% Compute distance btween Q and P and T and S in xy plan,
% 2 ways possible / solutions
dist_QP_xy1 = norm(Q1_xy-P(1:2));
dist_QP_xy2 = norm(Q2_xy-P(1:2));

dist_TS_xy1 = norm(T1_xy-S(1:2));
dist_TS_xy2 = norm(T2_xy-S(1:2));

%%% Z coordinates
Qz1 = P(3)+((S(3)-P(3))*dist_QP_xy1)/(dist_QP_xy1+norm(T1_xy-Q1_xy)+dist_TS_xy1);
Tz1 = S(3)-((S(3)-P(3))*dist_TS_xy1)/(dist_QP_xy1+norm(T1_xy-Q1_xy)+dist_TS_xy1);
Qz2 = P(3)+((S(3)-P(3))*dist_QP_xy2)/(dist_QP_xy2+norm(T2_xy-Q2_xy)+dist_TS_xy2);
Tz2 = S(3)-((S(3)-P(3))*dist_TS_xy2)/(dist_QP_xy2+norm(T2_xy-Q2_xy)+dist_TS_xy2);

% Solution 1
Q1 = [Qx1; Qy1; Qz1];
T1 = [Tx1; Ty1; Tz1];
norm_QT_xy1 = abs(R*acos(1-((Qx1-Tx1)^2+(Qy1-Ty1)^2)/(2*R^2)));
l_arc1 = sqrt(norm_QT_xy1^2+(Tz1-Qz1)^2);

% Solution 2
Q2 = [Qx2; Qy2; Qz2];
T2 = [Tx2; Ty2; Tz2];
norm_QT_xy2 = abs(R*acos(1-((Qx2-Tx2)^2+(Qy2-Ty2)^2)/(2*R^2)));
l_arc2 = sqrt(norm_QT_xy2^2+(Tz2-Qz2)^2);

% Concatenate the solutions
Q = [Q1, Q2];
T = [T1, T2];
L = [norm(P-Q(:, 1))+norm(T(:, 1)-S)+l_arc1, norm(P-Q(:, 2))+norm(T(:, 2)-S)+l_arc2];

%Choose the minimal one,
[~,ind]=min(L); ind
L=L(ind);Q=Q(:,ind);T=T(:,ind);

if nargout>3
    theta1 = 2*atand(Q(2)/ (Q(1) + sqrt( Q(1)^2 + Q(2)^2 ) ));
    theta2 = 2*atand(T(2)/ (T(1) + sqrt( T(1)^2 + T(2)^2 ) ));
    n=20;
    theta = linspace(theta1,theta2,n);
    z_T = linspace(Q(3),T(3),n);
    x = R*cosd(theta);
    y = R*sind(theta);
    z = z_T;
    
    AnimPt_in_Rw=[x',y',z'];
    
% figure
% fastscatter3(Q); hold on
% fastscatter3(T)
% plot(2*cosd(0:360),2*sind(0:360))
% axis equal
% plot(2*cosd(theta1),2*sind(theta1),'bo')
% plot(2*cosd(theta2),2*sind(theta2),'ro')
% plot(R*cosd(theta),R*sind(theta),'k-')

end

end