#Motor arm mixing, accounts for coupling in motion of each degree of freedom
#Wants radians and mm?
import numpy as np
import transforms3d as t3d
from forwardKinematics import *

pi = np.pi

class remoteRobotArm():
	#This class defines a robot arm controller, providing robot end effector position control
	#Inputs:
	#	Current robot position/orientation in cartesian/quaternion
	#	Robot end-effector setpoint position/orientation in cartesian/quaternion

	#Outputs:
	#	Motor angles


	def __init__(self):
		self.jointAngleCurrent = np.zeros(7) #read from joint encoders, N/A for now
		self.jointAngleSetpoint = np.zeros(7) #N/A
		self.jointAngledError = np.zeros(7) #N/A
		self.motorAngleSetpoint = np.zeros(7) #Motor angle commands given mixing matrix

		self.robotJacobian = np.zeros((7,6)) #from forwardKinematics.py
		
		self.endEffectorCurrent = np.zeros((2,3)) #fromOptitrack
		self.endEffectorSetpoint = np.zeros((2,3)) #input
		self.endEffectorError = np.zeros((2,3))

		self.initMotorArmMixing()

	def initMotorArmMixing(self): 
		#armTheta is a 7x1 for desired joint angles
		#linear motions are in ?meters?, DOUBLE CHECK THESE!!!d
		#rotary motions are in radians
		self.motorTheta_armTheta_full = np.zeros((7,7))


		#linear motions are very questionable right now and NEED TO BE REVIEWED!

		#backend mixing matrix;
		X_Y_pulley = 25 * 2  / (2 * pi)#linear motion (mm) per radian
		rotaryAxis_pulley = 50 / 25 #ratio for rotary axis

		self.motorTheta_armTheta_full[0,0] = X_Y_pulley
		self.motorTheta_armTheta_full[1,1] = X_Y_pulley
		self.motorTheta_armTheta_full[2,2] = rotaryAxis_pulley


		#cable driven arm mixing matrix:
		#Pulley diameters (mm)
		Db = 16.5 #drive pulley diameter
		Ds = 8.72 #small pulley
		Dm = 13.88	#medium pulley
		Dl = 18	#large pulley
		Dj1 = 21 #joint 1 terminating pulley
		Dj2 = 21.5	#joint 2 terminating pulley
		Dj3 = 13.5	#joint 3 terminating pulley

		motorTheta_armTheta = np.eye(4) * np.array([Db/Dj1, Db/Dj2, Db/Dj3, Db])
		motorTheta_armTheta = np.dot(np.array([[1, 0, 0, 0],
											   [Dl/Dj2, 1, 0, 0],
											   [0, 0, 1, 0], 
											   [0, 0, 0, 1]]), motorTheta_armTheta)
		motorTheta_armTheta = np.dot(np.array([[1, 0, 0, 0], 
											   [0, 1, 0, 0], 
											   [Dm/Dj3, -Dm/Dj3, 1, 0], 
											   [0, 0, 0, 1]]), motorTheta_armTheta)
		motorTheta_armTheta = np.dot(np.array([[1, 0, 0, 0], 
											   [0, 1, 0, 0], 
											   [0, 0, 1, 0], 
											   [-Ds/2, Ds/2, Dl/2, 1/2]]), motorTheta_armTheta) #divided last row by 2!!!!, if issues try removing this first

		self.motorTheta_armTheta_full[3:, 3:] = motorTheta_armTheta
		self.armTheta_motorTheta = np.linalg.inv(self.motorTheta_armTheta_full) #is a 4x4 submatrix for 4dof arm

	def updateMotorArmMixing(self):
		self.motorAngleSetpoint = np.dot(self.armTheta_motorTheta, self.jointAngleSetpoint) #takes in arm thetas and gives appropriate motor thetas

	def updateRobotEECurrent(self):
		pass
	def updateRobotJacobian(self):
		pass
	def zeroRobot(self):
		pass
