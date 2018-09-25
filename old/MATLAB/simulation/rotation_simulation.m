addpath ../mexTests/
clear;
close all;
warning on;

figure('Position', [142 119 595 540]);
set(gcf, 'color', 'w');

numLinks = 10;
robot = SerialLink( repmat(Revolute('a', 7.62, 'alpha', 1.5708, 'd', 0.8, 'qlim', [-3*pi/8, 3*pi/8]), numLinks, 1),  'name', 'my robot')
reachableRadius = sum(robot.a); % radius of reachable workspace of arm
axLim = reachableRadius/1.2*[-1 1 -1 1 -1 1];
wspaceViewPt = [-15 30];

time_delay = 0.05;

robot.plotopt = {'perspective',  'jointdiam', 1, 'jointscale', 1, 'scale', 1 'jointcolor', 0.3*[1 1 1], ...
    'noshadow', 'delay', time_delay};

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

%inverse kinematics test plot of above forward pass
if 1
%     length = sum(robot.a);
%     a = -pi/2;
%     b = pi/2;
%     cartesian_init = (b-a).*rand(6,1)' + a;
%     cartesian_final = (b-a).*rand(6,1)' + a;
%     cartesian_init(1:3) = [0,0,length/5];
%     cartesian_final(1:3) = [0,length/5,0];
% 
%     cartesian_ts = []
%     for i = 1:6
%         cartesian_ts(:,i) = linspace(cartesian_init(i), cartesian_final(i), 100);
%     end
    
    cartesian_ts = robot.fkine(q_ts);
    goals = cartesian_ts;
%    goals = SE3(cartesian_ts(:,1:3));
%    goalsSaved = goals;
%    for i = 1:size(goals,2)
%        goals(i)=goalsSaved(i)*SE3.eul(cartesian_ts(i,4:6));
%    end

    q_ts_inv = []

%    q_ts_inv = robot.ikunc(goals.T);
    q_ts_inv = robot.ikunc(goals);
    robot.plot(q_ts_inv);
    %q_ts_inv = ikine_old(robot, goals.T);

    %generate and save gif of robot
    h = gcf;
    robot.plot(zeros(1,robot.n));
    filename = 'inverse_forward_pass.gif';
    for j = 1:(size(q_ts_inv,1))
        robot.plot(q_ts_inv(j,:))

        %Capture the plot as an image 
        frame = getframe(h); 
        im = frame2im(frame); 
        [imind,cm] = rgb2ind(im,256); 
        %Write to the GIF File 
        if j == 1 
          imwrite(imind,cm,filename,'gif', 'DelayTime', time_delay, 'Loopcount',inf); 
        else 
          imwrite(imind,cm,filename,'gif','DelayTime', time_delay, 'WriteMode','append'); 
        end 
    end
end

%inverse kinematics for arbitrary cartesian path 
if 1
     length = sum(robot.a);
     a = -pi/2;
     b = pi/2;
     cartesian_init = (b-a).*rand(6,1)' + a;
     cartesian_final = (b-a).*rand(6,1)' + a;
     cartesian_init(1:3) = [0,0,length/3];
     cartesian_final(1:3) = [0,length/3,0];
 
     cartesian_ts = []
     for i = 1:6
         cartesian_ts(:,i) = linspace(cartesian_init(i), cartesian_final(i), 100);
     end
    
    goals = SE3(cartesian_ts(:,1:3));
    goalsSaved = goals;
    for i = 1:size(goals,2)
        goals(i)=goalsSaved(i)*SE3.eul(cartesian_ts(i,4:6));
    end

    q_ts_inv = []

    q_ts_inv = robot.ikunc(goals.T);
    robot.plot(q_ts_inv);

    %generate and save gif of robot
    h = gcf;
    robot.plot(zeros(1,robot.n));
    filename = 'cartesian_ikine.gif';
    for j = 1:(size(q_ts_inv,1))
        robot.plot(q_ts_inv(j,:))

        %Capture the plot as an image 
        frame = getframe(h); 
        im = frame2im(frame); 
        [imind,cm] = rgb2ind(im,256); 
        %Write to the GIF File 
        if j == 1 
          imwrite(imind,cm,filename,'gif', 'DelayTime', time_delay, 'Loopcount',inf); 
        else 
          imwrite(imind,cm,filename,'gif','DelayTime', time_delay, 'WriteMode','append'); 
        end 
    end
end

%inverse kinematics for arbitrary cartesian path, joint constraints
if 1
     length = sum(robot.a);
     a = -pi/2;
     b = pi/2;
     cartesian_init = (b-a).*rand(6,1)' + a;
     cartesian_final = (b-a).*rand(6,1)' + a;
     cartesian_init(1:3) = [0,0,length/3];
     cartesian_final(1:3) = [0,length/3,0];
 
     cartesian_ts = []
     for i = 1:6
         cartesian_ts(:,i) = linspace(cartesian_init(i), cartesian_final(i), 100);
     end
    
    goals = SE3(cartesian_ts(:,1:3));
    goalsSaved = goals;
    for i = 1:size(goals,2)
        goals(i)=goalsSaved(i)*SE3.eul(cartesian_ts(i,4:6));
    end

    q_ts_inv = []

    q_ts_inv = robot.ikcon(goals.T);
    robot.plot(q_ts_inv);

    %generate and save gif of robot
    h = gcf;
    robot.plot(zeros(1,robot.n));
    filename = 'cartesian_ikine.gif';
    for j = 1:(size(q_ts_inv,1))
        robot.plot(q_ts_inv(j,:))

        %Capture the plot as an image 
        frame = getframe(h); 
        im = frame2im(frame); 
        [imind,cm] = rgb2ind(im,256); 
        %Write to the GIF File 
        if j == 1 
          imwrite(imind,cm,filename,'gif', 'DelayTime', time_delay, 'Loopcount',inf); 
        else 
          imwrite(imind,cm,filename,'gif','DelayTime', time_delay, 'WriteMode','append'); 
        end 
    end
end