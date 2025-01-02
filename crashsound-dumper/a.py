from scipy.io import wavfile
import sys

if len(sys.argv) < 2:
    print("usage: ./dump.py <data_file>")
    sys.exit(1)

sps, data = wavfile.read(sys.argv[1])
l = len(data)

print(sps, data[0:100])

peak_h = 0
peak_l = 0
thresholds = []

# !!!!!!!!!! INDIVIDUALLY ADJUST THESE DEPENDING ON YOUR INPUT DATA !!!!!!!!!!!
SAMPLES_PER_BYTE = 13
AVERAGE_OVER = 6
THRESHOLD = 1000
PEAK_AVERAGE_OVER = 4
DISTANCE_BETWEEN_THRESHOLDS = 4

last_threshold = 0
threshold_lengths = []

# find obvious timestamps where bytes change values
# also find peaks
for i in range(0, l-PEAK_AVERAGE_OVER):
    if abs(int(data[i]) - int(data[i+1])) > THRESHOLD and i > last_threshold + DISTANCE_BETWEEN_THRESHOLDS:
        # found a threshold
        thresholds.append(i)
        # look for average sample values after thresholds
        offs = i + SAMPLES_PER_BYTE // 2 - PEAK_AVERAGE_OVER // 2
        avg_peak = int(sum(data[offs:offs+PEAK_AVERAGE_OVER]) / PEAK_AVERAGE_OVER)
        if avg_peak > peak_h:
            peak_h = avg_peak
        if avg_peak < peak_l:
            peak_l = avg_peak
        # if it's a simple threshold (less than 2*SAMPLES_PER_BYTE-1)
        # then we can use it to compute "real samples per byte"
        if abs(i - last_threshold) < 2*SAMPLES_PER_BYTE-1:
            threshold_lengths.append(abs(i - last_threshold))
        # update last vars
        last_threshold = i
    if i % 10000 == 0:
        print("\rscan 1: %.1f%%" % ((i/l)*100), end="", flush=True)
print("\rscan 1: done (%i)  " % len(thresholds), flush=True)

AVERAGE_SAMPLES_PER_BYTE = sum(threshold_lengths) / len(threshold_lengths)

print("determined the real samp/byte ratio as %.4f" % AVERAGE_SAMPLES_PER_BYTE)
print("hpeak: %i | lpeak: %i" % (peak_h, peak_l)) 

# find points to sample from

sample_points = []
last_threshold = 0
for threshold in thresholds:
    # how many extra samples are supposed to be in that interval?
    num_points = int(round(abs(last_threshold - threshold) / AVERAGE_SAMPLES_PER_BYTE))
    # get locations to sample from
    points = [int(last_threshold + round(AVERAGE_SAMPLES_PER_BYTE*i + AVERAGE_SAMPLES_PER_BYTE/2) + 1) for i in range(0, num_points)]
    # add that to the list
    sample_points += points
    last_threshold = threshold
    print("\rscan 2: %i sample points" % len(sample_points), end="", flush=True)
print("\rscan 2: %i sample points" % len(sample_points), flush=True)

out = []

for at in sample_points:
    # try to read the value
    offset = at - SAMPLES_PER_BYTE // 2 - AVERAGE_OVER // 2
    average_val = sum(data[offset:offset+AVERAGE_OVER]) / AVERAGE_OVER
    # try to convert it into a signed U2 byte on a linear scale
    if average_val < 0:
        # lower half
        result = 0x100 + int(round(-128 * (average_val / peak_l)))
        if result == 0x100: result = 0
    else:
        # higher half
        result = int(round(127 * (average_val / peak_h)))
    out.append(result)
    print("\rscan 3: %.1f%%" % ((at/l)*100), end="", flush=True)
print("\rscan 3: done (%i)  " % len(out))

# save it
with open(sys.argv[1].replace(".wav",".bin"), "wb") as f:
    f.write(bytes(out))