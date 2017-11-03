function [c,ceq]=ikine_nonlcon(x)
c(1) = sumsqr((goal \ robot.fkine(x) - eye(4))*omega) - 0.1;;
ceq = [];
end