import os
import random
import math
from PIL import Image, ImageDraw, ImageFilter, ImageOps

def create_soft_brush(size=256):
    """Creates a soft round brush tip with Gaussian blur."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Draw a white circle in the center, slightly smaller than canvas
    margin = size // 4
    draw.ellipse((margin, margin, size - margin, size - margin), fill=(255, 255, 255, 255))
    # Apply heavy blur
    image = image.filter(ImageFilter.GaussianBlur(radius=size // 6))
    return image

def create_hard_brush(size=256):
    """Creates a hard round brush tip with anti-aliasing."""
    # Super-sample for AA
    scale = 4
    image = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    margin = (size * scale) // 10
    draw.ellipse((margin, margin, size * scale - margin, size * scale - margin), fill=(255, 255, 255, 255))
    image = image.resize((size, size), resample=Image.LANCZOS)
    return image

def create_bristle_brush(size=256):
    """Creates a brush tip simulating bristles."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # Draw many small random lines/dots
    center = size // 2
    radius = size // 2 - 10
    
    for _ in range(300):
        # Random point in circle
        r = random.triangular(0, radius, 0) # More density towards center
        theta = random.uniform(0, 2 * math.pi)
        
        x = center + r * math.cos(theta)
        y = center + r * math.sin(theta)
        
        # Each bristle is a small fuzzy dot
        bristle_size = random.randint(2, 6)
        opacity = random.randint(100, 255)
        
        draw.ellipse((x, y, x + bristle_size, y + bristle_size), fill=(255, 255, 255, opacity))
        
    return image

def create_splatter_brush(size=256):
    """Creates a splatter texture."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    center = size // 2
    
    # Main blotches
    for _ in range(15):
        r = random.uniform(0, size // 3)
        theta = random.uniform(0, 2 * math.pi)
        x = center + r * math.cos(theta)
        y = center + r * math.sin(theta)
        s = random.randint(10, 40)
        draw.ellipse((x, y, x + s, y + s), fill=(255, 255, 255, 255))
        
    # Scatter droplets
    for _ in range(100):
        r = random.uniform(size // 4, size // 2 - 5)
        theta = random.uniform(0, 2 * math.pi)
        x = center + r * math.cos(theta)
        y = center + r * math.sin(theta)
        s = random.randint(2, 8)
        draw.ellipse((x, y, x + s, y + s), fill=(255, 255, 255, random.randint(150, 255)))
        
    image = image.filter(ImageFilter.GaussianBlur(radius=1))
    return image

def create_textured_brush(size=256):
    """Creates a grungy, textured brush."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # Noise base
    for x in range(0, size, 2):
        for y in range(0, size, 2):
            if random.random() > 0.5:
                # Distance fade from center
                dx = x - size // 2
                dy = y - size // 2
                dist = math.sqrt(dx*dx + dy*dy)
                max_dist = size // 2
                
                if dist < max_dist:
                    alpha = int(255 * (1 - (dist / max_dist)))
                    # Random variation
                    alpha = int(alpha * random.uniform(0.5, 1.0))
                    draw.point((x, y), fill=(255, 255, 255, alpha))
    
    # Soften
    image = image.filter(ImageFilter.GaussianBlur(radius=0.5))
    return image

def main():
    output_dir = r"assets/textures"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")
    
    brushes = {
        "tip_generated_soft.png": create_soft_brush,
        "tip_generated_hard.png": create_hard_brush,
        "tip_generated_bristle.png": create_bristle_brush,
        "tip_generated_splatter.png": create_splatter_brush,
        "tip_generated_textured.png": create_textured_brush
    }
    
    print("Generating brushes...")
    for filename, creator_func in brushes.items():
        path = os.path.join(output_dir, filename)
        print(f"  Generating {filename}...")
        img = creator_func()
        img.save(path, "PNG")
        print(f"  Saved to {path}")

    print("Done! New brush textures created.")

if __name__ == "__main__":
    main()
