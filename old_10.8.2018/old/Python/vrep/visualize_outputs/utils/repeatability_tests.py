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
from generate_trajectory import trajectoryGenerator

#---------------------------------------------
#constants
#---------------------------------------------
PI = np.pi
NUM_TESTS = 1
#TCP addresses
socket_ip = '192.168.1.39'
socket_port = 1122

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

P=0.5#5#0.1#2.3
PL=0#0.2
I=1#0.1
IL = 0#0.01
D = 0

joint_motor_indexes = [0,1,2,3] #which motors are used to control the arm in order of joints

MC = MotorControl(P, PL ,I, IL, D,joint_motor_indexes)
MC.tcp_init(socket_ip, socket_port)
MC.motor_init()

print("Arming motors now...")
MC.motors.arm()
time.sleep(2)

#SET target angles/position here
arm_angles_deg = np.array((-15,5,5, 0)) 
arm_angles_rads = degs2rads(arm_angles_deg) #rads, rads, rads, meters for q

EE_position_fk = myRobot.Tx('EE', arm_angles_rads) * 10 # is the scaling facto rfor units
EE_orientation_fk = myRobot.Te('EE', arm_angles_rads)
print("Forward kin orientation", EE_orientation_fk)
print("Forward kin end effector position {} for joint values (euler and meters){}".format(EE_position_fk, arm_angles_deg))
time.sleep(1)

#Data stoarage lists
traverse_data = []
final_data = []
final_traverse_data = []
two_norm_data_pos = []
two_norm_data_orientation = []
two_norm_data_both = []
norms = []
time_list = []
optitrak_list = []

trajPlanner = trajectoryGenerator()

for i in range(NUM_TESTS):

	#---------------------------------------------
	#Zeros the arm to home position
	#---------------------------------------------
	print("Zeroing arm")
	MC.zero_arm(track_data, NatNet)
	print("Done Zeroing")
	time.sleep(0.5)

	counter = 0

	track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
	j2b_euler, j3j2_euler, j4j3_pos,  = getOptitrakControl(track_data)
	q_optitrak = np.array([j2b_euler[0], j2b_euler[1], j3j2_euler[1], j4j3_pos[2]]) #current angles in euler RADIANS
	base_inv = track_data.bodies[0].homg_inv
	joint4 = track_data.bodies[3].homogenous_mat
	_, EE_position_optitrak, EE_orientation_optitrak, _ = track_data.homg_mat_mult(base_inv,joint4)

	#---------------------------------------------
	#Set all joint angles to desired positions
	#---------------------------------------------

	#FLorians stuff
	period = 1.0/50.0 # 20 Hz
	rates = np.array([PI/180, PI/180, PI/180, 0.1])*0.5
	trajectories, tracjectory_time = trajPlanner.creatTrajectoryMaxVelocity(q_optitrak, arm_angles_rads, rates, period)


	#trajPlanner.plotTrajectory(trajectories, tracjectory_time)


	for j in range(0, trajectories.shape[0]):
		maxVel = 0
		for i in range(1, trajectories.shape[1]):
			vel = (trajectories[j,i] - trajectories[j,i-1])/(tracjectory_time[i] - tracjectory_time[i-1])
			if abs(vel) > abs(maxVel):
				maxVel = vel

		print("Computed max velocity: {}".format(maxVel))

	start_time = time.time()

	time_diff = 0
	old_time= time.time()

	while np.amax(np.abs(arm_angles_deg - rads2degs(q_optitrak))) > 0.5 and (time_diff) < 2 * tracjectory_time[-1]: #looking at difference in DEGREES

		#---------------------------------------------
		#get Optitrak data, 4ms block
		#---------------------------------------------

		if time.time() - old_time > 0.5:
			print("total trajectory time: {}, current trajectory time: {}".format(tracjectory_time[-1], time_diff))
			old_time = time.time()

		track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used

		#For getting end effector position from optitrak -> check the units of this
		base_inv = track_data.bodies[0].homg_inv
		joint4 = track_data.bodies[3].homogenous_mat
		_, EE_position_optitrak, EE_orientation_optitrak, _ = track_data.homg_mat_mult(base_inv,joint4) #joint4 in base frame


		#For getting joint angles from optitrak
		j2b_euler, j3j2_euler, j4j3_pos,  = getOptitrakControl(track_data)
		q_optitrak = np.array([j2b_euler[0], j2b_euler[1], j3j2_euler[1], j4j3_pos[2]]) #euler

		#MC.update(q_optitrak, arm_angles_rads, print_data = True) #make sure values are in rads and mm?
		time_diff = time.time() - start_time
		index = np.argmin(np.abs(tracjectory_time - time_diff))
		traj_arm_angles = np.array((trajectories[0,index], trajectories[1,index], trajectories[2,index], trajectories[3,index]))

		MC.update(q_optitrak, traj_arm_angles, print_data = True)
		traverse_data.append([rads2degs(q_optitrak), EE_position_optitrak, EE_orientation_optitrak]) #EE_position_optitrak is meters 

		#two norm over single run
		two_norm_data_pos.append(np.linalg.norm(EE_position_optitrak - EE_position_fk))
		# print(EE_position_optitrak)
		# print(EE_position_fk)
		# print(np.linalg.norm(EE_position_optitrak - EE_position_fk))

		two_norm_data_orientation.append(np.linalg.norm(EE_orientation_optitrak - EE_orientation_fk)) #FIX LATER
		# print(EE_orientation_optitrak)
		# print(EE_orientation_fk)
		# print(np.linalg.norm(EE_orientation_optitrak - EE_orientation_fk))

		both = np.concatenate((EE_position_optitrak - EE_position_fk, EE_orientation_optitrak - EE_orientation_fk), axis = None)
		# print(np.concatenate((EE_position_optitrak,EE_position_fk), axis = None))
		# print(both)
		two_norm_data_both.append(np.linalg.norm(both))

		counter = counter + 1
		#print("ERROR VALUEs", (arm_angles_deg - rads2degs(q_optitrak)))

		time_list.append(time_diff)
		optitrak_list.append(EE_position_optitrak)

		time.sleep(0.01)

	final_traverse_data.append(traverse_data)
	#Getting open end effector stats for repeatability
	final_data.append([rads2degs(q_optitrak), [EE_position_optitrak, EE_orientation_optitrak], [EE_position_fk, EE_orientation_fk]])
	#Accuracy stats, 2 norm of xyz components compared to FK, and 2 norm of RPY components compared to FK

	norms.append([two_norm_data_pos, two_norm_data_orientation, two_norm_data_both])

	time.sleep(0.5)

	MC.update(np.array([0,0,0,0]), np.array([0,0,0,0]), print_data = True)

#Repeatability
EE_xs_trak = []
EE_ys_trak = []
EE_zs_trak = []
EE_roll_trak = []
EE_pitch_trak = []
EE_yaw_trak = []


for data in final_data:
	EE_xs_trak.append(data[1][0][0])
	EE_ys_trak.append(data[1][0][1])
	EE_zs_trak.append(data[1][0][2])
	EE_roll_trak.append(data[1][1][0])
	EE_pitch_trak.append(data[1][1][1])
	EE_yaw_trak.append(data[1][1][2])

EE_stats = [[np.mean(EE_xs_trak), np.var(EE_xs_trak)],
					[np.mean(EE_ys_trak), np.var(EE_ys_trak)],
					[np.mean(EE_zs_trak), np.var(EE_zs_trak)],
					[np.mean(EE_roll_trak), np.var(EE_roll_trak)],
					[np.mean(EE_pitch_trak), np.var(EE_pitch_trak)],
					[np.mean(EE_yaw_trak), np.var(EE_yaw_trak)]]

print(EE_stats)

#Accuracy
plt.subplot(1,3,1) #position and orientation
plt.plot(norms[0][0])
plt.subplot(1,3,2)
plt.plot(norms[0][1])
plt.subplot(1,3,3)
plt.plot(norms[0][2])
plt.savefig('norm_data.png')
plt.show()


#Double check...
plt.figure()
for i in range(3):
	plt.subplot(1,3,i+1)
	plt.plot(1000*np.array(optitrak_list)[:,i], 'g')
	plt.plot(1000*np.ones(len(optitrak_list))*EE_position_fk[i], 'r')
plt.show()







#Plotting last run
j1=[]
j2=[]
j3=[]
j4=[]
EE_x=[]
EE_y=[]
EE_z=[]

for data in traverse_data:
	j1.append(data[0][0])
	j2.append(data[0][1])
	j3.append(data[0][2])
	j4.append(data[0][3])
	EE_x.append(data[1][0])
	EE_y.append(data[1][1])
	EE_z.append(data[1][2])


print("plotting")
print(arm_angles_deg)
time.sleep(1)
plt.subplot(2,2,1)
plt.plot(time_list, j1)
plt.plot(tracjectory_time, trajectories[0,:] * 180 / np.pi)
plt.subplot(2,2,2)
plt.plot(time_list, j2)
plt.plot(tracjectory_time, trajectories[1,:] * 180 / np.pi)
plt.subplot(2,2,3)
plt.plot(time_list, j3)
plt.plot(tracjectory_time, trajectories[2,:] * 180 / np.pi)
plt.subplot(2,2,4)
plt.plot(time_list, j4)
plt.plot(tracjectory_time, trajectories[3,:] * 1000)
plt.title("this is what we want!")
plt.savefig('traverse_data_plot.png')
plt.show()


#---------------------------------------------
#storing data
#---------------------------------------------
with open("repeatability_test.txt", "wb") as fp:
	pickle.dump([final_traverse_data, final_data, EE_stats], fp)

"""
To get data back from pickle
with open("repeatability_test.txt", "rb") as fp:
	data = pickle.load(fp)

traverse_data = data[0] #list of lists for each run
final_data = data[1] #list of lists for each run
EE_optitrak_runs = final_data[which_run][1]
EE_fk_runs = final_data[which_run][2]

"""




#---------------------------------------------
#Cleanup
#---------------------------------------------
print("Clean up")
MC.tcp_close()
streamingClient.stop()