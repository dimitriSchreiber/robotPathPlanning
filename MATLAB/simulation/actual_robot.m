addpath ../mexTests/
clear;
close all;
warning on;

figure('Position', [142 119 595 540]);
set(gcf, 'color', 'w');

numLinks = 8;
numRotaryRepeated = 4;

L1 = Prismatic('a', 5, 'alpha', pi/2, 'qlim', [0, 28]);
L2 = Prismatic('a', 5, 'alpha', pi/2,'theta', pi/2, 'qlim', [0, 28]);
L3 = Prismatic('a', 5, 'alpha', 0, 'theta', pi/2,'qlim', [0, 28]);
L4 =  Revolute('a', 0, 'alpha', pi/2, 'd', 15, 'qlim', [-pi, pi]);
L5 = Revolute('a', 7.62, 'alpha', pi/2, 'd', 0, 'qlim', [pi/2-3*pi/8, pi/2+3*pi/8])
L6_8 = repmat(Revolute('a', 7.62, 'alpha', 1.5708, 'd', 0.8, 'qlim', [-3*pi/8, 3*pi/8]), numRotaryRepeated-1, 1);
robot = SerialLink( [L1,L2,L3,L4,L5,L6_8],  'name', 'my robot')
robot.base = robot.base * trotx(3*pi/2)

time_delay = 0.05;

robot.plotopt = {'perspective',  'jointdiam', 1, 'jointscale', 1, 'scale', 0.5 'jointcolor', 0.3*[1 1 1], ...
    'noshadow', 'workspace', [-50,100,-50,100,-50,100], 'delay', time_delay};

%robot.plot([20,20,20,pi/2,pi/3,pi/3,pi/3,pi/3]);
robot.plot([10, 10, 10, 0, pi/2, 0, 0, 0]);
%robot.teach
reachableRadius = sum(robot.a);
axLim = reachableRadius/1.2*[-1 1 -1 1 -1 1];


%forward kinematics test plot
if 0
    a1 = -pi/2;
    b1 = pi/2;
    q_init = (b1-a1).*rand(numLinks,1)' + a1;
    q_final = (b1-a1).*rand(numLinks,1)' + a1;
    a2 = 0;
    b2 = 10;
    q_init(1:3) = (b2-a2).*rand(3,1)' + a2
    q_final(1:3) = (b2-a2).*rand(3,1)' + a2
    q_ts = []
    for i = 1:numLinks
        q_ts(:,i) = linspace(q_init(i), q_final(i), 100);
    end
    robot.plot(q_ts);
    TE = robot.fkine(q_ts);
end

%inverse kinematics test plot of above forward pass
if 0
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

%inverse kinematics for arbitrary cartesian path, joint constraints
if 1
     length = sum(robot.a);
     %a = -pi/2;
     %b = pi/2;
     %cartesian_init = (b-a).*rand(6,1)' + a;
     %cartesian_final = (b-a).*rand(6,1)' + a;
     cartesian_init(1:3) = [length/2,0,0];
     cartesian_init(4:6) = [0,0,0];
     cartesian_final(1:3) = [length/1,0,0];
     cartesian_final(4:6) = [0,0,0];
     
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
    
    
    q_ts_inv=inverse_kinematics_fmincon(robot, goals.T);
    %q_ts_inv = robot.ikcon(goals.T);
    robot.plot(q_ts_inv);

    if 0
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
end

