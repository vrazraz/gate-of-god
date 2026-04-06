"""Generate card frame/background PNGs for Lexica Spire (140x200, transparent corners)."""
from PIL import Image, ImageDraw
import os

OUT = "e:/github/slay_the_spire/godot/assets/sprites/cards"
W, H = 140, 200
RADIUS = 10

# Card type colors from FRONTEND.md
FRAMES = {
    "card_frame_attack": {
        "bg": (244, 232, 208),        # parchment
        "border": (139, 30, 30),       # crimson
        "accent": (170, 50, 50),       # lighter crimson
    },
    "card_frame_skill": {
        "bg": (244, 232, 208),
        "border": (46, 80, 144),       # blue
        "accent": (70, 110, 180),
    },
    "card_frame_power": {
        "bg": (244, 232, 208),
        "border": (45, 95, 63),        # emerald
        "accent": (60, 130, 80),
    },
    "card_frame_curse": {
        "bg": (220, 210, 225),         # slightly purple tinted parchment
        "border": (90, 62, 92),        # curse purple
        "accent": (120, 80, 120),
    },
}


def rounded_rect(draw, xy, radius, fill, outline=None, outline_width=0):
    """Draw a rounded rectangle."""
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=outline_width)


def generate_frame(name, colors):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bg = colors["bg"]
    border = colors["border"]
    accent = colors["accent"]

    # Outer border (full card shape)
    d.rounded_rectangle([0, 0, W-1, H-1], radius=RADIUS, fill=border)

    # Inner parchment area (3px border)
    d.rounded_rectangle([3, 3, W-4, H-4], radius=RADIUS-2, fill=bg)

    # Top accent strip (card header area)
    d.rounded_rectangle([3, 3, W-4, 34], radius=RADIUS-2, fill=(*accent, 40))

    # Art frame area (dark inset)
    d.rectangle([9, 35, W-10, 119], fill=(*border, 30))
    d.rectangle([10, 36, W-11, 118], fill=(0, 0, 0, 0))

    # Bottom separator line
    d.line([(10, 124), (W-11, 124)], fill=(*border, 120), width=1)

    # Bottom accent strip (description area tint)
    d.rounded_rectangle([3, 150, W-4, H-4], radius=RADIUS-2, fill=(*accent, 20))

    # Inner border line for elegance
    d.rounded_rectangle([5, 5, W-6, H-6], radius=RADIUS-3, outline=(*border, 80), width=1)

    path = os.path.join(OUT, f"{name}.png")
    img.save(path)
    print(f"Created: {path}")


os.makedirs(OUT, exist_ok=True)
for name, colors in FRAMES.items():
    generate_frame(name, colors)

print("Done!")
