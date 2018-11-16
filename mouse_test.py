from mouse3d_multiproc import MouseClient
import time
import spacenav
import atexit


mouse = MouseClient()
mouse.run()

while(True):
	print(mouse.event[:])

for i in range(20):
	if mouse.event == None:
		print("nothing!")
	else:
		print(mouse.event[:])
	time.sleep(0.5)


print("stopping mouse")
mouse.stop()


# spacenav.open()
# for i in range(10):
# 	event = spacenav.wait()
# 	print(event)
# 	time.sleep(0.5)