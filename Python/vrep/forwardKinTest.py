# This example illustrates how to use the path/motion
# planning functionality from a remote API client.
#
# Load the demo scene 'motionPlanningServerDemo.ttt' in V-REP 
# then run this program.
#
# IMPORTANT: for each successful call to simxStart, there
# should be a corresponding call to simxFinish at the end!

import vrep
import numpy as np

print ('Program started')
vrep.simxFinish(-1) # just in case, close all opened connections
clientID=vrep.simxStart('127.0.0.1',19997,True,True,-500000,5) # Connect to V-REP, set a very large time-out for blocking commands
if clientID!=-1:
    print ('Connected to remote API server')

    emptyBuff = bytearray()

    # Start the simulation:
    vrep.simxStartSimulation(clientID,vrep.simx_opmode_oneshot_wait)

    # Load a robot instance:    res,retInts,retFloats,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',vrep.sim_scripttype_childscript,'loadRobot',[],[0,0,0,0],['d:/v_rep/qrelease/release/test.ttm'],emptyBuff,vrep.simx_opmode_oneshot_wait)
    #    robotHandle=retInts[0]
    
    # Retrieve some handles:
    res,robotHandle=vrep.simxGetObjectHandle(clientID,'IRB4600#1',vrep.simx_opmode_oneshot_wait) #robot model
    #res,robotHandle=vrep.simxGetObjectHandle(clientID,'Jaco#',vrep.simx_opmode_oneshot_wait) #robot model

    #goal poses/positions, these are set by the environment
    #res,target1=vrep.simxGetObjectHandle(clientID,'testPose1#',vrep.simx_opmode_oneshot_wait)
    res,target2=vrep.simxGetObjectHandle(clientID,'testPose2#',vrep.simx_opmode_oneshot_wait)
    #res,target3=vrep.simxGetObjectHandle(clientID,'testPose3#',vrep.simx_opmode_oneshot_wait)
    #res,target4=vrep.simxGetObjectHandle(clientID,'testPose4#',vrep.simx_opmode_oneshot_wait)

    # Retrieve the poses (i.e. transformation matrices, 12 values, last row is implicit) of some dummies in the scene
    #res,retInts,target1Pose,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',vrep.sim_scripttype_childscript,'getObjectPose',[target1],[],[],emptyBuff,vrep.simx_opmode_oneshot_wait)
    res,retInts,target2Pose,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',vrep.sim_scripttype_childscript,'getObjectPose',[target2],[],[],emptyBuff,vrep.simx_opmode_oneshot_wait)
    #res,retInts,target3Pose,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',vrep.sim_scripttype_childscript,'getObjectPose',[target3],[],[],emptyBuff,vrep.simx_opmode_oneshot_wait)
    #res,retInts,target4Pose,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',vrep.sim_scripttype_childscript,'getObjectPose',[target4],[],[],emptyBuff,vrep.simx_opmode_oneshot_wait)

    # Get the robot initial state:
    res,retInts,robotInitialState,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',vrep.sim_scripttype_childscript,'getRobotState',[robotHandle],[],[],emptyBuff,vrep.simx_opmode_oneshot_wait)


    print('Initial robot state: {}'.format(robotInitialState))
     # Some parameters:
    approachVector=[0,0,1] # often a linear approach is required. This should also be part of the calculations when selecting an appropriate state for a given pose, Z in end effector refernce frame?
    maxConfigsForDesiredPose=10 # we will try to find 10 different states corresponding to the goal pose and order them according to distance from initial state
    maxTrialsForConfigSearch=300 # a parameter needed for finding appropriate goal states
    searchCount=2 # how many times OMPL will run for a given task
    minConfigsForPathPlanningPath=400 # interpolation states for the OMPL path
    minConfigsForIkPath=100 # interpolation states for the linear approach path, IK is used for approach, but what about if there are collisions? Linear joint on the end is important
    collisionChecking=1 # whether collision checking is on or off
    # Collision checking off:
    collisionChecking=0

    # Find a linear path that runs through several poses:
    inInts=[robotHandle,collisionChecking,minConfigsForIkPath,minConfigsForPathPlanningPath,maxConfigsForDesiredPose,maxTrialsForConfigSearch,searchCount]
    path = np.linspace(0,-0.25, num=600)
    path += np.tile(robotInitialState, 100)
    res = 0

    if (res==0) and len(path)>0:
        # Visualize the path:
        res,retInts,retFloats,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,
            'remoteApiCommandServer',vrep.sim_scripttype_childscript,'visualizePath',
            [robotHandle,0,255,255],path,[],emptyBuff,vrep.simx_opmode_oneshot_wait)
        line1Handle=retInts[0]

        # Make the robot follow the path:
        res,retInts,retFloats,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',
            vrep.sim_scripttype_childscript,'runThroughPath',[robotHandle],path,[],emptyBuff,vrep.simx_opmode_oneshot_wait)

        # Wait until the end of the movement:
        runningPath=True
        while runningPath:
            res,retInts,retFloats,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',vrep.sim_scripttype_childscript,
                'isRunningThroughPath',[robotHandle],[],[],emptyBuff,vrep.simx_opmode_oneshot_wait)
            runningPath=retInts[0]==1

        # Clear the path visualization:
        res,retInts,retFloats,retStrings,retBuffer=vrep.simxCallScriptFunction(clientID,'remoteApiCommandServer',vrep.sim_scripttype_childscript,'removeLine',[line1Handle],[],[],emptyBuff,vrep.simx_opmode_oneshot_wait)

           # Stop simulation:
    vrep.simxStopSimulation(clientID,vrep.simx_opmode_oneshot_wait)

    # Now close the connection to V-REP:
    vrep.simxFinish(clientID)
else:
    print ('Failed connecting to remote API server')
    print ('Program ended')

