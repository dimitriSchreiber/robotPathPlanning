import vrep

class VREP_Environement:
	''' This object defines a VREP environment '''
	def __init__(self, object_names, environment_name, ip_adress = '192.168.1.39', port = 1122, connection_type):
		self.object_names = object_names
		self.object_handles = []
		self.environment_name = environment_name
		self.ip_adress = ip_adress
		self.port = port
		self.connection_type = connection_type

		error = connectToServer()
		if error:
			print('There was an error connecting to the server')

		error = getObjectHandles():
		if error:
			print('There was an error getting object handles')

	def connectToServer(self):	

	def getObjectHandles(self):
		if self.connection_type == 'blocking':
			object_handles = [vrep.simxGetObjectHandle(clientID, name, vrep.simx_opmode_blocking)[1] for name in joint_names]
		else:

		print 'Joint names: ', self.object_names
		print 'Joint handles: ', self.object_handles

	def setObjectPosition(self, object_name, cartesian_position):

	def setObjectOrientation(self, object_name, quaternion):

	def getObjectPosition(self, object_name):

	def getObjectOrientation(self, object_name):

class VREP_Robot(VREP_Environement):


