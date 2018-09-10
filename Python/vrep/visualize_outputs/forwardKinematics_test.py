from forwardKinematics import robot_config
import numpy as np
import time
pi = np.pi
#q = [-pi/2, pi/2, -pi/2, 20]
q = np.array([0., 0., 0., 0.])

myRobot = robot_config()

print("Joint angles/positions {}".format(q))

# calculate position of the end-effector
#xyz = myRobot.Tx('EE', q)
#print('XYZ forward kin: {}'.format(xyz))
#print(xyz.shape)
#print(type(xyz))
# calculate the Jacobian for the end effector
s = time.time()
for i in range(1000):
	JEE = myRobot.J('j4', q)
dt = time.time()-s
print(dt/1000)
print("analytic jacobian: \n{}".format(JEE))

def calculateJacobian(q, num_joints = 4, dx = 1e-5):
	jacobian = np.zeros((6,num_joints))
	for i in range(num_joints):
		q_plus = q.copy()
		q_plus[i] += dx
		q_minus = q.copy()
		q_minus[i] -= dx
		x_plus = myRobot.Tx('EE', q_plus)
		x_minus = myRobot.Tx('EE', q_minus)
		jacobian[:3, i] = (x_plus - x_minus) / (2*dx)

		qEE_plus = myRobot.Te('EE', q_plus)
		qEE_minus = myRobot.Te('EE', q_minus)
		jacobian[3:, i] = (qEE_plus - qEE_minus) / (2*dx)

	return jacobian

s = time.time()
for i in range(1000):
	JEE_numerical = calculateJacobian(q)
dt = time.time()-s
print(dt/1000)
print("numeric jacobian: \n{}".format(JEE_numerical))


s = time.time()
for i in range(1000):
	positions = myRobot.forwardKinPos(q)
dt = time.time()-s
print(dt/1000)
print(positions)

#J_orientation = myRobot._calc_T('j1', lambdify = True)
#print(J_orientation(*tuple(q)))

s = time.time()
for i in range(1000):
	orientation = myRobot.forwardKinOrientation(q)
dt = time.time()-s
print(dt/1000)
print(orientation)

