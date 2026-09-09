"""Generate RoastLine app icon + splash logo (dijalankan sekali).
python tool/make_icon.py
"""
from PIL import Image, ImageDraw
import os

MAROON = (139, 30, 36, 255)
WHITE = (255, 255, 255, 255)
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "branding")
os.makedirs(OUT, exist_ok=True)


def flame(draw, cx, cy, s, color):
    """Bentuk api sederhana: badan tetesan + lidah dalam."""
    outer = [
        (cx, cy - s),
        (cx + 0.62 * s, cy - 0.05 * s),
        (cx + 0.72 * s, cy + 0.55 * s),
        (cx + 0.30 * s, cy + s),
        (cx - 0.30 * s, cy + s),
        (cx - 0.72 * s, cy + 0.55 * s),
        (cx - 0.62 * s, cy - 0.05 * s),
    ]
    draw.polygon(outer, fill=color)
    draw.ellipse([cx - 0.72 * s, cy + 0.1 * s, cx + 0.72 * s, cy + s], fill=color)


def icon(size, bg, fg, pad_ratio=0.0, rounded=True):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if bg is not None:
        if rounded:
            r = int(size * 0.22)
            d.rounded_rectangle([0, 0, size, size], radius=r, fill=bg)
        else:
            d.rectangle([0, 0, size, size], fill=bg)
    s = size * (0.30 - pad_ratio)
    flame(d, size / 2, size / 2 + size * 0.02, s, fg)
    # inti api lebih terang
    flame(d, size / 2, size / 2 + size * 0.10, s * 0.45,
          (bg if bg else MAROON))
    return img


# Ikon aplikasi (maroon bg, api putih)
icon(1024, MAROON, WHITE).save(os.path.join(OUT, "icon.png"))
# Logo untuk splash (transparan, api putih)
icon(512, None, WHITE, pad_ratio=0.02).save(os.path.join(OUT, "splash_logo.png"))
# Logo maroon di atas transparan (kalau perlu dark bg)
icon(512, None, MAROON).save(os.path.join(OUT, "logo_maroon.png"))

print("OK ->", os.path.abspath(OUT))
