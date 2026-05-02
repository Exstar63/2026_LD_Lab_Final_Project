import math

N = 256 # 8-bit angle resolution
with open("./helpers/sin_lut.mem", "w") as f:
    for i in range(N):
        theta = (i / N) * 2 * math.pi
        val = int(round(math.sin(theta) * 256))
        if val < 0:
            val = (1 << 16) + val
        f.write(f"{val:04X}\n")