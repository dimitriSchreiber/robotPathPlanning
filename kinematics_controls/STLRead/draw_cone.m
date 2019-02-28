%% Load STL mesh
% Stereolithography (STL) files are a common format for storing mesh data. STL
% meshes are simply a collection of triangular faces. This type of model is very
% suitable for use with MATLAB's PATCH graphics object.

% Import an STL mesh, returning a PATCH-compatible face-vertex structure
fv = stlread('MRI-scanner-male-torso-001-1.STL');


%% Convert to point cloud
F = fv.faces;
V = fv.vertices;

%% Transform vertices
% rotate
Rx = [ 1,   0,     0
     0,  cos(pi/2), sin(pi/2);
     0, -sin(pi/2), cos(pi/2)];
 
Rz = [cos(pi), sin(pi), 0;
     -sin(pi), cos(pi), 0;
     0,          0,         1];
 
Ry = [cos(pi), 0, sin(pi);
     0,     1,          0;
     -sin(pi),   0,   cos(pi)];
 
V_r = V*Rx'*Rz'*Ry';

% convert from mm to m
V_rm = V_r / 1e3;

% translate
% V_rm(:,1) = V_rm(:,1)-1.03;
% V_rm(:,2) = V_rm(:,2)+0.8;
% V_rm(:,3) = V_rm(:,3)-1.5;
% V_rm(:,1) = V_rm(:,1)-1.03;
% V_rm(:,2) = V_rm(:,2)+0.93;
% V_rm(:,3) = V_rm(:,3)-1;
V_rm(:,1) = V_rm(:,1)-1.03;
V_rm(:,2) = V_rm(:,2)+0.6; % change y pos
V_rm(:,3) = V_rm(:,3)-1;% change z pos

ptCloud = pointCloud(V_rm);

%% load num_bins and create colormap
num_bin = csvread('../notebooks/logs/num_bin.csv');
nn = uint8(num_bin);
nn_temp = ind2rgb(nn,jet);
colormap_new(:,1) = nn_temp(:,:,1);
colormap_new(:,2) = nn_temp(:,:,2);
colormap_new(:,3) = nn_temp(:,:,3);

fig = figure()
colormap(jet)
scatter3(V_rm(:,1),V_rm(:,2),V_rm(:,3),36, colormap_new,'filled','s')
colorbar('Ticks',[0,0.25,0.5,0.75,1],...
         'TickLabels',{'Cold','Cool','Neutral','Warm','Hot'})
axis equal
hold on

%% Draw Cone
% cone 1
X1=[0 -0.1 -0.12];
X2=[0 -0.1 0];
R=[0.01 0.2];
n=20;
cyl_color='r';
closed=0;
lines=1;

Cone(X1,X2,R,n,cyl_color,closed,lines);

% cone 2
X1=[0 -0.45 -0.15];
X2=[0 -0.40 -0.02];
R=[0.01 0.05];
n=20;
cyl_color='b';
closed=0;
lines=1;

Cone(X1,X2,R,n,cyl_color,closed,lines)

hold off

% saveas(fig,'heatmap_with_cone.fig')
% saveas(fig,'heatmap_with_cone.png')
% cone 3
% X1=[0 0.43 -0.18];
% X2=[0 0.53 -0.05];
% R=[0.01 0.15];
% n=20;
% cyl_color='r';
% closed=0;
% lines=1;
% 
% Cone(X1,X2,R,n,cyl_color,closed,lines)