# -*- coding: utf-8 -*-
"""
Created on Tue Jan 22 12:03:35 2019

@author: ARCLab MRI Windows
"""

def setVrepPoses(n_poses, clientID, optitrak_joint_base_positions, optitrak_joint_base_quats, fk_positions, fk_orientations, robot_pose_handles, pose_handles):
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

	