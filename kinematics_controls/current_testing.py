#puts above directory into the path
import sys
sys.path.append("..")

import time
from datetime import date
import os
import signal
import numpy as np
import matplotlib.pyplot as plt

from utils.motor_setup import Motors

def signal_handler(signal, frame):
	motors.tcp_close()

signal.signal(signal.SIGINT, signal_handler)

script_dir = os.path.dirname(__file__)
results_dir = os.path.join(script_dir, 'Current_data/')
if not os.path.isdir(results_dir):
    os.makedirs(results_dir)

#Constants
socket_ip = '192.168.1.20'
socket_port = 1122

P = 0
PL = 0
I = 0
IL = 0
D = 0
motors = Motors(P ,PL ,I, IL ,D)
motors.tcp_init(socket_ip, socket_port)
print("Arming motors now...")
motors.arm_motors()
time.sleep(1)


#------------------------------
#Current Readings
#------------------------------
sensing_time = 15 #seconds
torque_constant = 0.0566 #mNm / mA
gear_ratio = 20
time_vals = []
current_vals = []
start_time = time.time()


enc_position = np.zeros(8)
while(time.time()-start_time < sensing_time):
	enc_position = enc_position + 100
	motors.command_motors(enc_position)
	#motors.command_motors(np.zeros(8))
	current = 1000*motors.avg_current
	time_vals.append(time.time()-start_time)
	current_vals.append(current)
	print("{:.3f} mA".format(current))
	time.sleep(0.01)

time_vals = np.array(time_vals)
current_vals = np.array(current_vals)
torque_vals = current_vals * torque_constant * gear_ratio

fig = plt.figure()
ax1 = fig.add_subplot(121)
ax1.plot(time_vals, current_vals)
ax1.set_xlabel("Time (seconds)")
ax1.set_ylabel("Current (mA)")
ax2 = fig.add_subplot(122)
ax2.plot(time_vals, torque_vals)
ax2.set_xlabel("Time (seconds)")
ax2.set_ylabel("Torque (mNm)")

plt.show()
fig.savefig(results_dir + 'current_data_' + str(date.today()) + '.png')
#------------------------------
#------------------------------

print("done")
motors.tcp_close()