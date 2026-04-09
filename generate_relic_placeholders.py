"""Generate placeholder relic sprites for Lexica Spire (256x256 PNG, transparent bg)."""
from PIL import Image, ImageDraw, ImageFilter
import os

OUT = "e:/github/slay_the_spire/godot/assets/sprites/relics"
SIZE = 256


def gen_otherworldly_eye() -> None:
    """Otherworldly Eye placeholder: glowing eye in a dark circle with gold border."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2

    # Outer glow halo
    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.ellipse([8, 8, SIZE - 8, SIZE - 8], fill=(120, 70, 200, 90))
    halo = halo.filter(ImageFilter.GaussianBlur(radius=12))
    img.alpha_composite(halo)

    # Dark base disc
    d.ellipse([20, 20, SIZE - 20, SIZE - 20], fill=(20, 18, 32, 255))

    # Gold border ring
    d.ellipse([20, 20, SIZE - 20, SIZE - 20], outline=(212, 175, 55, 255), width=4)

    # Upper + lower eyelid (lens shape via two arcs forming an almond)
    # Eyelid shadow band
    d.ellipse([40, 80, SIZE - 40, SIZE - 80], fill=(245, 232, 208, 255))

    # Iris
    iris_color = (90, 50, 160, 255)  # purple
    d.ellipse([cx - 36, cy - 36, cx + 36, cy + 36], fill=iris_color)

    # Iris ring (lighter)
    d.ellipse([cx - 36, cy - 36, cx + 36, cy + 36], outline=(160, 110, 220, 255), width=3)

    # Pupil (vertical slit, otherworldly feel)
    d.ellipse([cx - 6, cy - 30, cx + 6, cy + 30], fill=(8, 4, 16, 255))

    # Highlight in iris
    d.ellipse([cx - 14, cy - 24, cx - 4, cy - 14], fill=(230, 220, 255, 220))

    # Eyelash hint at top (subtle)
    for off in (-50, -25, 0, 25, 50):
        d.line([(cx + off, 78), (cx + off + 4, 70)], fill=(40, 30, 20, 200), width=2)

    img.save(os.path.join(OUT, "otherworldly_eye.png"))
    print("Created: otherworldly_eye.png")


os.makedirs(OUT, exist_ok=True)
gen_otherworldly_eye()
print("Done!")
