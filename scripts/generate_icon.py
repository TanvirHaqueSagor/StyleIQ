"""
Generates the StyleIQ 1024x1024 app icon:
  - Purple (#534AB7) → Teal (#1D9E75) diagonal gradient background
  - Rounded corners (radius ≈ 22% of size)
  - Centred white coat-hanger silhouette
  - Small white sparkle (✦) in the top-right quarter
"""

import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
PURPLE = (83, 74, 183)
TEAL   = (29, 158, 117)
CORNER_RADIUS = int(SIZE * 0.22)   # ~226 px — matches the widget's 0.26 * size / 2


# ── 1. Diagonal gradient ──────────────────────────────────────────────────────
x_idx = np.arange(SIZE, dtype=np.float32)
y_idx = np.arange(SIZE, dtype=np.float32)
xx, yy = np.meshgrid(x_idx, y_idx)

# t = 0 at top-left, 1 at bottom-right
t = ((xx + yy) / (2.0 * (SIZE - 1))).clip(0, 1)

r = (PURPLE[0] + (TEAL[0] - PURPLE[0]) * t).astype(np.uint8)
g = (PURPLE[1] + (TEAL[1] - PURPLE[1]) * t).astype(np.uint8)
b = (PURPLE[2] + (TEAL[2] - PURPLE[2]) * t).astype(np.uint8)

grad = np.stack([r, g, b, np.full((SIZE, SIZE), 255, dtype=np.uint8)], axis=2)
icon = Image.fromarray(grad, mode='RGBA')


# ── 2. Rounded-corner mask ────────────────────────────────────────────────────
mask = Image.new('L', (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
md.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=CORNER_RADIUS, fill=255)
icon.putalpha(mask)


# ── 3. Draw hanger silhouette ─────────────────────────────────────────────────
draw = ImageDraw.Draw(icon, 'RGBA')

WHITE = (255, 255, 255, 255)
WHITE_90 = (255, 255, 255, 230)

cx = SIZE // 2          # 512
cy = SIZE // 2          # 512
UNIT = SIZE * 0.0078    # 1 "unit" ≈ 8 px at 1024

# --- Hook (small arc at the very top) ---
hook_w  = int(SIZE * 0.08)   # 82
hook_h  = int(SIZE * 0.06)   # 61
hook_t  = int(SIZE * 0.04)   # 41  (line thickness)
hook_y  = int(cy - SIZE * 0.26)
hook_box = [cx - hook_w, hook_y - hook_h, cx + hook_w, hook_y + hook_h]
draw.arc(hook_box, start=210, end=330, fill=WHITE, width=hook_t)

# --- Neck (short vertical from hook down to shoulders) ---
neck_x  = cx
neck_y1 = hook_y + int(hook_h * 0.85)
neck_y2 = int(cy - SIZE * 0.10)
neck_t  = int(hook_t * 0.85)
draw.line([neck_x, neck_y1, neck_x, neck_y2], fill=WHITE, width=neck_t)

# --- Left arm ---
arm_t   = neck_t
left_x  = int(cx - SIZE * 0.30)
arm_y   = int(cy + SIZE * 0.02)
draw.line([neck_x, neck_y2, left_x, arm_y], fill=WHITE, width=arm_t)

# --- Right arm ---
right_x = int(cx + SIZE * 0.30)
draw.line([neck_x, neck_y2, right_x, arm_y], fill=WHITE, width=arm_t)

# --- Horizontal crossbar at bottom of arms ---
bar_y2 = arm_y + int(SIZE * 0.04)
bar_t  = arm_t
draw.line([left_x, bar_y2, right_x, bar_y2], fill=WHITE, width=bar_t)

# Tiny end-caps on the crossbar
cap_r = int(arm_t * 0.8)
draw.ellipse([left_x - cap_r,  bar_y2 - cap_r, left_x + cap_r,  bar_y2 + cap_r], fill=WHITE)
draw.ellipse([right_x - cap_r, bar_y2 - cap_r, right_x + cap_r, bar_y2 + cap_r], fill=WHITE)

# --- Garment body (rounded rectangle below crossbar) ---
body_top    = bar_y2 + int(SIZE * 0.01)
body_bottom = int(cy + SIZE * 0.28)
body_left   = int(cx - SIZE * 0.22)
body_right  = int(cx + SIZE * 0.22)
body_r      = int(SIZE * 0.04)
body_t      = int(arm_t * 0.90)
draw.rounded_rectangle(
    [body_left, body_top, body_right, body_bottom],
    radius=body_r,
    outline=WHITE,
    width=body_t,
)


# ── 4. Sparkle (4-pointed star) in top-right ─────────────────────────────────
def draw_sparkle(draw, cx, cy, outer, inner, color):
    pts = []
    for i in range(8):
        angle = math.radians(i * 45 - 90)
        r = outer if i % 2 == 0 else inner
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(pts, fill=color)

sp_cx = int(cx + SIZE * 0.23)
sp_cy = int(cy - SIZE * 0.26)
draw_sparkle(draw, sp_cx, sp_cy, int(SIZE * 0.055), int(SIZE * 0.022), WHITE_90)

# Tiny dot sparkle accent
dot_r = int(SIZE * 0.018)
draw.ellipse(
    [sp_cx + int(SIZE * 0.08) - dot_r, sp_cy - dot_r,
     sp_cx + int(SIZE * 0.08) + dot_r, sp_cy + dot_r],
    fill=(255, 255, 255, 140),
)


# ── 5. Save ───────────────────────────────────────────────────────────────────
out_path = 'assets/icons/app_icon.png'
icon.save(out_path, 'PNG')
print(f'Saved {out_path}  ({SIZE}x{SIZE})')
