%% Load STL mesh
% Stereolithography (STL) files are a common format for storing mesh data. STL
% meshes are simply a collection of triangular faces. This type of model is very
% suitable for use with MATLAB's PATCH graphics object.

% Import an STL mesh, returning a PATCH-compatible face-vertex structure
fv = stlread('MRI-scanner-male-torso-001-1.STL');


%% Render
% The model is rendered with a PATCH graphics object. We also add some dynamic
% lighting, and adjust the material properties to change the specular
% highlighting.

patch(fv,'FaceColor',       [0.8 0.8 1.0], ...
         'EdgeColor',       'none',        ...
         'FaceLighting',    'gouraud',     ...
         'AmbientStrength', 0.15);

% Add a camera light, and tone down the specular highlighting
camlight('headlight');
material('dull');

% Fix the axes scaling, and set a nice view angle
axis('image');
view([-135 35]);


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

%% Save vertices
save('Torso_vertices.mat','V_rm')

%% load num_bins and create colormap
num_bin = csvread('../notebooks/logs/num_bin.csv');
colormap_set = zeros(size(num_bin,1),3);
colormap_set(:,1) = num_bin/max(num_bin);       % adjust color here
%colormap(:,2) = num_bin/max(num_bin);
%colormap(:,3) = num_bin/max(num_bin);

%% Plot
figure()
scatter3(V_rm(:,1),V_rm(:,2),V_rm(:,3),36, colormap_set,'filled','s')
colorbar('Ticks',[0,0.25,0.5,0.75,1],...
         'TickLabels',{'Cold','Cool','Neutral','Warm','Hot'})
axis equal

% Save ply file
plywrite('TorsoHotmap.ply',fv.faces,V_rm, uint8(colormap_set*255))

%% Color map test
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
% colorbar('Ticks',[0,1],...
%          'TickLabels',{'low dexterity','high dexterity'})
axis equal

% saveas(fig,'heatmap_with_colorbar_2.fig')
% saveas(fig,'heatmap_with_colorbar.png')

% Save ply file
plywrite('TorsoHotmap_colorbar.ply',fv.faces,V_rm, uint8(colormap_new*255))