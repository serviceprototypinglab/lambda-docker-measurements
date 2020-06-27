import json
import sys
import time
import os

container = sys.argv[1]
uhull = sys.argv[2]

print("{autotune} container", container, "with", uhull)

f = open(uhull)
tune = json.load(f)
print("{autotune}", len(tune), "steps")

numsteps = 0
oldstep = None
s_time = time.time()
while True:
    n_time = str(round(time.time() - s_time, 1))
    if n_time in tune and n_time != oldstep:
        print("{autotune} step", n_time, tune[n_time])
        os.system(f"docker update --memory {tune[n_time]}M {container} >/dev/null")
        oldstep = n_time
        numsteps += 1
    if numsteps == len(tune):
        break
    time.sleep(0.01)
