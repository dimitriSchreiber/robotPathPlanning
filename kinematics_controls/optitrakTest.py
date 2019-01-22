import signal
import sys
import transforms3d as tf3d
import time
import numpy as np

from GetJointData import data, NatNetFuncs #receiveNewFrame, receiveRigidBodyFrameList
from NatNetClient2 import NatNetClient
from getRobotPose import getOptitrackPose


server_ip = "192.168.1.27"
multicastAddress = "239.255.42.99"
print_trak_data = False

joint_names = ['base', 'j2', 'j3', 'j4', 'target']
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

track_data = data(joint_names,ids)
track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
#debug values

print_cartesian = True


while True:
	j1_angle, j2_angle, j3_angle, j4_pos, joint4_base, j4b_pos, j4b_euler = getOptitrackPose(track_data, NatNet)
	print("J1 angle: {}, J2 angle: {}, J3 angle: {}, J4 pos: {}" .format(j1_angle, j2_angle, j3_angle, j4_pos))

