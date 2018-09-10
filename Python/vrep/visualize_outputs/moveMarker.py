import numpy as np
import vrep
from forwardKinematics import robot_config
import time
import os
import socket
from copy import deepcopy
from getRobotPose import getOptitrackPose

from utils.motor_class import motors
from utils.tcp_class import tcp_communication



pi = np.pi
myRobot = robot_config()
q = [0, 0, 0, 0.000]


def calculate_sine(dt, count, hz, amplitude):
    return np.sin(count/dt*(2*pi)*hz)*amplitude

# On Shutdown
def shutDown_vrep():
    vrep.simxStopSimulation(clientID, vrep.simx_opmode_blocking)
    vrep.simxFinish(clientID)
pose_names = ['pose_origin', 'pose_j1', 'pose_j2', 'pose_j3', 'pose_j4']
n_poses = len(pose_names)

try:
    # close any open connections
    vrep.simxFinish(-1)
    # Connect to the V-REP continuous server
    clientID = vrep.simxStart('127.0.0.1', 19997, True, True, 500, 5)

    if clientID != -1: # if we connected successfully
        print ('Connected to remote API server')

        # --------------------- Setup the simulation
        vrep.simxSynchronous(clientID,True)

        # get handle for target and set up streaming
        pose_handles = [vrep.simxGetObjectHandle(clientID,
            name, vrep.simx_opmode_blocking)[1] for name in pose_names]


        # Set up streaming
        dt = .001
        vrep.simxSetFloatingParameter(
            clientID,
            vrep.sim_floatparam_simulation_time_step,
            dt, # specify a simulation time step
            vrep.simx_opmode_oneshot)

        # Start the simulation
        vrep.simxStartSimulation(clientID,vrep.simx_opmode_blocking)


        #counter for time keeping
        count = 0

        goal_orientations = np.zeros((n_poses, 4))
        goal_orientations[0,-1] = 1
        goal_positions = np.zeros((n_poses, 3))
        goal_positions[1:,:] = myRobot.forwardKinPos(q) * 20
        goal_orientations[1:,:] = myRobot.forwardKinOrientation(q)

        while count < 1:

            j1_frame_pos = vrep.simxGetObjectPosition(
                        clientID,
                        pose_handles[0],
                        -1, #absolute not relative position
                        vrep.simx_opmode_blocking)

            print("goal pos: {}".format(goal_positions))

            #j1_goal_pos[2] = 0.5 + calculate_sine(dt=1, count=count, hz=4, amplitude = 0.5)
            #j1_goal_orientation[2] = calculate_sine(dt=1, count=count, hz=4, amplitude = pi)
            #print("goal pos: {}, goal orientation: {}".format(j1_frame_pos, j1_goal_orientation))

            # Set position of the target
            for i in range(n_poses):
                vrep.simxSetObjectPosition(
                    clientID,
                    pose_handles[i],
                    -1,# Setting the absolute position
                    position=goal_positions[i],
                    operationMode=vrep.simx_opmode_blocking
                    )
                # vrep.simxSetObjectOrientation(
                #     clientID,
                #     pose_handles[i],
                #     -1,# Setting the absolute position
                #     eulerAngles=goal_orientations[i],
                #     operationMode=vrep.simx_opmode_blocking
                #     )
                vrep.simxSetObjectQuaternion(
                    clientID,
                    pose_handles[i],
                    -1,
                    goal_orientations[i], #(x, y, z, w)
                    operationMode = vrep.simx_opmode_blocking)
            '''
            vrep.simxSetObjectOrientation(
                clientID,
                pose_handles[0],
                -1,# Setting the absolute position
                eulerAngles=j1_goal_orientation,
                operationMode=vrep.simx_opmode_blocking
                )
            '''
            # move simulation ahead one time step
            vrep.simxSynchronousTrigger(clientID)
            count += dt

        # stop the simulation
        vrep.simxStopSimulation(clientID, vrep.simx_opmode_blocking)

        # Before closing the connection to V-REP,
        #make sure that the last command sent out had time to arrive.
        vrep.simxGetPingTime(clientID)

        # Now close the connection to V-REP:
        vrep.simxFinish(clientID)

    else:
        raise Exception('Failed connecting to remote API server')

finally:

    # stop the simulation
    vrep.simxStopSimulation(clientID, vrep.simx_opmode_blocking)

    # Before closing the connection to V-REP,
    # make sure that the last command sent out had time to arrive.
    vrep.simxGetPingTime(clientID)

    # Now close the connection to V-REP:
    vrep.simxFinish(clientID)
print('connection closed...')