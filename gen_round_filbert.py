from PIL import Image, ImageDraw, ImageFilter
import random, os, math

def create_filbert_brush():
    S = 512
    img = Image.new("RGBA", (S, S), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    center = S/2

    # Dibujar miles de puntos concentrados en el centro
    for _ in range(8000):
        angle = random.random() * 2 * math.pi
        # Distribución para que sea denso en el centro y difuso en bordes
        dist = random.triangular(0, S/2 * 0.8, 0) 
        x = center + math.cos(angle) * dist
        y = center + math.sin(angle) * dist
        
        radius = random.uniform(2, 8)
        alpha = random.randint(20, 150)
        draw.ellipse([x-radius, y-radius, x+radius, y+radius], fill=(255,255,255,alpha))

    img = img.filter(ImageFilter.GaussianBlur(2))
    
    os.makedirs("src/assets/textures", exist_ok=True)
    img.save("src/assets/textures/oil_filbert_pro.png")
    print("Generado: src/assets/textures/oil_filbert_pro.png")

if __name__ == "__main__": create_filbert_brush()
