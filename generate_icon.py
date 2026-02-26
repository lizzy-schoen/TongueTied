#!/usr/bin/env python3
"""Generate TongueTied app icon — simple cartoon tongue on dark purple."""

from PIL import Image, ImageDraw
import math

SIZE = 1024
SCALE = 4
BIG = SIZE * SCALE

img = Image.new("RGBA", (BIG, BIG))
draw = ImageDraw.Draw(img)

# --- Dark purple radial gradient background ---
cx, cy = BIG // 2, BIG // 2
for y in range(0, BIG, SCALE):
    for x in range(0, BIG, SCALE):
        dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2) / (BIG * 0.7)
        dist = min(dist, 1.0)
        r = int(40 - 18 * dist)
        g = int(28 - 14 * dist)
        b = int(62 - 20 * dist)
        # Fill SCALE x SCALE block
        for dy in range(SCALE):
            for dx in range(SCALE):
                img.putpixel((x + dx, y + dy), (r, g, b, 255))

draw = ImageDraw.Draw(img)

S = SCALE  # shorthand

tongue_color = (225, 85, 105, 255)
highlight_color = (242, 128, 142, 255)
groove_color = (195, 65, 85, 255)
line_color = (230, 195, 205, 255)

# --- Tongue body ---
body_left = 330 * S
body_right = 694 * S
body_top = 340 * S
body_bottom = 740 * S

draw.rectangle([body_left, body_top, body_right, body_bottom], fill=tongue_color)
draw.ellipse([body_left, body_bottom - 182*S, body_right, body_bottom + 182*S], fill=tongue_color)

# --- Highlight oval ---
draw.rounded_rectangle([405*S, 400*S, 619*S, 760*S], radius=107*S, fill=highlight_color)

# --- Center groove ---
draw.line([(512*S, 400*S), (512*S, 770*S)], fill=groove_color, width=5*S)

# --- Mouth curves: stamp circles along bezier path ---
def bezier_curve(pts, steps=300):
    result = []
    for i in range(steps + 1):
        t = i / steps
        x = (1-t)**3*pts[0][0] + 3*(1-t)**2*t*pts[1][0] + 3*(1-t)*t**2*pts[2][0] + t**3*pts[3][0]
        y = (1-t)**3*pts[0][1] + 3*(1-t)**2*t*pts[1][1] + 3*(1-t)*t**2*pts[2][1] + t**3*pts[3][1]
        result.append((x, y))
    return result

left_curve = bezier_curve([
    (195*S, 235*S),
    (215*S, 290*S),
    (270*S, 340*S),
    (330*S, 340*S),
], steps=400)

right_curve = bezier_curve([
    (694*S, 340*S),
    (754*S, 340*S),
    (809*S, 290*S),
    (829*S, 235*S),
], steps=400)

radius = 11 * S  # thickness of mouth line

for pts in [left_curve, right_curve]:
    for px, py in pts:
        draw.ellipse([px - radius, py - radius, px + radius, py + radius], fill=line_color)

# --- Downscale for anti-aliasing ---
final = img.resize((SIZE, SIZE), Image.LANCZOS)

output = "/Users/lizzyschoen/TongueTied/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
final.save(output, "PNG")
print(f"Saved {SIZE}x{SIZE} icon to {output}")
