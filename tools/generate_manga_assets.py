import os
import random
import math
from PIL import Image, ImageDraw, ImageFilter

def create_manga_maru_pen(size=256):
    """Maru-pen: Very sharp and fine circle."""
    scale = 4
    image = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    margin = (size * scale) // 8
    draw.ellipse((margin, margin, size * scale - margin, size * scale - margin), fill=(255, 255, 255, 255))
    image = image.resize((size, size), resample=Image.LANCZOS)
    return image

def create_manga_saji_pen(size=256):
    """Saji-pen (Spoon pen): Stiff and consistent, slightly elongated."""
    scale = 4
    image = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    margin_x = (size * scale) // 10
    margin_y = (size * scale) // 9
    draw.ellipse((margin_x, margin_y, size * scale - margin_x, size * scale - margin_y), fill=(255, 255, 255, 255))
    image = image.resize((size, size), resample=Image.LANCZOS)
    return image

def create_manga_fude_pen(size=256):
    """Fude Pen: Brush-like, slightly irregular edges."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    center = size // 2
    radius = size // 2 - 20
    draw.ellipse((20, 20, size - 20, size - 20), fill=(255, 255, 255, 255))
    for _ in range(100):
        angle = random.uniform(0, 2 * math.pi)
        r = random.uniform(radius - 10, radius + 10)
        x = center + r * math.cos(angle)
        y = center + r * math.sin(angle)
        s = random.randint(3, 8)
        draw.ellipse((x, y, x + s, y + s), fill=(255, 255, 255, random.randint(100, 200)))
    image = image.filter(ImageFilter.GaussianBlur(radius=1.5))
    return image

def create_manga_textured_ink(size=256):
    """Ink with slight paper texture / bleeding."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for _ in range(1000):
        r = random.triangular(0, size // 2 - 5, 0)
        theta = random.uniform(0, 2 * math.pi)
        x = size // 2 + r * math.cos(theta)
        y = size // 2 + r * math.sin(theta)
        s = random.randint(1, 4)
        draw.ellipse((x, y, x + s, y + s), fill=(255, 255, 255, random.randint(50, 255)))
    image = image.filter(ImageFilter.GaussianBlur(radius=0.8))
    return image

def create_manga_halftone_dot(size=256):
    """Halftone dot (screentone replacement)."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    center = size // 2
    r = size // 3
    draw.ellipse((center - r, center - r, center + r, center + r), fill=(255, 255, 255, 255))
    return image

def create_manga_speed_lines(size=256):
    """Speed lines: vertical tapered lines."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for _ in range(20):
        x = random.randint(0, size)
        w = random.randint(2, 6)
        h = random.randint(size // 2, size)
        y_start = random.randint(0, size - h)
        draw.ellipse((x, y_start, x + w, y_start + h), fill=(255, 255, 255, random.randint(150, 255)))
    image = image.filter(ImageFilter.GaussianBlur(radius=0.5))
    return image

def main():
    output_dir = r"assets/textures"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    brushes = {
        "ink_maru_pen.png": create_manga_maru_pen,
        "ink_saji_pen.png": create_manga_saji_pen,
        "ink_fude_pen.png": create_manga_fude_pen,
        "ink_manga_textured.png": create_manga_textured_ink,
        "manga_halftone.png": create_manga_halftone_dot,
        "manga_speed_lines.png": create_manga_speed_lines
    }
    print("Generating Manga Inking textures...")
    for filename, creator_func in brushes.items():
        path = os.path.join(output_dir, filename)
        img = creator_func()
        img.save(path, "PNG")
        print(f"  Generated {filename}")

if __name__ == "__main__":
    main()
