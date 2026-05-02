import math

# Parameters
N = 256           # Table size (based on 8 bits of distance: Q4.4)
SCREEN_H = 240    # Basys 3 internal vertical resolution
PROJ_K = 240      # Projection constant (Height = K / Dist)

with open("./helpers/height_lut.mem", "w") as f:
    for i in range(N):
        dist = max(i / 16.0, 0.0625) 
        height = int(round(PROJ_K / dist))
        if height > SCREEN_H:
            height = SCREEN_H
        f.write(f"{height:02X}\n")