import pylab
import pandas as pd
import sys

def conv(x):
	ts = int(x[0:2]) * 3600 + int(x[3:5]) * 60 + int(x[6:8]) + int(x[9:12]) / 1000
	return ts

def ceildiv(x, d):
	return (x + d - 1) // d

if len(sys.argv) != 2:
	print("Syntax: plotter.py <csvfile>", file=sys.stderr)
	sys.exit(1)

df = pd.read_csv(sys.argv[1], header=None, names=["timestamp", "memory(MB)"])

df["memory(MB)"] /= 1048576
initms = conv(df["timestamp"][0])
df["time"] = df["timestamp"].apply(conv).apply(lambda x: x - initms)
#del df["timestamp"]
df = df.set_index("time")

df[["memory(MB)"]].plot(title="Container memory use over time and microbilling period") #This is the line

maxmb = df["memory(MB)"].max()
if maxmb > 128:
	possiblembs = ceildiv(maxmb - 128, 64)
	maxmbchosen = 128 + 64 * possiblembs
	if maxmbchosen > 3008:
		maxmbchosen = 3008
else:
	maxmbchosen = 128
	
#possiblembs = [128, 192, 256, 320, 384, 448, 512, 576, 640, 704, 768, 832, 896, 960, 1024, 1088, 1152, 1216, 1280, 1344, 1408, 1472, 1536, 1600, 1664]
#maxmbchosen = possiblembs[0]
#for possiblemb in possiblembs:
#	if maxmb < possiblemb and not maxmbchosen > maxmb:
#		maxmbchosen = possiblemb
print(maxmb, maxmbchosen)

maxms = df.index[-1]
maxmschosen = (int(maxms * 10) + 1) / 10
print(maxms, maxmschosen)

pylab.plot((0, len(df)), (maxmbchosen, maxmbchosen), label="memory-canvas")
pylab.plot((0, len(df)), (maxmb, maxmb), linestyle="dashed")
pylab.plot((maxmschosen, maxmschosen), (0, maxmbchosen), label="time-canvas")
pylab.plot((maxms, maxms), (0, maxmbchosen), linestyle="dashed")
pylab.xlim((0, maxmschosen * 1.02))

pylab.xlabel("time(s)")
pylab.ylabel("memory(MB)")
pylab.legend()
pylab.show()
