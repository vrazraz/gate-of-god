"""Generate gradient + thematic pattern PNGs for the transition shader.

Outputs (godot/assets/sprites/ui/transitions/):
  - gradient_radial.png  : iris wipe (dark center -> bright edges)
  - gradient_linear.png  : diagonal wipe (dark top-left -> bright bottom-right)
  - pattern_cuneiform.png: tileable cuneiform wedges (Sumerian script motif)
  - pattern_ziggurat.png : tileable stepped diamond (ziggurat top-down motif)

Pattern textures are stored as distance-field-like maps (bright at shape centers,
fading to black at edges) so the transition shader can grow shapes outward from
their centers as the gradient front passes over them.
"""
from PIL import Image, ImageDraw, ImageFilter
import math
import os

OUT = "e:/github/slay_the_spire/godot/assets/sprites/ui/transitions"


# --- Gradients (define the SHAPE of the transition) -------------------------

def gen_radial() -> None:
    """Iris wipe. Dark center -> bright edges. Center reveals first."""
    size = 256
    img = Image.new("L", (size, size), 0)
    px = img.load()
    cx, cy = (size - 1) / 2.0, (size - 1) / 2.0
    max_d = math.sqrt(cx * cx + cy * cy)
    for y in range(size):
        for x in range(size):
            d = math.sqrt((x - cx) ** 2 + (y - cy) ** 2) / max_d
            px[x, y] = int(255 * min(1.0, d))
    img.save(os.path.join(OUT, "gradient_radial.png"))
    print("Created: gradient_radial.png")


def gen_linear() -> None:
    """Diagonal wipe. Dark top-left -> bright bottom-right."""
    size = 256
    img = Image.new("L", (size, size), 0)
    px = img.load()
    denom = 2.0 * (size - 1)
    for y in range(size):
        for x in range(size):
            px[x, y] = int(255 * (x + y) / denom)
    img.save(os.path.join(OUT, "gradient_linear.png"))
    print("Created: gradient_linear.png")


# --- Patterns (tileable distance-field-like maps) ----------------------------

def _tileable_blur(img: Image.Image, radius: float) -> Image.Image:
    """Gaussian-blur a tile while keeping it seamlessly tileable.

    Pads the tile with copies of itself in 3x3 layout, blurs the whole thing,
    then crops the center cell. Edge bleed from neighbors is identical to what
    you'd see at runtime when the texture is sampled with repeat_enable.
    """
    w, h = img.size
    tiled = Image.new("L", (w * 3, h * 3))
    for ty in range(3):
        for tx in range(3):
            tiled.paste(img, (tx * w, ty * h))
    blurred = tiled.filter(ImageFilter.GaussianBlur(radius=radius))
    return blurred.crop((w, h, w * 2, h * 2))


def gen_cuneiform() -> None:
    """Tileable cuneiform wedges (Sumerian script), as a soft distance field.

    Bright wedge cores on dark background. Gaussian-blurred so each wedge has
    a smooth falloff — the shader uses this falloff to grow each wedge outward
    from its center as the transition front passes over it.
    """
    size = 64
    img = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(img)
    # Horizontal wedge (pointing right) - top-left
    d.polygon([(6, 10), (22, 14), (6, 18)], fill=255)
    # Vertical wedge (pointing down) - top-right
    d.polygon([(40, 6), (44, 22), (48, 6)], fill=255)
    # Oblique wedge - middle
    d.polygon([(26, 30), (38, 34), (32, 44)], fill=255)
    # Horizontal wedge - bottom-right
    d.polygon([(42, 46), (58, 50), (42, 54)], fill=255)
    # Small vertical wedge - bottom-left
    d.polygon([(8, 42), (12, 56), (16, 42)], fill=255)
    # Distance-field via tileable Gaussian blur
    blurred = _tileable_blur(img, radius=3.5)
    # Stretch contrast so peak stays near 255
    blurred = blurred.point(lambda v: min(255, int(v * 2.2)))
    blurred.save(os.path.join(OUT, "pattern_cuneiform.png"))
    print("Created: pattern_cuneiform.png")


def gen_ziggurat() -> None:
    """Tileable stepped diamond (ziggurat seen from above), as a soft distance field.

    Solid central diamond gradually falls off to black via Gaussian blur.
    The rings/steps are implicit in the smooth falloff; shapes grow outward
    from the diamond center as the transition front passes.
    """
    size = 64
    img = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(img)
    cx, cy = (size - 1) / 2.0, (size - 1) / 2.0
    # Single solid diamond, smaller than tile so blur has room to fade out
    half = 14
    d.polygon(
        [(cx, cy - half), (cx + half, cy), (cx, cy + half), (cx - half, cy)],
        fill=255,
    )
    blurred = _tileable_blur(img, radius=4.0)
    blurred = blurred.point(lambda v: min(255, int(v * 2.0)))
    blurred.save(os.path.join(OUT, "pattern_ziggurat.png"))
    print("Created: pattern_ziggurat.png")


os.makedirs(OUT, exist_ok=True)
gen_radial()
gen_linear()
gen_cuneiform()
gen_ziggurat()
print("Done!")
