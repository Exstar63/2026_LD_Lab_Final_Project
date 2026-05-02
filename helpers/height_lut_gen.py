import math

N = 1024          # Table size (based on 12 bits of distance: Q8.4)
SCREEN_H = 240
PROJ_K = 240      # Projection constant (Height = K / Dist)

with open("./final_proj/height_lut.mem", "w") as f:
    for i in range(N):
        dist = max(i / 64.0, 0.0625) 
        height = int(round(PROJ_K / dist))
        if height > SCREEN_H:
            height = SCREEN_H
        f.write(f"{height:02X}\n")