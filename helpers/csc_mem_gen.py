import math

N = 256 # 8-bit angle resolution
MAX_VAL = 0x7FFF # Cap at 32767 for overflow
with open("./Final/helpers/csc_lut.mem", "w") as f:
    for i in range(N):
        theta = (i / N) * 2 * math.pi
        s = math.sin(theta)
        if abs(s) < 0.0001:
            val = MAX_VAL
        else:
            csc = abs(1.0 / s)
            val = int(round(csc * 256))
            if val > MAX_VAL:
                val = MAX_VAL
        f.write(f"{val:04X}\n")