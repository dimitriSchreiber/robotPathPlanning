# -*- coding: utf-8 -*-
"""
Created on Wed Jul 25 17:45:22 2018

@author: snowl
"""
from NatNetClient import NatNetClient

from collections import deque
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.ticker import FuncFormatter

import time

max_x = 1000
max_rand = 5

positions = []
rotations = []
index = 0



data = deque(np.zeros(max_x), maxlen=max_x)  # hold the last 10 values
x = np.arange(0, max_x)

def init():
    line.set_ydata([np.nan] * len(x))
    return line,

def animate(i):
    # Add next value
    
    #data.append(np.random.randint(0, max_rand))
    
    line.set_ydata(data)
    #plt.savefig('e:\\python temp\\fig_{:02}'.format(i))
    print(i)
    return line,

def receiveNewFrame( frameNumber, markerSetCount, unlabeledMarkersCount, rigidBodyCount, skeletonCount,
                    labeledMarkerCount, timecode, timecodeSub, timestamp, isRecording, trackedModelsChanged ):
    print( "Received frame", frameNumber )

# This is a callback function that gets connected to the NatNet client. It is called once per rigid body per frame
def receiveRigidBodyFrame( id, position, rotation ):
    
    if id == 1:
       #print( "Received frame for rigid body", id )
        #print("Position: {}, Orientation: {}".format(position,rotation))
        positions.append(position)
        rotations.append(rotation)
        x_pos = position[0]*1000
        print('x position: {}'.format(x_pos))
        data.append(x_pos)
        '''
        if len(positions > max_x):
            positions = positions[-1*max_x:]
        if len(rotations > max_x):
            rotations = rotations[-1*max_x:]
        '''

streamingClient = NatNetClient()

# Configure the streaming client to call our rigid body handler on the emulator to send data out.
streamingClient.newFrameListener = receiveNewFrame
streamingClient.rigidBodyListener = receiveRigidBodyFrame

# Start up the streaming client now that the callbacks are set up.
# This will run perpetually, and operate on a separate thread.
#time.sleep(5)    

streamingClient.run()

time.sleep(0.5)

fig, ax = plt.subplots()
ax.set_ylim(-350, -50)
ax.set_xlim(0, max_x-1)
line, = ax.plot(x, np.random.randint(0, max_rand, max_x))
ax.xaxis.set_major_formatter(FuncFormatter(lambda x, pos: '{:.1f}s'.format(0.1*(max_x - x - 1))))
plt.xlabel('Seconds ago')

ani = animation.FuncAnimation(
    fig, animate, init_func=init, interval=100, blit=True, save_count=10)

plt.show()
