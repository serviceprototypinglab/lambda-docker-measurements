#!/usr/bin/env python3

import pylab
import pandas as pd
import sys
import glob
import math
import json

def conv(x):
	ts = int(x[0:2]) * 3600 + int(x[3:5]) * 60 + int(x[6:8]) + int(x[9:12]) / 1000
	return ts

def ceildiv(x, d):
	return (x + d - 1) // d

""" if len(sys.argv) < 2:
	print("Syntax: plotter.py <csvfile> [<csvfile>...]", file=sys.stderr)
	sys.exit(1) """

# csvfiles = sys.argv[1:]
csvfiles = glob.glob("autostats*.csv")

ax = None
maxmb = None
maxms = None
hull = {}
l = "memory(MB)*"
for csvfile in csvfiles:
    df = pd.read_csv(csvfile, header=None, names=["timestamp", "memory(MB)", "limit(MB)"])

    df["memory(MB)"] /= 1048576
    initms = conv(df["timestamp"][0])
    df["time"] = df["timestamp"].apply(conv).apply(lambda x: x - initms)
    #del df["timestamp"]
    df = df.set_index("time")

    # Cut away default "unlimited" Docker limit of several petabytes...
    df["limit(MB)"][df["limit(MB)"] > 1000000000000] = 0
    df["limit(MB)"] /= 1048576

    if len(csvfiles) == 1:
        ax = df[["memory(MB)"]].plot() #This is the line
        ax.plot(df[["limit(MB)"]], color=(0.8, 0.8, 0.8), linewidth=5)
    else:
        # avoid multiple labels
        if not ax:
            fig = pylab.figure()
            ax = fig.add_subplot(1, 1, 1)
        ax.plot(df.index, df["memory(MB)"], color=(0.6, 0.6, 0.6), label=l)
        l = ""

    maxmblocal = df["memory(MB)"].max()
    if maxmb is None or maxmblocal > maxmb:
        maxmb = maxmblocal

    maxmslocal = df.index[-1]
    if maxms is None or maxmslocal > maxms:
        maxms = maxmslocal

    if len(csvfiles) > 1:
        for row in df.iterrows():
            #htime = int(row[0] * 10) / 10
            htime = round(row[0], 1)
            mem = row[1]["memory(MB)"]
            #print("-", mem, "@", row[0], "→", htime)
            if not math.isnan(mem) and (not htime in hull or mem > hull[htime]):
                hull[htime] = mem

if hull:
    hull = {k: hull[k] for k in sorted(hull)}
    print("Hull", hull)
    ax.plot(list(hull.keys()), list(hull.values()), color=(0, 0, 0), linewidth=3, label="memory-hull")
    uhull = {}
    hkeys = list(hull.keys())
    scaletime = 2
    for i in range(len(hkeys)):
        scale = 0
        if i < len(hkeys) - scaletime:
            if hull[hkeys[i + scaletime]] > hull[hkeys[i]]:
                scale = hull[hkeys[i + scaletime]] - hull[hkeys[i]]
        uhull[hkeys[i]] = hull[hkeys[i]] + scale
    print("u-Hull", hull)
    ax.plot(list(uhull.keys()), list(uhull.values()), color=(0.6, 0, 0), linewidth=2, label="memory-hull-upscale")

    f = open("uhull.json", "w")
    json.dump(uhull, f)
    f.close()

if maxmb > 128:
	possiblembs = ceildiv(maxmb - 128, 64)
	maxmbchosen = 128 + 64 * possiblembs
	if maxmbchosen > 3008:
		maxmbchosen = 3008
else:
	maxmbchosen = 128

maxmschosen = (int(maxms * 10) + 1) / 10
	
#possiblembs = [128, 192, 256, 320, 384, 448, 512, 576, 640, 704, 768, 832, 896, 960, 1024, 1088, 1152, 1216, 1280, 1344, 1408, 1472, 1536, 1600, 1664]
#maxmbchosen = possiblembs[0]
#for possiblemb in possiblembs:
#	if maxmb < possiblemb and not maxmbchosen > maxmb:
#		maxmbchosen = possiblemb
print("mem max", maxmb, "chosen", maxmbchosen, "MB")

print("time max", maxms, "chosen", maxmschosen, "s")

pylab.plot((0, len(df)), (maxmbchosen, maxmbchosen), label="memory-canvas")
pylab.plot((0, len(df)), (maxmb, maxmb), linestyle="dashed")
pylab.plot((maxmschosen, maxmschosen), (0, maxmbchosen), label="time-canvas")
pylab.plot((maxms, maxms), (0, maxmbchosen), linestyle="dashed")
pylab.xlim((0, maxmschosen * 1.02))

pylab.xlabel("time(s)")
pylab.ylabel("memory(MB)")
pylab.title("Container memory use over time and microbilling period")
pylab.legend()

pylab.show()
#pylab.savefig("x.pdf")
