""" Scenario Description
Ego-vehicle performs a lane changing to evade a leading vehicle, which is moving too slowly,but crashes going into a car going in the lane next to it.
"""

#SET MAP AND MODEL (i.e. definitions of all referenceable vehicle types, road library, etc)
param map = localPath('../Scenic-devel/tests/formats/opendrive/maps/CARLA/Town05.xodr')  # or other CARLA map that definitely works
param carla_map = 'Town05'
model scenic.simulators.carla.model #located in scenic/simulators/carla/model.scenic

#CONSTANTS
EGO_SPEED = 10
FRONT_CAR_SPEED = 6
PARALLEL_CAR_SPEED = 10
OTHER_CAR = 5
EGO_TO_FRONT_CAR = 10
OTHER_TO_PARALLEL_CAR = 30
DIST_THRESHOLD = 15
PED_DIST_THRESHOLD = 15
PEDESTRIAN_SPEED = 3

## DEFINING BEHAVIORS
behavior EgoBehavior(speed, ped_threshold, frontThreshold, currentLane):
	#EGO BEHAVIOR: Follow lane, then perform a lane change once within DIST_THRESHOLD is breached and laneChange is yet completed
	do FollowLaneBehavior(speed) for 2 seconds
	do fullSafeAutopilot3(speed, ped_threshold, frontThreshold, currentLane)
	

behavior frontCarBehavior():
	#OTHER CAR'S BEHAVIOR
	do FollowLaneBehavior(FRONT_CAR_SPEED)

behavior ParallelCarBehavior():
	#Parallel Car's Behavior
	do FollowLaneBehavior(PARALLEL_CAR_SPEED)

behavior PedestrianBehavior(dest, speed):
    do WalkTowardsPointsBehavior(dest, speed=speed, stuck_behavior=JumpBehavior)


## DEFINING SPATIAL RELATIONS
# Please refer to scenic/domains/driving/roads.py how to access detailed road infrastructure
# 'network' is the 'class Network' object in roads.py
laneSecsWithRightLane = []
for lane in network.lanes:
	if (lane.group._sidewalk is not None) and (lane.group._opposite is not None) and (lane.group._opposite._sidewalk is not None):
		for laneSec in lane.sections:
			if laneSec._laneToRight != None:
				laneSecsWithRightLane.append(laneSec)

print(laneSecsWithRightLane)
assert len(laneSecsWithRightLane) > 0, \
	'No lane sections with adjacent left lane in network.'

# make sure to put '*' to uniformly randomly select from all elements of the list
initLaneSec = Uniform(*laneSecsWithRightLane)
rightLane = initLaneSec._laneToRight

#OJBECT PLACEMENT
spawnPt = initLaneSec.centerline[0]
parallelSpawnPnt = rightLane.centerline[0]

ego = Car at spawnPt,
	with behavior EgoBehavior(EGO_SPEED, PED_DIST_THRESHOLD, DIST_THRESHOLD, initLaneSec.lane) 

# Set a specific vehicle model for the Bicycle. 
# The referenceable types of vehicles supported in carla are listed in scenic/simulators/carla/model.scenic
frontCar = Car following roadDirection from ego for EGO_TO_FRONT_CAR,
	with behavior frontCarBehavior()

parallelCar = Truck at parallelSpawnPnt, #EgoBehavior(rightLane, [initLaneSec])
	with behavior ParallelCarBehavior()

otherCar  = Car following roadDirection from parallelCar for OTHER_TO_PARALLEL_CAR,
	with behavior FollowLaneBehavior()

sideWalk = ego.oppositeLaneGroup.sidewalk
target_sideWalk = ego.laneGroup.sidewalk


end_point = Point on visible target_sideWalk
end_point_2 = Point on target_sideWalk

# ped = Pedestrian on visible sideWalk, with behavior PedestrianBehavior((end_point, ego.position), PEDESTRIAN_SPEED)



#EXPLICIT HARD CONSTRAINTS
require (distance from ego to intersection) > 10
require (distance from frontCar to intersection) > 10