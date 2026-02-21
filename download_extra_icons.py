
import requests
import os

base_url = "https://raw.githubusercontent.com/phosphor-icons/core/main/assets/duotone"
target_dir = "d:/app_dibujo_proyecto-main/assets/icons"

icons = {
    "clipboard-duotone.svg": "clipboard.svg",
    "dots-three-vertical-duotone.svg": "dots-vertical.svg",
    "arrows-left-right-duotone.svg": "swap.svg",
    "circles-three-duotone.svg": "circles-three.svg" # For palette or similar?
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
                content = r.text.replace('currentColor', '#FFFFFF')
                f.write(content.encode('utf-8'))
            print(f"  Success.")
        else:
            print(f"  Failed: {r.status_code}")
    except Exception as e:
        print(f"  Error: {e}")

print("Done.")
