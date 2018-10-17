import vrep
import numpy as np


class VREP_Environement:
''' This object defines a VREP environment '''
	def __init__(self, object_names, dt, connection_type, ip_adress = '192.168.1.39', port = 1122):
		self.object_names = object_names
		self.object_handles = []
		self.dt = dt
		self.ip_adress = ip_adress
		self.port = port
		self.connection_type = connection_type
		self.clientID = None

		#Close any open connections
		vrep.simxFinish(-1)

		error = self.connectToServer()
		if error:
			print('There was an error connecting to the server')

		# error = self.getObjectHandles():
		# if error:
		# 	print('There was an error getting object handles')

	def connectToServer(self):	
		self.clientID = vrep.simxStart('127.0.0.1', 19997, True, True, 500, 5)

		if self.clientID != -1: # if we connected successfully
			print ('Connected to remote API server')

	def add_robot(self, robot_class):
		#Adds robot class to current running VREP environment
		setattr(self, robot_class.robot_name, robot_class)
		self.robot_class.robot_name.clientID = self.clientID

	def getObjectHandles(self):
		if self.connection_type == 'blocking':
			object_handles = [vrep.simxGetObjectHandle(clientID, name, vrep.simx_opmode_blocking)[1] for name in joint_names]
		else:

		print 'Joint names: ', self.object_names
		print 'Joint handles: ', self.object_handles

	def shutdown(self):
		self.vrep.simxFinish(self.clientID)



class VREP_Robot:
'''This object defines the robots in the environment'''
	def __init__(self, robot_name, handle_names):
		self.robot_name = robot_name
		self.handles = handle_names
		self.num_poses = len(handle_names) 
		self.positions = np.ones([self.num_poses,3]) #xyz
		self.orientations = np.ones([self.num_poses,4]) #xyzw
		self.clientID = None

	def setObjectPosition(self, object_name, cartesian_position):
		if self.clientID == None:
			print("Robot not attached to VREP environment")
		else:
			vrep.simxSetObjectPosition(
			    clientID,
			    object_name,
			    -1,# Setting the absolute position
			    position=cartesian_position,
			    operationMode=vrep.simx_opmode_oneshot
			    )

	def setObjectQuaternion(self, object_name, quaternion):
		if self.clientID == None:
			print("Robot not attached to VREP environment")
		else:
			vrep.simxSetObjectQuaternion(
			    clientID,
			    object_name,
			    -1,# Setting the absolute position
			    quat = quaternion, #(x, y, z, w)
			    operationMode = vrep.simx_opmode_oneshot
			    )

	def setObjectPosition(self, object_name):
		if self.clientID == None:
			print("Robot not attached to VREP environment")
		else:
			vrep.simxGetObjetPosition(
			    clientID,
			    object_name,
			    -1,# Setting the absolute position
			    operationMode = vrep.simx_opmode_oneshot
			    )

	def getObjectOrientation(self, object_name):
		if self.clientID == None:
			print("Robot not attached to VREP environment")
		else:
			vrep.simxGetObjectQuaternion(
			    clientID,
			    object_name,
			    -1,# Setting the absolute position
			    operationMode = vrep.simx_opmode_oneshot
			    )