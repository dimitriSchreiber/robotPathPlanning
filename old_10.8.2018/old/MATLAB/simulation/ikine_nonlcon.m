function [c,ceq]=ikine_nonlcon(x)
global goal_global, global robot_global, global omega
c = [];
ceq = sumsqr((goal_global \ robot_global.fkine(x) - eye(4))*omega);
end