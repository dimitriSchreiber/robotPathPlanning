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
from motor_class import motors
from tcp_class import tcp_communication

#---------------------------------------------
#optitrak imports
#---------------------------------------------
import signal
import sys
import transforms3d as t3d
from copy import deepcopy
from GetJointData import data, NatNetFuncs#receiveNewFrame, receiveRigidBodyFrameList
from NatNetClient2 import NatNetClient
from AngleControl import MotorControl


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

# On Shutdown
def shutDown_vrep():
    vrep.simxStopSimulation(clientID, vrep.simx_opmode_blocking)
    vrep.simxFinish(clientID)

#---------------------------------------------
#constants
#---------------------------------------------
pi = np.pi
#TCP addresses
socket_ip = '192.168.1.39'
socket_port = 1122

#---------------------------------------------
#robot kinematics, jacobian class
#---------------------------------------------
myRobot = robot_config()

#robot joint positions
#q = [pi/8, pi/8, pi/8, 0]
q = np.array([0, 0., 0., 0.])
joint_angle_update_Kp = np.zeros(4)
joint_angle_update_Ki = np.zeros(4)

#arm_joint_command = q.copy()
#---------------------------------------------
#vrep setup
#---------------------------------------------
pose_names = ['pose_origin', 'pose_j1', 'pose_j2', 'pose_j3', 'pose_j4']
robot_pose_names = ['robot_origin', 'robot_j1', 'robot_j2', 'robot_j3', 'robot_j4', 'target']
n_poses = len(pose_names)

#---------------------------------------------
#main loop
#---------------------------------------------

try:

    #---------------------------------------------
    #motor control init
    #---------------------------------------------
 
    P=0.25
    PL=0
    I=0
    D = 0

    joint_motor_indexes = [0,1,2,3] #which motors are used to control the arm in order of joints

    MC = MotorControl(P, PL ,I,D,joint_motor_indexes, control_freq = 20)
    MC.tcp_init(socket_ip, socket_port)
    MC.motor_init()
    
    print("Arming motors now...")
    MC.motors.arm()
    time.sleep(2)

    #Zeros the arm to home position
    MC.zero_arm(track_data, NatNet)

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
        fk_orientations = np.zeros((n_poses, 4)) #4 for quat
        fk_orientations[0,-1] = 1
        fk_positions = np.zeros((n_poses, 3))
        fk_positions[1:,:] = myRobot.forwardKinPos(q) * 20
        fk_orientations[1:,:] = myRobot.forwardKinOrientation(q)

        #to check loop time:
        start_time_loop = time.time()

        while count < 1000:
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
   
                vrep.simxSetObjectPosition(
                    clientID,
                    robot_pose_handles[-1],
                    -1,# Setting the absolute position
                    position=optitrak_joint_base_positions[-1],
                    operationMode=vrep.simx_opmode_oneshot#vrep.simx_opmode_blocking
                    )

                vrep.simxSetObjectQuaternion(
                    clientID,
                    robot_pose_handles[-1],
                    -1,
                    optitrak_joint_base_quats[-1], #(x, y, z, w)
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
            EE_position_optitrak = optitrak_joint_base_positions[n_poses-1, :]
            EE_position_fk = fk_positions[n_poses-1, :]
            Kp = np.array([0.2, 0.2, 0.2])*0.05#*0.01 #0.1 is for I #* 10
            Ki = np.array([0.05, 0.05, 0.05])*dt*5

            EE_position_fk = optitrak_joint_base_positions[-1]
            joint_angle_update_Kp = np.matmul(JEE_optitrak_inv,(EE_position_fk - EE_position_optitrak) * Kp)# * dt
            joint_angle_update_Ki += np.matmul(JEE_optitrak_inv,(EE_position_fk - EE_position_optitrak) * Ki)

            print(joint_angle_update_Kp)
            print(joint_angle_update_Ki)
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
                #arm_offset = np.array([0., 0., 0., 75])
                arm_joint_command = q.copy() + joint_angle_update_Kp + joint_angle_update_Ki
                #arm_joint_command[:3] += joint_angle_update[:3]
                arm_joint_command[3] = arm_joint_command[3]*1000
                #arm_joint_command[3] = arm_joint_command[3] * 1000# + 75

                MC.update(arm_joint_command, arm_joint_command)

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