import numpy as np
import time
import socket
import re
from copy import deepcopy
import signal
import sys
import os

from .tcp_class import tcp_communication
#from .JointAngleMixing import MotorArmMixing #accounts for coupling in motion
#from .getRobotPose import getOptitrackPose



"""
Example setup

motors = Motors()
motors.tcp_init(socket_ip, socket_port)
motors.arm_motors()

#Zeros the arm to home position
motors.zero_arm(track_data, NatNet)

"""

class Motors():
	def __init__(self, P ,PL ,I, IL ,D, control_freq = 50):
		#Constants -> also belt pitch 2mm
		self.encoder_counts = 1440
		self.gear_ratio = 470 #479
		self.counts_per_revolution = self.gear_ratio * self.encoder_counts
		self.counts_per_radian = self.counts_per_revolution / (2 * np.pi)
		self.counts_per_degree = self.counts_per_revolution / 360
		self.counter = 0

		self.motor_pos = np.zeros(8)	#running track of motor position in encoder counts, updates with each command
		self.motor_encoders_data = np.zeros(8) #running track of read data
		self.limit_switches_data = np.zeros(8)
		self.joint_encoders_data = np.zeros(4) #running track of read data
		self.avg_current = 0


		self.current_time = time.time()
		self.time_last_run = time.time()
		self.control_freq = control_freq
		self.error_cum = 0
		self.P = P
		self.PL = PL
		self.IL = IL
		self.I = I
		self.D = D

		#communication stuff setup on call to tcp_init
		self.tcp = None
		self.client_socket = None
		self.zero_position = None


	def tcp_init(self, socket_ip, socket_port):
		self.tcp = tcp_communication(socket_ip, socket_port)
		self.client_socket = self.tcp.open_socket()
		IsWindows = os.name == 'nt'
		if IsWindows:
			self.tcp.setpriority()

	def arm_motors(self):
		self.read_buff()
		print("initializing motors to {}".format(self.motor_encoders_data))
		self.zero_position = deepcopy(self.motor_pos)
		time.sleep(1)
		self.read_buff()
		data = ('b' + 'arm' + 'd')
		print("Arming motors")
		self.client_socket.send(data.encode())
		self.read_buff()
		time.sleep(1)
		return

	def command_motors(self, pos): #sends new positions to controller and updates local position with encoder reads
		self.motor_pos = pos
		data = ('b'+ str(int(pos[0])) + ' ' + str(int(pos[1])) + ' ' + str(int(pos[2])) + ' ' +
					 str(int(pos[3])) + ' ' + str(int(pos[4])) + ' ' + str(int(pos[5])) + ' ' +
					 str(int(pos[6])) + ' ' + str(int(pos[7])) + 'd')
		self.client_socket.send(data.encode())
		self.read_buff()
		return self.motor_pos #position just sent to motors

	def read_buff(self, print_sensors = False):
		data = str(self.client_socket.recv(256))
		data = re.split('\s', data)
		if data[1] == 'closeports':
			self.client_socket.close()
			print("\n\nServer side closed. Closing ports now.\n\n")
			sys.exit()

		if data[1] == 'err':
			print("*** C side has an error or needs to be armed ***\n")

		else:
			self.motor_encoders_data = np.array(list(map(int, data[1:9])))
			self.limit_switches_data = np.array(list(map(int, data[9:17])))
			self.joint_encoders_data = np.array(list(map(int, data[17:21])))
			self.avg_current = float(data[21])

			if print_sensors:
				print('Read motor encoder positions {}'.format(self.motor_encoders_data))
				print('Read joint encoder positions {}'.format(self.joint_encoders_data))
				#print('Read limit switch values {}'.format(self.limit_data))
		return

	def tcp_close(self):
		data = ('b'+ 'stop' +'d')
		self.client_socket.send(data.encode())
		self.client_socket.shutdown(socket.SHUT_RDWR)
		self.client_socket.close()

	def zero_arm(self, track_data, NatNet, joint_motor_indexes):	
		k = 0.025
		kl = 0.1
		motor_command = deepcopy(self.zero_position)

		#---------------------------------------#---------------------------------------
		#Zeroing loop                           #---------------------------------------
		#---------------------------------------#---------------------------------------
		j1_angle, j2_angle, j3_angle, j4_pos, joint4_base, j4b_pos, j4b_euler = getOptitrackPose(track_data, NatNet)

		retractFlag = 0

		while np.abs(j1_angle) > 1 or np.abs(j2_angle) > 1 or np.abs(j3_angle) > 1 or np.abs(j4_pos - 175) > 0.2:

			j1_angle, j2_angle, j3_angle, j4_pos, joint4_base, j4b_pos, j4b_euler = getOptitrackPose(track_data, NatNet)

			if retractFlag == 0:
				while np.abs(j4_pos - 175) > 0.2:
					motor_command[joint_motor_indexes[3]] += int(-1* (j4_pos-175) * self.counts_per_degree * kl)
					self.command_motors(motor_command)
					print("Current joint positions: \n j1: {}\n j2: {}\n j3: {}\n j4: {}\n".format(j1_angle, j2_angle, j3_angle, j4_pos))
					print("Motor command: {}".format(motor_command))
					j1_angle, j2_angle, j3_angle, j4_pos, joint4_base, j4b_pos, j4b_euler = getOptitrackPose(track_data, NatNet)
					time.sleep(0.05)

				retractFlag = 1

			if np.abs(j1_angle) > 1:
				motor_command[joint_motor_indexes[0]] += int(-1* j1_angle * self.counts_per_degree * k)
			elif np.abs(j2_angle) > 1:
				motor_command[joint_motor_indexes[1]] += int(j2_angle * self.counts_per_degree * k)
			elif np.abs(j3_angle) > 1:
				motor_command[joint_motor_indexes[2]] += int(j3_angle * self.counts_per_degree * k)
			elif np.abs(j4_pos - 175) > 0.2:
				motor_command[joint_motor_indexes[3]] += int(-1* (j4_pos-175) * self.counts_per_degree * kl)
			error_cum = np.abs(j1_angle) + np.abs(j2_angle) + np.abs(j3_angle)

			print("Current joint positions: \n j1: {}\n j2: {}\n j3: {}\n j4: {}\n".format(j1_angle, j2_angle, j3_angle, j4_pos))
			print("Motor command: {}".format(motor_command))

			self.command_motors(motor_command)

			time.sleep(0.05)

		self.zero_position = deepcopy(motor_command)



#update step might not be what we want right now
	def update(self, current_angles, angle_setpoints, trajectory = None, print_data=False):
		#Radians
		#returns a flag that indicates if the update was run or not
		self.current_time = time.time()

		error = angle_setpoints - current_angles
		arm_angles_signal = np.zeros((4,1))

		if self.current_time - self.time_last_run >= 1/self.control_freq:

			dt = self.current_time - self.time_last_run
			self.error_cum = error * dt + self.error_cum
			arm_angles_signal[0] = angle_setpoints[0] + error[0] * self.P + self.error_cum[0] * self.I
			arm_angles_signal[1] = angle_setpoints[1] + error[1] * self.P + self.error_cum[1] * self.I
			arm_angles_signal[2] = angle_setpoints[2] + error[2] * self.P + self.error_cum[2] * self.I
			arm_angles_signal[3] = angle_setpoints[3] + error[3] * self.PL + self.error_cum[3] * self.IL

			motor_angle_setpoints = MotorArmMixing(arm_angles_signal) #4x1 matrix return

			self.motor_command[self.joint_motor_indexes[0]] = self.zero_position[self.joint_motor_indexes[0]] + motor_angle_setpoints[0] * self.counts_per_radian
			self.motor_command[self.joint_motor_indexes[1]] = self.zero_position[self.joint_motor_indexes[1]] + motor_angle_setpoints[1] * self.counts_per_radian * -1
			self.motor_command[self.joint_motor_indexes[2]] = self.zero_position[self.joint_motor_indexes[2]] + motor_angle_setpoints[2] * self.counts_per_radian * -1
			self.motor_command[self.joint_motor_indexes[3]] = self.zero_position[self.joint_motor_indexes[3]] + motor_angle_setpoints[3] * self.counts_per_radian

			#for i in range(len(joint_motor_indexes))
			#	self.motor_command[joint_motor_indexes[i]] = self.zero_position + motor_angle_setpoints[i] * self.counts_per_radian
			if print_data and self.counter % 100 == 0:
				#Converting to degrees
				# print("ERROR", error)
				# print("setpoints", angle_setpoints)
				# print("current angles", current_angles)
				# print(self.motor_command)
				print("ERROR", np.append(error[0:-1] * 180/np.pi, error[-1]))
				print("cum error for I", self.error_cum)
				print("setpoints", np.append(angle_setpoints[0:-1] * 180/np.pi, angle_setpoints[-1]))
				print("current angles", np.append(current_angles[0:-1] * 180/np.pi, current_angles[-1]))
				print(self.motor_command.astype(int))
				print("\n")
			
			self.counter = self.counter + 1
			self.command_motors(self.motor_command.astype(int))

			self.time_last_run = self.current_time
			update = 1
		else:
			update = 0

		return update