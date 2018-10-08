%joint_pos is a NxM matrix, N setpoints, M joint angles
%goal is a NX3x3 homogeneous matrix (X,Y,Z,roll,pitch,yaw)
%uses fmincon for constrained optimization

function joint_positions = inverse_kinematics_fmincon(robot, goal, start)
    global robot_global, global reach, global omega, global goal_global;
    reach = sum(abs([robot.a, robot.d]));
    omega = diag([1 1 1 3/reach]);
    robot_global = robot;
    %first try basic constrained basic, then fancy

    %x  columns is num joints
    %robot.fkine(x) = goal * A --> goal \ robot.fkine(x) = A, minimum norm
    %solution, same transformation either way but why eye(4)?
    problem.lb = robot.qlim(:,1);
    problem.ub = robot.qlim(:,2);
    problem.objective = @(x) cond(jacob0(robot, x));
    problem.nonlcon = @ikine_nonlcon;
    
    %why did they only use one row???
    %J0 = jacob0(robot, x);
    %J0 = J0(m, :);
    %if cond(J0) > 100
    joint_positions = zeros(size(goal,3),robot.n);
    
    for i = 1:size(goal,3)
        i
        goal_global = goal(:,:,i);

        if i>1
            problem.x0 = joint_positions(i-1,:)
            problem.objective = @(x) cond(jacob0(robot, x)); %+ (sumsqr(x-joint_positions(i-1,:))*5)^2;
        
        elseif exist('start')
            problem.x0 = start;
        else
            problem.x0 = zeros(1, robot.n);
        end

        problem.solver = 'fmincon';
        problem.options = optimoptions('fmincon', ...
            'Algorithm', 'active-set', ...
            'Display', 'off'); % default options for ikcon

        joint_positions(i,:) = fmincon(problem);
        cond(jacob0(robot, joint_positions(i,:)))
    end
end