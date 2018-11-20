
# coding: utf-8

# In[ ]:


import sys
sys.path.append("..")
import numpy as np
import time
import vrep
import spacenav

from vrepRobot import VREP_Environement, VREP_Robot
from utils.mouse3d import MouseClient


# In[ ]:


mouse = MouseClient()
mouse.run()
print(mouse.event[:])

#mouse.stop()


# In[ ]:


vrep_env = VREP_Environement()

#Adding robots to scene
ik_handles = ['ik_joint1', 'ik_joint2', 'ik_joint3', 'ik_joint4', 'ik_joint5', 'ik_joint6', 'ik_joint7', 'ik_ee', 'kinematicsTest_IKTip', 'ik_rf7_static']
vrep_env.add_robot(VREP_Robot('ik_robot', ik_handles))

viz_handles = ['viz_joint1', 'viz_joint2', 'viz_joint3', 'viz_joint4', 'viz_joint5', 'viz_joint6', 'viz_joint7']
vrep_env.add_robot(VREP_Robot('viz_robot', viz_handles))




# In[ ]:


vrep_env.ik_robot.setObjectPosition(vrep_env.ik_robot.handles[7], [0,0,0], relative2 = 'ik_rf7_static' )
vrep_env.ik_robot.setObjectOrientation(vrep_env.ik_robot.handles[7], [0,0,0], relative2 = 'ik_rf7_static' )

vrep_env.ik_robot.setObjectPosition(vrep_env.ik_robot.handles[8], [0,0,0], relative2 = 'ik_rf7_static' )
vrep_env.ik_robot.setObjectOrientation(vrep_env.ik_robot.handles[8], [0,0,0], relative2 = 'ik_rf7_static' )



# In[ ]:


#Add all robot before starting the simulation - once robots are added start simulation
vrep_env.start_simulation()


# In[ ]:


position = np.zeros(3)
orientation = np.zeros(3)
joint_data = [0,0,0,0,0,0,0]

while True:
    #x,z,y,rx,rz,ry, meters and radians
    #0-500 regualr scaling on the mouse, max speed is 5 mm update
    #5 degs -> np.pi/180 * 5
    position[0] = position[0] + mouse.event[0] * .000001
    position[1] = position[1] + mouse.event[2] * .000001
    position[2] = position[2] + mouse.event[1] * .000001
    orientation[0] = orientation[0] + 0.001 * mouse.event[3] * np.pi/180
    orientation[1] = orientation[1] + 0.001 * mouse.event[5] * np.pi/180
    orientation[2] = orientation[2] + 0.001 * mouse.event[4] * np.pi/180
    
    position[position>0.1] = 0.1
    position[position<-0.1] = -0.1
    orientation[orientation>np.pi/2] = np.pi/2
    orientation[orientation<-np.pi/2] = -np.pi/2
    
    vrep_env.ik_robot.setObjectPosition(vrep_env.ik_robot.handles[7], position, relative2 = 'ik_rf7_static' )
    #vrep_env.ik_robot.setObjectOrientation(vrep_env.ik_robot.handles[7], orientation, relative2 = 'ik_rf7_static' )
    

    
    for i in range(len(viz_handles)):
        joint_pos = vrep_env.ik_robot.getJointPosition(vrep_env.ik_robot.handles[i])[1]
        joint_data[i] = joint_pos
        print("joint {}: {}".format(i+1,joint_pos))
        vrep_env.viz_robot.setJointPosition(vrep_env.viz_robot.handles[i], joint_pos)

    print("\n")

    time.sleep(0.01)
    

