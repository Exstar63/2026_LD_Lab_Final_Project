from PIL import Image

try:
    img = Image.open("./pictrans/wall_01_brickwall.png").convert('RGBA')
except Exception as e:
    print(f"err {e}")
img = img.resize((64, 64), Image.Resampling.NEAREST)
pixels = img.load()
with open("./final_proj/wall_01_tex.mem", 'w') as f:
    for y in range(64):
        for x in range(64):
            r, g, b, a = pixels[x, y]
            r_vga = r >> 4
            g_vga = g >> 4
            b_vga = b >> 4
            hex_color = f"{r_vga:1X}{g_vga:1X}{b_vga:1X}"
            f.write(f"{hex_color}\n")

