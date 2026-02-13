from PIL import Image
import numpy as np
import os

path = "src/assets/textures/tip_pencil.png"
if not os.path.exists(path):
    print(f"File not found: {path}")
    exit(1)

img = Image.open(path)
print(f"Format: {img.mode}, Size: {img.size}")
data = np.array(img)
print(f"Min: {data.min()}, Max: {data.max()}, Mean: {data.mean()}")
center = data[128, 128]
print(f"Center pixel: {center}")
