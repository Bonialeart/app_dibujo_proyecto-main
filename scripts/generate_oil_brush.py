import math
import random
from PIL import Image, ImageDraw, ImageFilter
import os

def create_oil_bristle_texture(filename="assets/textures/oil_bristle_pro.png", size=512):
    # 1. Crear lienzo transparente
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size / 2
    radius = size / 2 * 0.9
    
    # 2. Dibujar miles de "cerdas" (Bristles)
    num_bristles = 4000
    
    print("Generando cerdas digitales...")
    
    for _ in range(num_bristles):
        # Punto aleatorio dentro del círculo (coordenadas polares)
        angle = random.random() * 2 * math.pi
        # Concentrar más cerdas en el centro (distribución exponencial)
        dist = random.triangular(0, radius, 0) 
        
        x = center + math.cos(angle) * dist
        y = center + math.sin(angle) * dist
        
        # Tamaño y opacidad variable para cada pelo
        bristle_size = random.randint(2, 6)
        opacity = random.randint(50, 200) # Alpha entre 50 y 200
        
        # Dibujar la cerda
        draw.ellipse(
            [x - bristle_size/2, y - bristle_size/2, x + bristle_size/2, y + bristle_size/2],
            fill=(255, 255, 255, opacity)
        )

    # 3. Aplicar "Desgaste" (Noise Overlay)
    print("Aplicando textura de desgaste...")
    noise_layer = Image.new("RGBA", (size, size))
    noise_draw = ImageDraw.Draw(noise_layer)
    for x in range(0, size, 4):
        for y in range(0, size, 4):
            if random.random() > 0.5:
                noise_draw.point((x, y), fill=(0, 0, 0, 50)) # Puntos negros semitransparentes para restar
    
    # Fusionar ruido
    img = Image.alpha_composite(img, noise_layer)

    # 4. Suavizar un poco
    img = img.filter(ImageFilter.GaussianBlur(radius=1.0))
    
    # 5. Asegurar directorios y guardar
    abs_filename = os.path.abspath(filename)
    os.makedirs(os.path.dirname(abs_filename), exist_ok=True)
    img.save(abs_filename)
    print(f"¡Textura generada exitosamente en: {abs_filename}!")

if __name__ == "__main__":
    try:
        create_oil_bristle_texture()
    except ImportError:
        print("Error: Necesitas la librería Pillow.")
        print("Instálala con: pip install Pillow")
