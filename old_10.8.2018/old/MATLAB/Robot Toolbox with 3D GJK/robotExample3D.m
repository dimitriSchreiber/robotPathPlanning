addpath ../mexTests/
clear;
close all;
figure('Position', [142 119 595 540]);
set(gcf, 'color', 'w');
dof = 6;

baseL = Link('d', 0, 'a', 0, 'alpha', pi/2, 'm', .001, 'r', [-0.5, 0, 0]);
L = Link('d', 0, 'a', 1, 'alpha', 0, 'm', .001, 'r', [-0.5, 0, 0]);
if mod(dof,2)
    R = SerialLink([repmat([baseL; L], 1, (dof-1)/2); L]);
else
    R = SerialLink(repmat([baseL; L], 1, dof/2));
end
R.base = trotx(0)*R.base;
R.name = 'R';

reachableRadius = sum(R.a); % radius of reachable workspace of arm

axLim = reachableRadius/1.2*[-1 1 -1 1 -1 1];
wspaceViewPt = [-15 30];

time_delay = 0;
%% first arm
robotColor = [0 0 1];
R.plotopt = {'perspective',  'nowrist', 'nojaxes', 'noname', 'shading', 'workspace', [-4 4 -4 4 -5 4], ...
    'tile1color', 0.9*[1,1,1], 'tile2color', [1,1,1], ...
    'jointdiam', 2.1, 'jointscale', 1, 'scale', 0.5 'jointcolor', 0.3*[1 1 1], ...
    'linkcolor', robotColor, 'toolcolor', robotColor, 'noshadow', ...
    'delay', time_delay};
%%
axis(axLim); axis square; hold on;
q_init = 2*pi*rand(1,dof);
opt = R.plot(q_init); w = opt.scale*2;

% F is face information for cubes. needed for GJK
F = [1 2 6 5; 2 4 8 6; 3 4 8 7; 1 3 7 5; 1 2 4 3; 5 6 8 7]';
obs_template = 0.2*combvec([-1 1],[-1 1],[-1 1])';
set(gca, 'Projection', 'perspective');
%%
% set up obstacles
numObs = 4;
offset = [2*(rand(numObs, 1))+1.5, zeros(numObs,1), 2*(rand(numObs, 1))-1]; % initial obs positions
obj_colors = jet(numObs);
obsIsClose = true(1, numObs); % boolean vector for if obs is within reach
%plot obstacles
for i = numObs:-1:1
    obs(i) = V2shapeMex(bsxfun(@plus, obs_template, offset(i,:)), F);
    obs_h(i) = patch('XData', obs(i).XData, 'YData', obs(i).YData, 'ZData', obs(i).ZData, 'FaceColor', obj_colors(i,:));
end
% set obstacle velocities
v = 2*rand(size(offset))-1;
v(:,2) = 0*v(:,2);
v(:,3) = 0*v(:,3);
v = 0.01*bsxfun(@rdivide, v, sum(v.^2,2).^0.5);

q = q_init;
for iter = 1:1000
    % Plot obstacles and prepare them for GJK collision checking
    delete(obs_h);
    obs_h = zeros(1,numObs);
    for o = 1:numObs
        % update vertices of cubes by adding velocities
        V = bsxfun(@plus, obs(o).V, v(o,:));
        % wrap obstacle around workspace if it goes too far away
        m_V = mean(V);
        for k = find(m_V < axLim([1 3 5])), V(:,k) = V(:,k) - 2*axLim(2*k-1); end
        for k = find(m_V > axLim([2 4 6])), V(:,k) = V(:,k) - 2*axLim(2*k); end
        
        % convert vertices to format needed for GJK
        obs(o) = V2shapeMex(V, F);
        
        % check if obstacle is even in the reachable workspace
        if any(sum(V.^2,2) < reachableRadius^2)
            obsIsClose(o) = 1;
            obs_h(o) = patch('XData', obs(o).XData, 'YData', obs(o).YData, 'ZData', obs(o).ZData, 'FaceColor', obj_colors(o,:), 'edgecolor', 'r', 'linewidth', 1);
        else
            obsIsClose(o) = 0;
            obs_h(o) = patch('XData', obs(o).XData, 'YData', obs(o).YData, 'ZData', obs(o).ZData, 'FaceColor', obj_colors(o,:), 'edgecolor', 'k', 'linewidth', 1);
        end
    end
    
    % move robot
    q(1) = q(1) + 0.01;
    R.plot(q);
    
    % perform collision checks
    P = generateArmPolyhedra(R,q,w);
    P = P(R.a~=0);
    if GJKarray(P, obs, 6) == -1
        title(sprintf('Collision'));
    else
        title(sprintf('No collision'));
    end
    
    % update figure
    drawnow limitrate;
end

