"""Generate status effect icons for Lexica Spire (48x48 PNG, transparent bg)."""
from PIL import Image, ImageDraw, ImageFont
import os, math

OUT = "e:/github/slay_the_spire/godot/assets/sprites/ui/status"
SIZE = 48
PAD = 4

def circle_icon(color_bg, color_border, symbol_func):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Outer glow
    d.ellipse([2, 2, SIZE-3, SIZE-3], fill=(*color_bg[:3], 60))
    # Main circle
    d.ellipse([PAD, PAD, SIZE-PAD-1, SIZE-PAD-1], fill=color_bg, outline=color_border, width=2)
    symbol_func(d, img)
    return img

def draw_confusion(d, img):
    """Purple ? mark"""
    cx, cy = SIZE//2, SIZE//2
    # Question mark using arcs and lines
    r = 8
    # Arc of the ?
    d.arc([cx-r, cy-r-4, cx+r, cy+r-4], 180, 0, fill=(240, 232, 208), width=3)
    d.line([cx+r, cy-4, cx, cy+4], fill=(240, 232, 208), width=3)
    # Dot
    d.ellipse([cx-2, cy+8, cx+2, cy+12], fill=(240, 232, 208))

def draw_silence(d, img):
    """Grey X mark"""
    cx, cy = SIZE//2, SIZE//2
    off = 8
    col = (240, 232, 208)
    d.line([cx-off, cy-off, cx+off, cy+off], fill=col, width=3)
    d.line([cx+off, cy-off, cx-off, cy+off], fill=col, width=3)

def draw_strength(d, img):
    """Red sword"""
    cx, cy = SIZE//2, SIZE//2
    col = (240, 232, 208)
    # Blade
    d.line([cx, cy-12, cx, cy+6], fill=col, width=3)
    # Tip (triangle)
    d.polygon([cx, cy-14, cx-4, cy-8, cx+4, cy-8], fill=col)
    # Guard
    d.line([cx-7, cy+4, cx+7, cy+4], fill=col, width=3)
    # Handle
    d.line([cx, cy+6, cx, cy+13], fill=col, width=2)
    # Pommel
    d.ellipse([cx-2, cy+12, cx+2, cy+16], fill=col)

def draw_block(d, img):
    """Blue shield"""
    cx, cy = SIZE//2, SIZE//2
    col = (240, 232, 208)
    # Shield shape (pentagon-ish)
    points = [
        (cx - 10, cy - 10),
        (cx + 10, cy - 10),
        (cx + 10, cy + 2),
        (cx, cy + 13),
        (cx - 10, cy + 2),
    ]
    d.polygon(points, outline=col, width=2)
    # Inner cross on shield
    d.line([cx, cy-6, cx, cy+6], fill=col, width=2)
    d.line([cx-5, cy-1, cx+5, cy-1], fill=col, width=2)

icons = {
    "confusion": (
        (90, 62, 92, 220),   # purple bg
        (140, 100, 140),     # purple border
        draw_confusion,
    ),
    "silence": (
        (70, 70, 70, 220),   # dark grey bg
        (120, 120, 120),     # grey border
        draw_silence,
    ),
    "strength": (
        (139, 30, 30, 220),  # crimson bg
        (180, 60, 60),       # red border
        draw_strength,
    ),
    "block": (
        (46, 80, 144, 220),  # blue bg
        (70, 110, 180),      # blue border
        draw_block,
    ),
}

os.makedirs(OUT, exist_ok=True)
for name, (bg, border, func) in icons.items():
    img = circle_icon(bg, border, func)
    path = os.path.join(OUT, f"{name}.png")
    img.save(path)
    print(f"Created: {path}")

print("Done!")
