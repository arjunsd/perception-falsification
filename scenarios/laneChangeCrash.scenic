""" Scenario Description
Ego-vehicle performs a lane changing to evade a leading vehicle, which is moving too slowly,but crashes going into a car going in the lane next to it.
"""

#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map = localPath('../Scenic-devel/tests/formats/opendrive/maps/CARLA/Town05.xodr')  # or other CARLA map that definitely works
param carla_map = 'Town05'
model scenic.simulators.carla.model #located in scenic/simulators/carla/model.scenic

#CONSTANTS
EGO_SPEED = 20
FRONT_CAR_SPEED = 6
PARALLEL_CAR_SPEED = 10
EGO_TO_FRONT_CAR = 15
DIST_THRESHOLD = 15

## DEFINING BEHAVIORS
behavior EgoBehavior(leftpath, origpath=[]):
	#EGO BEHAVIOR: Follow lane, then perform a lane change once within DIST_THRESHOLD is breached and laneChange is yet completed
	laneChangeCompleted = False

	try: 
		do FollowLaneBehavior(EGO_SPEED)

	interrupt when withinDistanceToAnyObjs(self, DIST_THRESHOLD) and not laneChangeCompleted:
		do LaneChangeBehavior(laneSectionToSwitch=leftpath, target_speed=10)
		laneChangeCompleted = True

behavior frontCarBehavior():
	#OTHER CAR'S BEHAVIOR
	do FollowLaneBehavior(FRONT_CAR_SPEED)

behavior ParallelCarBehavior():
	#Parallel Car's Behavior
	do FollowLaneBehavior(PARALLEL_CAR_SPEED)


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

ego = Car at spawnPt,
	with behavior EgoSafeOvertakeBehavior2(EGO_SPEED, DIST_THRESHOLD, initLaneSec.lane) 

# Set a specific vehicle model for the Bicycle. 
# The referenceable types of vehicles supported in carla are listed in scenic/simulators/carla/model.scenic
frontCar = Car following roadDirection from ego for EGO_TO_FRONT_CAR,
	with behavior frontCarBehavior()

parallelCar = Truck at parallelSpawnPnt, #EgoBehavior(rightLane, [initLaneSec])
	with behavior ParallelCarBehavior()


#EXPLICIT HARD CONSTRAINTS
require (distance from ego to intersection) > 10
require (distance from frontCar to intersection) > 10