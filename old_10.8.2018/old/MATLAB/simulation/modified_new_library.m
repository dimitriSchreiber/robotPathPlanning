addpath ../mexTests/
clear;
close all;
warning on;

figure('Position', [142 119 595 540]);
set(gcf, 'color', 'w');

numLinks = 6;
robot = SerialLink( repmat(Revolute('a', 7.62, 'alpha', 1.5708, 'd', 0.8), numLinks, 1),  'name', 'my robot')
reachableRadius = sum(robot.a); % radius of reachable workspace of arm
axLim = reachableRadius/1.2*[-1 1 -1 1 -1 1];
wspaceViewPt = [-15 30];

time_delay = 0.05;

robot.plotopt = {'delay', time_delay};

%forward kinematics test plot
if 1
    a = -pi/2;
    b = pi/2;
    q_init = (b-a).*rand(numLinks,1)' + a
    q_final = (b-a).*rand(numLinks,1)' + a
    q_ts = []
    for i = 1:numLinks
        q_ts(:,i) = linspace(q_init(i), q_final(i), 100);
    end
    robot.plot(q_ts);
    TE = robot.fkine(q_ts);
end

%inverse kinematics test plot
length = sum(robot.a);
a = -pi/2;
b = pi/2;
cartesian_init = (b-a).*rand(6,1)' + a;
cartesian_final = (b-a).*rand(6,1)' + a;
cartesian_init(1:3) = [0,0,length/5];
cartesian_final(1:3) = [0,length/5,0];

cartesian_ts = []
for i = 1:6
    cartesian_ts(:,i) = linspace(cartesian_init(i), cartesian_final(i), 1000);
end

goals = SE3(cartesian_ts(:,1:3));
goalsSaved = goals;
for i = 1:size(goals,2)
    goals(i)=goalsSaved(i)*SE3.eul(cartesian_ts(i,4:6));
end

q_ts_inv = []

q_ts_inv = robot.ikine(goals);
%q_ts_inv = ikine_old(robot, goals.T);

h = gcf;
robot.plot(zeros(1,robot.n));
filename = 'testAnimated.gif';
for j = 1:(size(q_ts_inv,1))
    robot.plot(q_ts_inv(j,:))
    
    % Capture the plot as an image 
    frame = getframe(h); 
    im = frame2im(frame); 
    [imind,cm] = rgb2ind(im,256); 
    % Write to the GIF File 
    if j == 1 
      imwrite(imind,cm,filename,'gif', 'DelayTime', time_delay, 'Loopcount',inf); 
    else 
      imwrite(imind,cm,filename,'gif','DelayTime', time_delay, 'WriteMode','append'); 
    end 
end

%generate constraint boundary to work inside
%units in cm
close all
theta1 = 48.2;
theta2 = 180-theta1;
radius = 30
z = radius*sind(theta1);
y = 100;
x = radius*cosd(theta1);
rect = [-x 0 z; x 0 z; x y z; -x y z];

%poly_rectangle(rect(1,:), rect(2,:), rect(3,:), rect(4,:));

thetas = linspace(theta1, theta2, 100);
zs = radius*sind(thetas);
ys = 100*ones(100,1)';
xs = radius*cosd(thetas);

xs = [xs x] + 20;
ys = [ys y] + 40;
zs = [zs z] -20;
for i = 1:(size(xs,2)-1)
    rect = [xs(i) 0 zs(i); xs(i+1) 0 zs(i+1); xs(i+1) ys(i+1) zs(i+1); xs(i) ys(i) zs(i)];
    poly_rectangle(rect(1,:), rect(2,:), rect(3,:), rect(4,:));
end