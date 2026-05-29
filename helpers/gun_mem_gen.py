from PIL import Image

try:
    img = Image.open("./pictrans/gun_01_dragonawp.png").convert('RGBA')
except Exception as e:
    print(f"err {e}")
img = img.resize((160, 120), Image.Resampling.NEAREST)
pixels = img.load()
with open("./final_proj/gun_01_tex.mem", 'w') as f:
    for y in range(120):
        for x in range(160):
            r, g, b, a = pixels[x, y]
            if a < 128: 
                hex_color = "F0F"
            else:
                r_vga = r >> 4
                g_vga = g >> 4
                b_vga = b >> 4
                hex_color = f"{r_vga:1X}{g_vga:1X}{b_vga:1X}"
            f.write(f"{hex_color}\n")

