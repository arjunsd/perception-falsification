'''
Example to control pedestrians across a road where the ego vehicle is going.
'''

#SET MAP AND MODEL
param map = localPath('../Scenic-devel/tests/formats/opendrive/maps/CARLA/Town05.xodr')  # or other CARLA map that definitely works
param carla_map = 'Town05'
model scenic.simulators.carla.model #located in scenic/simulators/carla/model.scenic

# constants
DISTANCE_TO_INTERSECTION = Uniform(8, 10) * -1
# DISTANCE_TO_INTERSECTION = VerifaiRange(-10, -8)
PED_SPEED = VerifaiRange(2,4)
SAFE_FOLLOW_THRESHOLD = 10


# behavior
behavior PedestrianBehavior(dest):
    do WalkTowardsPointsBehavior(dest, speed=PED_SPEED, stuck_behavior=JumpBehavior)


behavior EgoBehavior():
    do EgoPedestrianSafeFollowRoadBehavior(speed = 3, threshold = SAFE_FOLLOW_THRESHOLD)
    # do FollowLaneBehavior(3)
    



lanesWithCrossing = []
for lane in network.lanes:
    if (lane.group._sidewalk != None) and (lane.group.road.crossings != None):
        lanesWithCrossing.append(lane)

assert (len(lanesWithCrossing)>0)

print("lanes with crossing {}".format(lanesWithCrossing))

lane = Uniform(*lanesWithCrossing)


# scene
intersec = Uniform(*network.intersections)
startLane_select = Uniform(*intersec.incomingLanes)

# find lane for ego
startLane = Uniform(*startLane_select.group.lanes)
spwPt = lane.centerline[-1]

ego = Car following roadDirection from spwPt for DISTANCE_TO_INTERSECTION, with behavior EgoBehavior()

# find crossing for ped
sideWalk = ego.oppositeLaneGroup.sidewalk
target_sideWalk = ego.laneGroup.sidewalk


end_point = Point on visible target_sideWalk
end_point_2 = Point on target_sideWalk

ped = Pedestrian on visible sideWalk, with behavior PedestrianBehavior((end_point, ego.position))
# ped2 = Pedestrian at end_point
# ped3 = Pedestrian at end_point_2

require ego can see ped
# require ego can see ped2
# require (distance from ped2 to ped3) > 2


# print(ego.carla_actor.carla_actor.collision_sensor.history)