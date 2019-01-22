import signal
import sys
import transforms3d as tf3d
import time
import numpy as np

from GetJointData import data, NatNetFuncs#receiveNewFrame, receiveRigidBodyFrameList
from NatNetClient2 import NatNetClient
#from AngleControl import MotorControl
from getRobotPose import getOptitrackPose

#socket_ip = '192.168.1.39'
#socket_port = 1122

server_ip = "192.168.1.27"
multicastAddress = "239.255.42.99"
print_trak_data = False

joint_names = ['base', 'j2', 'j3', 'j4', 'target']
ids = [0, 1, 2, 3, 4]

#P=0.1
#PL=0
#I=0
#D = 0

#joint_motor_indexes = [0,1,2,3]

#MC = MotorControl(P, PL ,I,D,joint_motor_indexes, control_freq = 20)
#MC.tcp_init(socket_ip, socket_port)
#MC.motor_init()

#rint("Arming motors now...")
#MC.motors.arm()
#time.sleep(2)
#error_cum = 100 #initialize break error to a large value

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
track_data = data(joint_names,ids)
track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
#debug values
print_cartesian = True

#MC.zero_arm(track_data, NatNet)

#angle_setpoints = np.array([5,0,0,75])
#angle_setpoints[:3] = angle_setpoints[:3] * np.pi/180

while True:
	j1_angle, j2_angle, j3_angle, j4_pos, joint4_base, j4b_pos, j4b_euler = getOptitrackPose(track_data, NatNet)
	print("J1 angle: {}, J2 angle: {}, J3 angle: {}, J4 pos: {}" .format(j1_angle, j2_angle, j3_angle, j4_pos))
	#current_angles = np.array([j1_angle* np.pi/180 ,j2_angle* np.pi/180, j3_angle* np.pi/180, j4_pos])
	#MC.update(current_angles, angle_setpoints)
