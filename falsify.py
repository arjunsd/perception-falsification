import time
import numpy as np
from dotmap import DotMap
import sys

from verifai.samplers.scenic_sampler import ScenicSampler
from verifai.scenic_server import ScenicServer
from verifai.falsifier import generic_falsifier
from verifai.monitor import specification_monitor
from verifai.falsifier import mtl_falsifier

def specification(traj):
    min_dist = np.inf
    for timestep in traj:
        print("timestep = {}".format(timestep))
        obj1, obj2, obj3, obj4 = timestep
        objects = [obj2,obj3,obj4,obj5]
        min_dist = 1000
        for obj in objects:
            dist = obj1.distanceTo(obj)
        min_dist = min(min_dist, dist)
        # obj1, obj2 = timestep
        # dist = obj1.distanceTo(obj2)
        # min_dist = min(min_dist, dist)
    print(f'min_dist = {min_dist}')
    return min_dist

def main():

    # path = '../Scenic-devel/examples/carla/pedestrian.scenic'
    path = 'fullScenario.scenic'
    sampler = ScenicSampler.fromScenario(path)
    falsifier_params = DotMap(
        n_iters=1,
        save_error_table=True,
        save_safe_table=True,
        error_table_path = "failures_file.txt",
    )
    falsifier_params.fal_thres =4
    # falsifier_params.fal_thres = 7
    server_options = DotMap(maxSteps=800, verbosity=0)
    falsifier = generic_falsifier(sampler=sampler,
                                  falsifier_params=falsifier_params,
                                  server_class=ScenicServer,
                                  server_options=server_options,
                                  monitor=specification_monitor(specification))
    t0 = time.time()
    falsifier.run_falsifier()
    t = time.time() - t0
    print(f'Generated {len(falsifier.samples)} samples in {t} seconds with 1 worker')
    print(f'Number of counterexamples: {len(falsifier.error_table.table)}')
    # f = open("failures_file.txt", "w")
    # f.write(falsifier.error_table.table)
    # f.close()

if __name__ == '__main__':
    main()
