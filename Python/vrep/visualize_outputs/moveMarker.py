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
from getRobotPose import getOptitrackPose

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
time.sleep(1)
track_data = data(optitrack_joint_names,ids)
track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
old_frame = track_data.frame

# while 1:
#     track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
#     current_frame = track_data.frame
#     print(current_frame)

    
#     base = track_data.bodies[0].homogenous_mat
#     base_inv = track_data.bodies[0].homg_inv
#     joint2 = track_data.bodies[1].homogenous_mat
#     joint2_inv = track_data.bodies[1].homg_inv
#     joint3 = track_data.bodies[2].homogenous_mat
#     joint3_inv = track_data.bodies[2].homg_inv
#     joint4 = track_data.bodies[3].homogenous_mat
#     joint4_inv = track_data.bodies[3].homg_inv
#     target = track_data.bodies[4].homogenous_mat

#     joint2_base, j2b_pos, j2b_euler, _ = track_data.homg_mat_mult(base_inv,joint2) #joint2 in base frame -> moves only in base Y+X axis
#     joint3_joint2, j3j2_pos, j3j2_euler, _ = track_data.homg_mat_mult(joint2_inv,joint3)
#     joint4_joint3, j4j3_pos, j4j3_euler, _ = track_data.homg_mat_mult(joint3_inv,joint4)
#     target_joint4, targetj4_pos, targetj4_euler, _ = track_data.homg_mat_mult(joint4_inv,target)


#     j2b_deg = np.array(j2b_euler) * 180 / np.pi
#     j2b_pos_mm = np.array(j2b_pos)*1000
#     j3j2_deg = np.array(j3j2_euler) * 180 / np.pi
#     j3j2_pos_mm = np.array(j3j2_pos)*1000
#     j4j3_deg = np.array(j4j3_euler) * 180 / np.pi
#     j4j3_pos_mm = np.array(j4j3_pos)*1000
#     targetj4_deg = np.array(targetj4_euler) * 180 / np.pi
#     targetj4_pos_mm = np.array(targetj4_pos)*1000


#     print("joint 2 position in base frame\n base: {0[0]:.4f}, {0[1]:.4f}, {0[2]:.4f}".format(j2b_pos_mm))
#     print("joint 2 euler in base frame\n base: {0[0]:.4f}, {0[1]:.4f}, {0[2]:.4f}\n".format(j2b_deg))
#     print("joint 3 position in joint 2 frame\n base: {0[0]:.4f}, {0[1]:.4f}, {0[2]:.4f}".format(j3j2_pos_mm))
#     print("joint 3 euler in joint 2 frame\n base: {0[0]:.4f}, {0[1]:.4f}, {0[2]:.4f}\n".format(j3j2_deg))
#     print("joint 4 position in joint 3 frame\n base: {0[0]:.4f}, {0[1]:.4f}, {0[2]:.4f}".format(j4j3_pos_mm))
#     print("joint 4 euler in joint 3 frame\n base: {0[0]:.4f}, {0[1]:.4f}, {0[2]:.4f}\n".format(j4j3_deg))
#     print("target position in joint 4 frame\n base: {0[0]:.4f}, {0[1]:.4f}, {0[2]:.4f}".format(targetj4_pos_mm))
#     print("target euler in joint 4 frame\n base: {0[0]:.4f}, {0[1]:.4f}, {0[2]:.4f}\n".format(targetj4_deg))

#     if (current_frame - old_frame > 100 and save_data):
#         print("saving values printed below \n\n\n")
#         print(base)
#         print(joint2)
#         print(joint3)
#         print(joint4)
#         print(target)
#         np.savez('outfile', base, joint2, joint3, joint4, target)
#         old_frame = current_frame
    
#     time.sleep(0.1)

#---------------------------------------------
#constants
#---------------------------------------------
pi = np.pi


#---------------------------------------------
#robot kinematics
#---------------------------------------------
myRobot = robot_config()
q = [pi/8, pi/8, pi/8, 0.001*pi/8]


#---------------------------------------------
#helper functions
#---------------------------------------------

def calculate_sine(dt, count, hz, amplitude):
    return np.sin(count/dt*(2*pi)*hz)*amplitude

# On Shutdown
def shutDown_vrep():
    vrep.simxStopSimulation(clientID, vrep.simx_opmode_blocking)
    vrep.simxFinish(clientID)

#---------------------------------------------
#vrep poses
#---------------------------------------------
pose_names = ['pose_origin', 'pose_j1', 'pose_j2', 'pose_j3', 'pose_j4']
robot_pose_names = ['robot_origin', 'robot_j1', 'robot_j2', 'robot_j3', 'robot_j4']
n_poses = len(pose_names)

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
        vrep.simxSynchronous(clientID,True)

        # get handle for target and set up streaming
        pose_handles = [vrep.simxGetObjectHandle(clientID,
            name, vrep.simx_opmode_blocking)[1] for name in pose_names]

        robot_pose_handles = [vrep.simxGetObjectHandle(clientID,
            name, vrep.simx_opmode_blocking)[1] for name in robot_pose_names]


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

            #---------------------------------------------
            #get Optitrak data
            #---------------------------------------------
            track_data.parse_data(NatNet.joint_data, NatNet.frame) #updates the frame and data that is being used
            current_frame = track_data.frame
            base = track_data.bodies[0].homogenous_mat
            base_inv = track_data.bodies[0].homg_inv
            joint2 = track_data.bodies[1].homogenous_mat
            joint2_inv = track_data.bodies[1].homg_inv
            joint3 = track_data.bodies[2].homogenous_mat
            joint3_inv = track_data.bodies[2].homg_inv
            joint4 = track_data.bodies[3].homogenous_mat
            joint4_inv = track_data.bodies[3].homg_inv
            target = track_data.bodies[4].homogenous_mat

            joint2_base, j2b_pos, j2b_euler, _ = track_data.homg_mat_mult(base_inv,joint2) #joint2 in base frame -> moves only in base Y+X axis
            joint3_base, j3b_pos, j3b_euler, _ = track_data.homg_mat_mult(base_inv,joint3) #joint3 in base frame
            joint4_base, j4b_pos, j4b_euler, _ = track_data.homg_mat_mult(base_inv,joint4) #joint4 in base frame

            joint2_base_quat = t3d.quaternions.mat2quat(joint2_base[:3,:3])
            joint3_base_quat = t3d.quaternions.mat2quat(joint3_base[:3,:3])
            joint4_base_quat = t3d.quaternions.mat2quat(joint4_base[:3,:3])
            joint2_base_quat = np.roll(joint2_base_quat, -1)
            joint3_base_quat = np.roll(joint3_base_quat, -1)
            joint4_base_quat = np.roll(joint4_base_quat, -1)

            optitrak_joint_base_positions = np.array([goal_positions[0], j2b_pos, j2b_pos, j3b_pos, j4b_pos]) * 2 # 2x multiplier
            optitrak_joint_base_positions[:,0] += 0.1 #0.1m translation in x
            optitrak_joint_base_quats = np.array([goal_orientations[0], joint2_base_quat, joint2_base_quat, joint3_base_quat, joint4_base_quat])

            joint3_joint2, j3j2_pos, j3j2_euler, _ = track_data.homg_mat_mult(joint2_inv,joint3)
            joint4_joint3, j4j3_pos, j4j3_euler, _ = track_data.homg_mat_mult(joint3_inv,joint4)
            target_joint4, targetj4_pos, targetj4_euler, _ = track_data.homg_mat_mult(joint4_inv,target)


            #---------------------------------------------
            #update vrep display
            #---------------------------------------------
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

                vrep.simxSetObjectPosition(
                    clientID,
                    robot_pose_handles[i],
                    -1,# Setting the absolute position
                    position=optitrak_joint_base_positions[i],
                    operationMode=vrep.simx_opmode_blocking
                    )

                vrep.simxSetObjectQuaternion(
                    clientID,
                    pose_handles[i],
                    -1,
                    goal_orientations[i], #(x, y, z, w)
                    operationMode = vrep.simx_opmode_blocking)

                vrep.simxSetObjectQuaternion(
                    clientID,
                    robot_pose_handles[i],
                    -1,
                    optitrak_joint_base_quats[i], #(x, y, z, w)
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