import numpy as np
import vrep
import time

#https://studywolf.wordpress.com/2016/04/18/using-vrep-for-simulation-of-force-controlled-models/

try:
	# close any open connections
	vrep.simxFinish(-1)
	# Connect to the V-REP continuous server
	clientID = vrep.simxStart('127.0.0.1', 19997, True, True, 500, 5)

	track_target = []

	if clientID != -1: # if we connected successfully

		emptyBuff = bytearray()

		print ('Connected to remote API server')
		# Start the simulation:
		vrep.simxStartSimulation(clientID,vrep.simx_opmode_oneshot_wait)

		# Retrieve some handles:
		joint_names = ['x_joint', 'y_joint', 'rotary_joint', 'j0_joint', 'j1_joint', 'j2_joint', 'insertion_joint']
		joint_handles = [vrep.simxGetObjectHandle(clientID,
		    name, vrep.simx_opmode_oneshot_wait)[1] for name in joint_names]

		# get handle for target and set up streaming
		_, target_handle = vrep.simxGetObjectHandle(clientID,
	        'target', vrep.simx_opmode_oneshot_wait)


		# get the (x,y,z) position of the target
		_, target_xyz = vrep.simxGetObjectPosition(clientID,
			target_handle,
			-1, # retrieve absolute, not relative, position
			vrep.simx_opmode_blocking)

		if _ !=0 : raise Exception()
		print('Target position: {}'.format(target_xyz))

		track_target.append(np.copy(target_xyz)) # store for plotting
		target_xyz = np.asarray(target_xyz)

		q = np.zeros(len(joint_handles))
		dq = np.zeros(len(joint_handles))
		for ii,joint_handle in enumerate(joint_handles):
			# get the joint angles
			_, q[ii] = vrep.simxGetJointPosition(clientID,
	    		joint_handle,
	    		vrep.simx_opmode_oneshot_wait)
			
			#if _ !=0 : raise Exception() #what is this for?

			# get the joint velocity
			_, dq[ii] = vrep.simxGetObjectFloatParameter(clientID,
	        	joint_handle,
	        	2012, # parameter ID for angular velocity of the joint
	    		vrep.simx_opmode_oneshot_wait)
			
			#if _ !=0 : raise Exception() #what is this for?


		L = np.array([.42, .225]) # arm segment lengths
		joint_target_position = np.ones(len(joint_handles)) * 0#joint_target_positions[i]
		for ii,joint_handle in enumerate(joint_handles):
			vrep.simxSetJointTargetPosition(clientID,
				joint_handle,
				joint_target_position[ii], # target velocity
				vrep.simx_opmode_oneshot_wait)

		time.sleep(1)

		joint_target_position = np.ones(len(joint_handles)) * 0.05#joint_target_positions[i]
		for ii,joint_handle in enumerate(joint_handles):
			vrep.simxSetJointTargetPosition(clientID,
				joint_handle,
				joint_target_position[ii], # target velocity
				vrep.simx_opmode_oneshot_wait)

		time.sleep(1)

		joint_target_velocity = np.ones(len(joint_handles)) * 0.05#joint_target_positions[i]
		for ii,joint_handle in enumerate(joint_handles):
			vrep.simxSetJointTargetVelocity(clientID,
				joint_handle,
				joint_target_velocity[ii], # target velocity
				vrep.simx_opmode_oneshot_wait)	

		time.sleep(1)		

finally:

	time.sleep(1)
	vrep.simxStopSimulation(clientID,vrep.simx_opmode_oneshot_wait)

    # Now close the connection to V-REP:
	vrep.simxFinish(clientID)

        