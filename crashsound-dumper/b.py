import sys

NUM_SEQ = 0x8000

if len(sys.argv) < 2:
    print("usage: ./reconstruct.py <data_file>")
    sys.exit(1)

print("calculating sequence points for real ROM")
seq_real = []
last_sec = 0
with open('real.gba', 'rb') as f:
    data_real = f.read()
    last = 0
    cnt = 0
    for i in range(0, len(data_real)):
        if data_real[i] == last:
            cnt += 1
        else:
            if cnt > NUM_SEQ:
                seq_real.append((last_sec, i-last_sec-NUM_SEQ))
                last_sec = i
            cnt = 0
        last = data_real[i]

print("calculating sequence points for input data")
seq_inp = []
last_sec = 0
with open(sys.argv[1], 'rb') as f:
    data = f.read()
    last = 0
    cnt = 0
    for i in range(0, len(data)):
        if data[i] == last:
            cnt += 1
        else:
            if cnt > NUM_SEQ:
                seq_inp.append((last_sec, -1))
                last_sec = i
            cnt = 0
        last = data[i]

print(seq_real)
print(seq_inp)

result = [0] * (1024*1024*16)
for i in range(0, len(seq_real)):
    target_addr, target_size = seq_real[i]
    input_addr, input_size = seq_inp[i]
    for j in range(0, target_size):
        r = data[input_addr + j]
        result[target_addr + j] = r

outfname = sys.argv[1].replace(".bin",".gba")
with open(outfname, "wb") as f:
    f.write(bytes(result))

successes = 0
failures = 0
for i in range(0, 1024*1024*16):
    if data_real[i] == result[i]: successes += 1
    else: failures += 1

print("%i/%i (%.2f%%)" % (successes, failures, (successes/(successes+failures))*100))
