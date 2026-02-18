
import requests
import os

base_url = "https://raw.githubusercontent.com/phosphor-icons/core/main/assets/duotone"
target_dir = "d:/app_dibujo_proyecto-main/assets/icons"

# Map: Phosphor Name -> Local Name
icons = {
    "stack-duotone.svg": "layers.svg",
    "folder-duotone.svg": "folder.svg",
    "eye-duotone.svg": "eye.svg",
    "eye-slash-duotone.svg": "eye-off.svg",
    "lock-duotone.svg": "lock.svg", 
    "lock-key-open-duotone.svg": "unlock.svg",
    "sliders-horizontal-duotone.svg": "sliders.svg",
    "trash-duotone.svg": "trash.svg",
    "copy-duotone.svg": "copy.svg",
    "caret-down-duotone.svg": "chevron-down.svg",
    "plus-duotone.svg": "plus.svg",
    "dots-six-vertical-duotone.svg": "grip.svg",
    "ghost-duotone.svg": "ghost.svg",
    "paint-brush-duotone.svg": "brush.svg",
    "palette-duotone.svg": "palette.svg", 
    "compass-duotone.svg": "compass.svg",
    "eraser-duotone.svg": "eraser.svg",
    "house-duotone.svg": "home.svg",
    "gear-duotone.svg": "settings.svg",
    "arrow-bend-down-left-duotone.svg": "arrow-down-left.svg"
}

if not os.path.exists(target_dir):
    os.makedirs(target_dir)

for phosphor_name, local_name in icons.items():
    url = f"{base_url}/{phosphor_name}"
    print(f"Downloading {phosphor_name} to {local_name}...")
    try:
        r = requests.get(url)
        if r.status_code == 200:
            with open(os.path.join(target_dir, local_name), 'wb') as f:
                f.write(r.content)
            print(f"  Success.")
        else:
            print(f"  Failed: {r.status_code}")
    except Exception as e:
        print(f"  Error: {e}")

print("Done.")
