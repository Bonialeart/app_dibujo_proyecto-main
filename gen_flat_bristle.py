from PIL import Image, ImageDraw, ImageFilter
import random, os

def create_flat_brush():
    W, H = 512, 512
    img = Image.new("RGBA", (W, H), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    
    # Crear una forma rectangular base con esquinas redondeadas
    margin = 50
    draw.rounded_rectangle([margin, margin+100, W-margin, H-margin-100], radius=60, fill=(255,255,255,180))
    
    # Añadir "cerdas" verticales (líneas ruidosas)
    noise = Image.new("RGBA", (W, H), (0,0,0,0))
    noise_draw = ImageDraw.Draw(noise)
    for x in range(margin, W-margin, 2):
        opacity = random.randint(50, 255)
        width = random.randint(1, 3)
        # Líneas ligeramente temblorosas
        start_x = x + random.randint(-2, 2)
        end_x = x + random.randint(-2, 2)
        noise_draw.line([start_x, margin+80, end_x, H-margin-80], fill=(255,255,255,opacity), width=width)

    # Fusionar y añadir textura granulada
    img = Image.alpha_composite(img, noise)
    
    # Ruido final para romper la perfección
    for _ in range(10000):
        x, y = random.randint(0, W-1), random.randint(0, H-1)
        if img.getpixel((x,y))[3] > 0: # Solo dentro del pincel
             draw.point((x,y), fill=(0,0,0,40)) # Puntos oscuros para restar

    img = img.filter(ImageFilter.GaussianBlur(1))
    
    os.makedirs("src/assets/textures", exist_ok=True)
    img.save("src/assets/textures/oil_flat_pro.png")
    print("Generado: src/assets/textures/oil_flat_pro.png")

if __name__ == "__main__": create_flat_brush()
