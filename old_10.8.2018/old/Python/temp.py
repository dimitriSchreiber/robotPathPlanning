# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
#http://alexanderfabisch.github.io/pybullet.html
#C:\Users\snowl\Google Drive\Documents\Research\ARCLAB Arm_\CAD\active\full_arm\arm\subarms\multi.SLDASM\urdf\multi.SLDASM.urdf

import pybullet as p
import pybullet_data
import os
import sys
import numpy as np
import time
# robot_path = r"C:\Users\snowl\Google Drive\Documents\Research\ARCLAB Arm_\CAD\active\full_arm\arm\subarms\output\urdf\output.urdf"
# robot_path2 = r"C:\Users\snowl\Google Drive\Documents\Research\ARCLAB Arm_\CAD\active\full_arm\arm\subarms\multi.SLDASM\urdf\multi.SLDASM.urdf"
# robot_path3 = r"C:\Users\snowl\Google Drive\Documents\Research\ARCLAB Arm_\CAD\active\full_arm\arm\subarms\asdf\urdf\multi.SLDASM.urdf"

cwd = os.getcwd()

robot_path4 = cwd + '/mri/urdf/mri.urdf'

cid = p.connect(p.SHARED_MEMORY)
if (cid<0):
	p.connect(p.GUI)
    
p.setAdditionalSearchPath(pybullet_data.getDataPath())
p.resetSimulation()

StartPos = [0,0,1]
StartOrientation = p.getQuaternionFromEuler([0,0,0])

temp = p.loadURDF(robot_path4, StartPos, StartOrientation, useFixedBase = 1)
position, orientation = p.getBasePositionAndOrientation(temp) #(x,y,z,w) in quaternions
num_joints = p.getNumJoints(temp)

#gets information about joint number 2
joint_index = 2
_, name, joint_type, _, _, _, _, _, lower_limit, upper_limit, _, _, _ ,_,_,_,_= \
    p.getJointInfo(temp, joint_index)
name, joint_type, lower_limit, upper_limit


#gets position of all joints
joint_positions = [j[0] for j in p.getJointStates(temp, range(num_joints))]
joint_positions


#get world position of joints
#world_position, world_orientation = p.getLinkState(temp, 2)[:2]
#world_position

p.setGravity(0, 0, -9.81)   # everything should fall down
p.setTimeStep(0.0001)       # this slows everything down, but let's be accurate...
p.setRealTimeSimulation(0)  # we want to be faster than real time :)
    
#p.setJointMotorControlArray(
#    temp, range(num_joints), p.POSITION_CONTROL,
#    targetPositions=[1] * num_joints)
p.setJointMotorControl2(temp, 0,
     controlMode=p.POSITION_CONTROL, targetPosition = 2)

jointPositions = np.linspace(0,2, num = 100)
for i in range(10000):
    p.setJointMotorControl2(bodyUniqueId = temp, jointIndex = 0, 
                            controlMode = p.POSITION_CONTROL,
                            targetPosition = jointPositions[i])
    p.setJointMotorControl2(bodyUniqueId = temp, jointIndex = 1, 
                            controlMode = p.POSITION_CONTROL,
                            targetPosition = jointPositions[i])
    p.setJointMotorControl2(bodyUniqueId = temp, jointIndex = 2, 
                            controlMode = p.POSITION_CONTROL,
                            targetPosition = jointPositions[i])
    p.setJointMotorControl2(bodyUniqueId = temp, jointIndex = 3, 
                            controlMode = p.POSITION_CONTROL,
                            targetPosition = jointPositions[i])
    p.stepSimulation()
    time.sleep(0.05)
#p.disconnect()

