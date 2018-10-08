%% 3D Model Demo
% This is short demo that loads and renders a 3D model of a human femur. It
% showcases some of MATLAB's advanced graphics features, including lighting and
% specular reflectance.

% Copyright 2011 The MathWorks, Inc.


%% Load STL mesh
% Stereolithography (STL) files are a common format for storing mesh data. STL
% meshes are simply a collection of triangular faces. This type of model is very
% suitable for use with MATLAB's PATCH graphics object.

% Import an STL mesh, returning a PATCH-compatible face-vertex structure
%fv = stlread('femur.stl');
fv = {}
fv{1} = stlread('../stl_models/MRI scanner - Base Frame-1.STL');
fv{2} = stlread('../stl_models/MRI scanner - Base Frame-1-1.STL');
fv{3} = stlread('../stl_models/MRI scanner - Bed Base-1.STL');
fv{4} = stlread('../stl_models/MRI scanner - Bed Base-1-1.STL');
fv{5} = stlread('../stl_models/MRI scanner - Center Part-1.STL');
fv{6} = stlread('../stl_models/MRI scanner - Center Part-1-1.STL');
fv{7} = stlread('../stl_models/MRI scanner - male-torso-001-1.STL');
fv{8} = stlread('../stl_models/MRI scanner - male-torso-001-1-1.STL');
fv{9} = stlread('../stl_models/MRI scanner - Moving Bed-1.STL');
fv{10} = stlread('../stl_models/MRI scanner - Moving Bed-1-1.STL');

%% Render
% The model is rendered with a PATCH graphics object. We also add some dynamic
% lighting, and adjust the material properties to change the specular
% highlighting.

for i = 1:length(fv)
    patch(fv{i},'FaceColor',       [0.8 0.8 1.0], ...
             'EdgeColor',       'none',        ...
             'FaceLighting',    'gouraud',     ...
             'AmbientStrength', 0.15);
end


% Add a camera light, and tone down the specular highlighting
camlight('headlight');
material('dull');

% Fix the axes scaling, and set a nice view angle
axis('image');
view([-135 35]);