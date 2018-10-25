#puts above directory into the path
import sys
sys.path.append("..")

import time
import signal
import numpy as np
import vrep

from utils.motor_setup import Motors

def signal_handler(signal, frame):
	motors.tcp_close()

signal.signal(signal.SIGINT, signal_handler)

#Constants
socket_ip = '192.168.1.18'
socket_port = 1122

P = 0
PL = 0
I = 0
IL = 0
D = 0
motors = Motors(P ,PL ,I, IL ,D)
motors.tcp_init(socket_ip, socket_port)
print("Arming motors now...")
motors.arm_motors()
time.sleep(2)

#------------------------------
#Current Readings
#------------------------------
while(True):
	motors.command_motors(np.zeros(8))
	print("{:.3f} mA".format(1000*motors.avg_current))
	time.sleep(0.01)
#------------------------------
#------------------------------



# limit_switches = 0
# enc_position = np.zeros(8)
# while(np.sum(limit_switches) == 0):
# 	enc_position = enc_position + 1000
# 	motors.command_motors(enc_position)
# 	limit_switches = motors.limit_switches_data
# 	print(limit_switches)
# 	time.sleep(0.01)

print("done")
motors.tcp_close()


# #optitrak setup
# server_ip = "192.168.1.27"
# multicastAddress = "239.255.42.99"
# print_trak_data = False
# optitrack_joint_names = ['base', 'j2', 'j3', 'j4', 'target']
# ids = [0, 1, 2, 3, 4]

# #Tracking class
# print("Starting streaming client now...")
# streamingClient = NatNetClient(server_ip, multicastAddress, verbose = print_trak_data)
# NatNet = NatNetFuncs()
# streamingClient.newFrameListener = NatNet.receiveNewFrame
# streamingClient.rigidBodyListListener = NatNet.receiveRigidBodyFrameList

# prev_frame = 0
# time.sleep(0.5)
# streamingClient.run()
# time.sleep(0.5)
# track_data = data(optitrack_joint_names,ids)
# track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
# old_frame = track_data.frame

"""
#What i need to do
conversion of motor encoder counts to distance
integrate limit switches
record data
setup tracker info
plot tracker data and encoder data
"""