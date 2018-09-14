#---------------------------------------------
#vrep imports
#---------------------------------------------
import numpy as np
import vrep
from forwardKinematics import robot_config
import time
import os
import pickle
import socket
import matplotlib.pyplot as plt
from copy import deepcopy
from getRobotPose import *
#---------------------------------------------
#motor imports
#---------------------------------------------
from motor_class import motors
from tcp_class import tcp_communication

#---------------------------------------------
#optitrak imports
#---------------------------------------------
import signal
import sys
import transforms3d as t3d
from copy import deepcopy
from GetJointData import data, NatNetFuncs#receiveNewFrame, receiveRigidBodyFrameList
from NatNetClient2 import NatNetClient
from AngleControl import MotorControl

#---------------------------------------------
#constants
#---------------------------------------------
PI = np.pi
NUM_TESTS = 1
#TCP addresses
socket_ip = '192.168.1.39'
socket_port = 1123

#---------------------------------------------
#optitrak setup
#---------------------------------------------
server_ip = "192.168.1.27"
multicastAddress = "239.255.42.99"
print_trak_data = False
optitrack_joint_names = ['base', 'j2', 'j3', 'j4', 'target']
ids = [0, 1, 2, 3, 4]

#Tracking class
print("Starting streaming client now...")
streamingClient = NatNetClient(server_ip, multicastAddress, verbose = print_trak_data)
NatNet = NatNetFuncs()
streamingClient.newFrameListener = NatNet.receiveNewFrame
streamingClient.rigidBodyListListener = NatNet.receiveRigidBodyFrameList

prev_frame = 0
time.sleep(0.5)
streamingClient.run()
time.sleep(0.5)
track_data = data(optitrack_joint_names,ids)
track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
old_frame = track_data.frame

#---------------------------------------------
#Helper functions
#---------------------------------------------
def rads2degs(radians):
	degrees = np.append(radians[0:-1] * 180/PI, radians[-1])
	return degrees

def degs2rads(degrees):
	radians = np.append(degrees[0:-1] * PI/180, degrees[-1])
	return radians

#---------------------------------------------
#robot kinematics, jacobian class
#---------------------------------------------
myRobot = robot_config()

#---------------------------------------------
#vrep setup
#---------------------------------------------
pose_names = ['pose_origin', 'pose_j1', 'pose_j2', 'pose_j3', 'pose_j4']
robot_pose_names = ['robot_origin', 'robot_j1', 'robot_j2', 'robot_j3', 'robot_j4', 'target']
n_poses = len(pose_names)

P=0.5
PL=0.2
I=0.05
IL = 0.01
D = 0

joint_motor_indexes = [0,1,2,3] #which motors are used to control the arm in order of joints

MC = MotorControl(P, PL ,I, IL, D,joint_motor_indexes, control_freq = 20)
MC.tcp_init(socket_ip, socket_port)
MC.motor_init()

print("Arming motors now...")
MC.motors.arm()
time.sleep(2)

#SET target angles/position here
arm_angles_deg = np.array((5,15,20, 0)) 
arm_angles_rads = degs2rads(arm_angles_deg) #rads, rads, rads, meters for q

EE_position_fk = myRobot.Tx('EE', arm_angles_rads) * 10 # is the scaling factor for units
print("Forward kin end effector position {} for joint values (euler and meters){}".format(EE_position_fk, arm_angles_deg))
time.sleep(1)

track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
j2b_euler, j3j2_euler, j4j3_pos,  = getOptitrakControl(track_data)
q_optitrak = np.array([j2b_euler[0], j2b_euler[1], j3j2_euler[1], j4j3_pos[2]]) #current angles in euler RADIANS
base_inv = track_data.bodies[0].homg_inv
joint4 = track_data.bodies[3].homogenous_mat
_, EE_position_optitrak, _, _ = track_data.homg_mat_mult(base_inv,joint4)

#Data stoarage lists
traverse_data = []
final_data = []

for i in range(NUM_TESTS):

	#---------------------------------------------
	#Zeros the arm to home position
	#---------------------------------------------
	print("Zeroing arm")
	MC.zero_arm(track_data, NatNet)
	print("Done Zeroing")
	time.sleep(0.5)

	counter = 0

	#---------------------------------------------
	#Set all joint angles to desired positions
	#---------------------------------------------
	while np.amax(np.abs(arm_angles_deg - rads2degs(q_optitrak))) > 0.5: #looking at difference in DEGREES

		#---------------------------------------------
		#get Optitrak data, 4ms block
		#---------------------------------------------
		track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used

		#For getting end effector position from optitrak -> check the units of this
		base_inv = track_data.bodies[0].homg_inv
		joint4 = track_data.bodies[3].homogenous_mat
		_, EE_position_optitrak, _, _ = track_data.homg_mat_mult(base_inv,joint4) #joint4 in base frame

		#For getting joint angles from optitrak
		j2b_euler, j3j2_euler, j4j3_pos,  = getOptitrakControl(track_data)
		q_optitrak = np.array([j2b_euler[0], j2b_euler[1], j3j2_euler[1], j4j3_pos[2]]) #euler
		MC.update(q_optitrak, arm_angles_rads, print_data = True) #make sure values are in rads and mm?

		traverse_data.append([rads2degs(q_optitrak), EE_position_optitrak]) #EE_position_optitrak is meters 

		#if counter % 100 == 0:
		#	print("Angle setpoints are {}\n Current angles are {}\n FK EE {}\n Current EE {}\n".format(arm_angles_deg, q_optitrak, EE_position_fk, EE_position_optitrak))

		counter = counter + 1
		#print("ERROR VALUEs", (arm_angles_deg - rads2degs(q_optitrak)))

		time.sleep(0.01)

	final_data.append([rads2degs(q_optitrak), EE_position_optitrak, EE_position_fk])


#---------------------------------------------
#storing the 2 lists
#---------------------------------------------
with open("repeatability_test.txt", "wb") as fp:
		pickle.dump([traverse_data, final_data], fp)

j1=[]
j2=[]
j3=[]
j4=[]
for data in traverse_data:
	j1.append(data[0][0])
	j2.append(data[0][1])
	j3.append(data[0][2])
	j4.append(data[0][3])

print("plotting")
time.sleep(1)
plt.subplot(2,2,1)
plt.plot(j1)
plt.subplot(2,2,2)
plt.plot(j2)
plt.subplot(2,2,3)
plt.plot(j3)
plt.subplot(2,2,4)
plt.plot(j4)
plt.show()
plt.savefig('traverse_data_plot.png')

#---------------------------------------------
#Cleanup
#---------------------------------------------
print("Clean up")
MC.tcp_close()
streamingClient.stop()