from threading import Thread
import spacenav
import atexit

class MouseClient:
	def __init__(self):
		self.running = False
		self.event = None
		self.button = None
		self.pressesd = None

	def mouseThreadFunction(self):
		try:
			# open the connection
			print("Opening connection to SpaceNav driver ...")
			spacenav.open()
			print("... connection established.")
			# register the close function if no exception was raised
			atexit.register(spacenav.close)
		except spacenav.ConnectionError:
			# give some user advice if the connection failed 
			print("No connection to the SpaceNav driver. Is spacenavd running?")
			sys.exit(-1)

		# reset exit condition
		stop = False

		# loop over space navigator events
		while not stop and self.running:
			# wait for next event
			event = spacenav.wait()

			# #if event signals the release of the first button
			# if type(event) is spacenav.ButtonEvent \
			# 	and event.button == 0 and event.pressed == 0:
			# 	# set exit condition
			# 	#stop = True

			if type(event) is spacenav.ButtonEvent:
				pass
			else:
				self.processdata(event)

	def processdata(self, event):
		self.event = [event.x, event.y, event.z, event.rx, event.ry, event.rz]


	def run(self):
		self.running = True

		mouseThread = Thread(target = self.mouseThreadFunction, args=())
		mouseThread.daemon = True #autimatically kills the thread when the main thread is finished
		mouseThread.start()

	def stop(self):
		self.running = False
