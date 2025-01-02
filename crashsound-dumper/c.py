import sys
import glob
if len(sys.argv) < 2:
    print("usage: ./majority.py <glob_pattern>")
    sys.exit(1)

files = []
for fn in glob.glob(sys.argv[1]):
    with open(fn, 'rb') as f:
        files.append(f.read())

print("majority vote across %i outfiles" % len(files))

result = []
for i in range(0, 1024*1024*16):
    histogram = {}
    for d in files:
        if d[i] not in histogram: histogram[d[i]] = 0
        histogram[d[i]] += 1
    sorted_hist = sorted([(y, x) for x, y in histogram.items()], reverse=True)
    result.append(sorted_hist[0][1])
    if i % 10000 == 0:
        print("\r%.2f%%" % ((i/(1024*1024*16))*100), end="", flush=True)
print("\rdone         ", flush=True)

with open("result.gba", "wb") as f:
    f.write(bytes(result))
with open("real.gba", "rb") as f:
    data_real = f.read()

successes = 0
failures = 0
for i in range(0, 1024*1024*16):
    if data_real[i] == result[i]: successes += 1
    else: failures += 1

print("%i/%i (%.4f%%)" % (successes, failures, (successes/(successes+failures))*100))
