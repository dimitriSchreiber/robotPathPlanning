#Motor arm mixing, accounts for coupling in motion of each degree of freedom
#Wants radians and mm?
import numpy as np
import transforms3d as t3d
#from forwardKinematics import *

pi = np.pi


class remoteRobotArm():
    #This class defines a robot arm controller, providing robot end effector position control
    #Inputs:
    #    Current robot position/orientation in cartesian/quaternion
    #    Robot end-effector setpoint position/orientation in cartesian/quaternion

    #Outputs:
    #    Motor angles


    def __init__(self):
        self.jointAngleCurrent = np.zeros(7) #read from joint encoders, N/A for now
        self.jointAngleSetpoint = np.zeros(7) #N/A
        self.jointAngleError = np.zeros(7) #N/A
        self.motorAngleSetpoint = np.zeros(7) #Motor angle commands given mixing matrix

        self.robotJacobian = np.zeros((7,6)) #from forwardKinematics.py
        
        self.endEffectorCurrent = np.zeros((2,3)) #fromOptitrack
        self.endEffectorSetpoint = np.zeros((2,3)) #input
        self.endEffectorError = np.zeros((2,3))
        self.jointUpperLimits = np.array([1000,1000,5,0.872,0.872,0.872,50])
        self.jointLowerLimits = np.array([0,0,-5,-0.872,-0.872,-0.872,0])
        
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
        Db = 12.7 #drive pulley diameter
        Ds = 10 #small pulley
        Dm = 16    #medium pulley
        Dl = 22    #large pulley
        Dj1 = 28 #joint 1 terminating pulley
        Dj2 = 28    #joint 2 terminating pulley
        Dj3 = 16    #joint 3 terminating pulley

        #motorTheta_armTheta = np.eye(4) * np.array([Db/Dj1, Db/Dj2, Db/Dj3, Db])
        #motorTheta_armTheta = np.dot(np.array([[1, 0, 0, 0],
        #                                       [Dl/Dj2, 1, 0, 0],
        #                                       [0, 0, 1, 0], 
        #                                       [0, 0, 0, 1]]), motorTheta_armTheta)
        #motorTheta_armTheta = np.dot(np.array([[1, 0, 0, 0], 
        #                                       [0, 1, 0, 0], 
        #                                       [Dm/Dj3, -Dm/Dj3, 1, 0], 
        #                                       [0, 0, 0, 1]]), motorTheta_armTheta)
        #motorTheta_armTheta = np.dot(np.array([[1, 0, 0, 0], 
        #                                       [0, 1, 0, 0], 
        #                                       [0, 0, 1, 0], 
        #                                       [-Ds, Ds, Dl, 1]]), motorTheta_armTheta) #divided last row by 2!!!!, if issues try removing this first
        D = np.array([[Dj1,0,0,0],
                      [-Dl,Dj2,0,0],
                      [Dm,-Dl,Dj3,0],
                      [Ds,-Dm,-Dl,1]]) #this needs to be finished!!
        a1 = np.eye(4)*np.array([Db/D[0,0], 1, 1, 1])
        a2 = np.array([[1,0,0,0],
                     [D[1,0]/D[1,1], Db/D[1,1], 0, 0],
                     [0, 0, 1, 0],
                     [0, 0, 0, 1]])
        a3 = np.array([[1,0,0,0],
                     [0, 1, 0, 0],
                     [D[2,0]/D[2,2], D[2,1]/D[2,2], Db/D[2,2], 0],
                     [0, 0, 0, 1]])
        a4 = np.array([[1,0,0,0],
                     [0, 1, 0, 0],
                     [0, 0, 1, 0],
                     [D[3,0]/(2), D[3,1]/(2), D[3,2]/(2), Db/(2)]])
        
        motorTheta_armTheta = a4 @ (a3 @ (a2 @ a1))
        
        self.motorTheta_armTheta_full[3:, 3:] = motorTheta_armTheta
        self.armTheta_motorTheta = np.linalg.inv(self.motorTheta_armTheta_full) #is a 4x4 submatrix for 4dof arm

    def updateMotorArmMixing(self):
        temp = np.clip(self.jointAngleSetpoint, self.jointLowerLimits, self.jointUpperLimits)
        if (temp != self.jointAngleSetpoint).any():
            bad=True
            #print("warning! commanded joint angle is out of robot limits")
        self.jointAngleSetpoint = temp   
        self.motorAngleSetpoint = self.armTheta_motorTheta @ self.jointAngleSetpoint #takes in arm thetas and gives appropriate motor thetas
    def commandJoints(self, motors, setpoint_arm, trajectory = True):
        setpoint_arm[3] = -1 * setpoint_arm[3]
        setpoint_arm[4] = 1 * setpoint_arm[4]
        setpoint_arm[5] = -1 * setpoint_arm[5]

        self.jointAngleSetpoint = setpoint_arm
        self.updateMotorArmMixing()
        
        axis_motor_indexes = np.array([-1, -1, -1, 0, 3, 2, 1])
        velocity = np.ones(8)*3.14/20
        
        setpoint_motor = np.zeros(8)
        setpoint_motor[axis_motor_indexes[3:7]] = self.motorAngleSetpoint[3:7]

        if trajectory:
            motors.run_trajectory(setpoint_motor, velocity)
        else:
            motors.command_motors_radians(setpoint_motor)


    def updateRobotEECurrent(self):
        pass
    def updateRobotJacobian(self):
        pass
    def zeroRobot(self):
        pass
