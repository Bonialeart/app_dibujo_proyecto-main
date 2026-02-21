from PIL import Image, ImageDraw, ImageFilter
import random, os

def create_knife_brush():
    S = 512
    img = Image.new("RGBA", (S, S), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Forma de diamante/espátula sólida
    points = [(S/2, 20), (S-40, S/2), (S/2, S-20), (40, S/2)]
    draw.polygon(points, fill=(255,255,255,255))
    
    # Un poco de ruido muy sutil solo para que el shader de relieve tenga algo que agarrar
    for _ in range(5000):
         x, y = random.randint(0, S-1), random.randint(0, S-1)
         if img.getpixel((x,y))[3] > 0:
             draw.point((x,y), fill=(255,255,255,random.randint(200,255))) # Variación sutil de blanco

    # Casi sin desenfoque para bordes duros
    img = img.filter(ImageFilter.GaussianBlur(0.5))

    os.makedirs("assets/textures", exist_ok=True)
    img.save("assets/textures/oil_knife_pro.png")
    print("Generado: assets/textures/oil_knife_pro.png")

if __name__ == "__main__": create_knife_brush()
