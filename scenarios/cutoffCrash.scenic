""" Scenario Description
Ego-vehicle gets cutoff by another vehicle"""

#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map = localPath('../Scenic-devel/tests/formats/opendrive/maps/CARLA/Town10HD.xodr')  # or other CARLA map that definitely works
param carla_map = 'Town10HD'
model scenic.simulators.carla.model #located in scenic/simulators/carla/model.scenic

#CONSTANTS
EGO_SPEED = 5
OVERTAKE_CAR_INITIAL_SPEED = 20
OVERTAKE_CAR_FINAL_SPEED = 0
DIST_THRESHOLD = 15
# CUTOFF_THRESHOLD = VerifaiRange(5,10)
SAFE_THRESHOLD = 8
LARGE_THRESHOLD = 15
ABRUPT_STOP_DELAY = 0
TURN_DELAY = 15


## DEFINING BEHAVIORS
behavior EgoBehavior():
	#EGO BEHAVIOR: Follow lane, then perform a lane change once within DIST_THRESHOLD is breached and laneChange is yet completed
	# do FollowLaneBehavior(EGO_SPEED)
	# do EgoCutoffSafeFollowRoadBehavior(EGO_SPEED, SAFE_THRESHOLD)
	do EgoCutoffSafeFollowRoadBehavior2(EGO_SPEED, SAFE_THRESHOLD, LARGE_THRESHOLD)

behavior ParallelCarBehavior(origpath=[]):
	#Parallel Car's Behavior

	try: 
		
		do FollowLaneBehavior(OVERTAKE_CAR_INITIAL_SPEED)

			

	interrupt when (clearForOvertake(self, network.laneSectionAt(self)._laneToLeft, DIST_THRESHOLD) == True):
		do LaneChangeBehavior(laneSectionToSwitch=network.laneSectionAt(self)._laneToLeft, target_speed=10)
		do FollowLaneBehavior(OVERTAKE_CAR_INITIAL_SPEED) for ABRUPT_STOP_DELAY seconds
		take SetBrakeAction(1)
		do idleBehavior() for 6 seconds

## DEFINING SPATIAL RELATIONS
# Please refer to scenic/domains/driving/roads.py how to access detailed road infrastructure
# 'network' is the 'class Network' object in roads.py
laneSecsWithRightLane = []
for lane in network.lanes:
	for laneSec in lane.sections:
		if laneSec._laneToRight != None:
			laneSecsWithRightLane.append(laneSec)

assert len(laneSecsWithRightLane) > 0, \
	'No lane sections with adjacent left lane in network.'

# make sure to put '*' to uniformly randomly select from all elements of the list
initLaneSec = Uniform(*laneSecsWithRightLane)
rightLane = initLaneSec._laneToRight

#OJBECT PLACEMENT
spawnPt = initLaneSec.centerline[0]
parallelSpawnPnt = rightLane.centerline[0]

ego = Car at spawnPt, with behavior EgoBehavior()

# Set a specific vehicle model for the Bicycle. 
# The referenceable types of vehicles supported in carla are listed in scenic/simulators/carla/model.scenic
# print("initLane Sec lane {}".format(initLaneSec.lane))
parallelCar = Car at parallelSpawnPnt,
	with behavior ParallelCarBehavior([rightLane])


#EXPLICIT HARD CONSTRAINTS
require (distance from ego to intersection) > 20
require (distance from parallelCar to intersection) > 20