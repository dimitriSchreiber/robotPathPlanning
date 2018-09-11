#---------------------------------------------
#vrep imports
#---------------------------------------------
import numpy as np
import vrep
from forwardKinematics import robot_config
import time
import os
import socket
from copy import deepcopy
from getRobotPose import *
#---------------------------------------------
#motor imports
#---------------------------------------------
from utils.motor_class import motors
from utils.tcp_class import tcp_communication

#---------------------------------------------
#optitrak imports
#---------------------------------------------
import signal
import sys
import transforms3d as t3d
from copy import deepcopy
from utils.GetJointData import data, NatNetFuncs#receiveNewFrame, receiveRigidBodyFrameList
from utils.NatNetClient2 import NatNetClient


#---------------------------------------------
#optitrak setup
#---------------------------------------------
server_ip = "192.168.1.27"
multicastAddress = "239.255.42.99"
print_trak_data = False
optitrack_joint_names = ['base', 'j2', 'j3', 'j4', 'target']
ids = [0, 1, 2, 3, 4]
#debug values
print_cartesian = False
save_data = False

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
#helper functions
#---------------------------------------------

def calculate_sine(dt, count, hz, amplitude):
    return np.sin(count/dt*(2*pi)*hz)*amplitude



#---------------------------------------------
#constants
#---------------------------------------------
pi = np.pi

#---------------------------------------------
#robot kinematics, jacobian class
#---------------------------------------------
myRobot = robot_config()

#robot joint positions
#q = [pi/8, pi/8, pi/8, 0]
q = [0, 0, 0, 0]

#---------------------------------------------
#vrep setup
#---------------------------------------------
pose_names = ['pose_origin', 'pose_j1', 'pose_j2', 'pose_j3', 'pose_j4']
robot_pose_names = ['robot_origin', 'robot_j1', 'robot_j2', 'robot_j3', 'robot_j4']
n_poses = len(pose_names)

# On Shutdown
def shutDown_vrep():
    vrep.simxStopSimulation(clientID, vrep.simx_opmode_blocking)
    vrep.simxFinish(clientID)

#---------------------------------------------
#main loop
#---------------------------------------------

try:

    
    # close any open connections
    vrep.simxFinish(-1)
    # Connect to the V-REP continuous server
    clientID = vrep.simxStart('127.0.0.1', 19997, True, True, 500, 5)

    if clientID != -1: # if we connected successfully
        print ('Connected to remote API server')

        # --------------------- Setup the simulation
        #vrep.simxSynchronous(clientID,True)

        # get handle for target and set up streaming
        pose_handles = [vrep.simxGetObjectHandle(clientID,
            name, vrep.simx_opmode_blocking)[1] for name in pose_names]

        robot_pose_handles = [vrep.simxGetObjectHandle(clientID,
            name, vrep.simx_opmode_blocking)[1] for name in robot_pose_names]


        # Set up streaming
        dt = .05
        vrep.simxSetFloatingParameter(
            clientID,
            vrep.sim_floatparam_simulation_time_step,
            dt, # specify a simulation time step
            vrep.simx_opmode_oneshot)

        # Start the simulation
        #vrep.simxStartSimulation(clientID,vrep.simx_opmode_blocking) #to increase loop speed mode is changed.
        vrep.simxStartSimulation(clientID,vrep.simx_opmode_oneshot_wait)

        #counter for time keeping
        count = 0

        #initialize forward kinematics
        fk_orientations = np.zeros((n_poses, 4))
        fk_orientations[0,-1] = 1
        fk_positions = np.zeros((n_poses, 3))
        fk_positions[1:,:] = myRobot.forwardKinPos(q) * 20
        fk_orientations[1:,:] = myRobot.forwardKinOrientation(q)

        #to check loop time:
        start_time_loop = time.time()

        while count < 20:
            #for loop timer sleep at the end to make true "dt" loop time
            start_time = time.time()


            #---------------------------------------------
            #update vrep display, 0.7ms block
            #---------------------------------------------

            if count > 0:
                # j1_frame_pos = vrep.simxGetObjectPosition(
                #             clientID,
                #             pose_handles[0],
                #             -1, #absolute not relative position
                #             vrep.simx_opmode_blocking)
                #print("goal pos: {}".format(fk_positions))


                # Set position of the target
                for i in range(n_poses):
                    vrep.simxSetObjectPosition(
                        clientID,
                        pose_handles[i],
                        -1,# Setting the absolute position
                        position=fk_positions[i],
                        operationMode=vrep.simx_opmode_oneshot#vrep.simx_opmode_blocking
                        )

                    vrep.simxSetObjectPosition(
                        clientID,
                        robot_pose_handles[i],
                        -1,# Setting the absolute position
                        position=optitrak_joint_base_positions[i],
                        operationMode=vrep.simx_opmode_oneshot#vrep.simx_opmode_blocking
                        )

                    vrep.simxSetObjectQuaternion(
                        clientID,
                        pose_handles[i],
                        -1,
                        fk_orientations[i], #(x, y, z, w)
                        operationMode = vrep.simx_opmode_oneshot#vrep.simx_opmode_blocking
                        )

                    vrep.simxSetObjectQuaternion(
                        clientID,
                        robot_pose_handles[i],
                        -1,
                        optitrak_joint_base_quats[i], #(x, y, z, w)
                        operationMode = vrep.simx_opmode_oneshot#vrep.simx_opmode_blocking
                        )
   
            #---------------------------------------------
            #update joint angle goal using IK, 2ms block
            #---------------------------------------------
            #TODO, for now static
            q = q

            #for visualization
            fk_positions[1:,:] = myRobot.forwardKinPos(q) * 20 #20 for consistent visualizing  --> uses m units length
            fk_orientations[1:,:] = myRobot.forwardKinOrientation(q)
            

            #---------------------------------------------
            #get Optitrak data, 4ms block
            #---------------------------------------------
            track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
            
            optitrak_joint_base_positions, optitrak_joint_base_quats = getOptitrakVis(track_data, fk_positions, fk_orientations)
            j2b_euler, j3j2_euler, j4j3_pos,  = getOptitrakControl(track_data)
            
            #!!!! this possibly has errors, likely is correct. !!!!
            q_optitrak = np.array([j2b_euler[0], j2b_euler[1], j3j2_euler[1], j4j3_pos[2]])


            
            #---------------------------------------------
            #calculate jacobian update, 0.35ms block
            #---------------------------------------------
            print('\n q: {}\n q optitrak: {}\n optitrak EE base positions: {}\n fk EE base positions: {}'
                .format(q, q_optitrak, optitrak_joint_base_positions[-1, :], fk_positions[-1, :]))

            JEE_optitrak = myRobot.J('j4', q_optitrak)
            JEE = myRobot.J('j4', q)
            JEE_optitrak_inv = np.linalg.pinv(JEE_optitrak[:3, :])
            EE_position_optitrak = optitrak_joint_base_positions[-1, :]
            EE_position_fk = fk_positions[-1, :]
            K = np.array([0.1, 0.1, 0.1])
            joint_angle_update = np.matmul(JEE_optitrak_inv,(EE_position_fk - EE_position_optitrak) * K) * dt

            print(joint_angle_update)
            #invert jacobian matrix, multiply by end effector error versus FK times K gain matrix? look in my notebook.

            #!!!!!!!!need to do this control code!!!!!!


            #---------------------------------------------
            #perform joint angle control
            #---------------------------------------------
            #calculates forward kinematic homogeneous matrices
            #fk_homogenous = myRobot.forwardKinHomogenous(q)
            #calculates forward kinematic homogeneous matrix inverses
            #fk_homogenous_inv = myRobot.forwardKinHomogenous(q, inverse = True)

            while dt - (time.time() - start_time) > 0:


                #---------------------------------------------
                #update joint angle controller setpoint, takes in q+joint_angle_update, q_optitrak
                #---------------------------------------------

                #DANIELS CONTROL FUNCTION


                track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
                j2b_euler, j3j2_euler, j4j3_pos,  = getOptitrakControl(track_data)
                q_optitrak = np.array([j2b_euler[0], j2b_euler[1], j3j2_euler[1], j4j3_pos[2]])

                time.sleep(0.001)

            count += dt #for outer loop timekeeping
            #time.sleep(max(dt - difference, 0))

        end_time_loop = time.time()

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

    print("Average loop time: {}".format((end_time_loop-start_time_loop)/(count/dt)))
    # stop the simulation
    vrep.simxStopSimulation(clientID, vrep.simx_opmode_blocking)

    # Before closing the connection to V-REP,
    # make sure that the last command sent out had time to arrive.
    vrep.simxGetPingTime(clientID)

    # Now close the connection to V-REP:
    vrep.simxFinish(clientID)

    #close optitrak connection
    streamingClient.stop()

print('connection closed...')