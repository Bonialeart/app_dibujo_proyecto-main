
import os
import shutil
import sys
import re

# Add scripts dir to path to import generate_brushes
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(SCRIPT_DIR)

try:
    import generate_brushes
except ImportError:
    # If we can't import, we might be running this from root, so try adjusting path
    sys.path.append(os.path.join(os.getcwd(), 'scripts'))
    import generate_brushes

# Path to assets
ASSETS_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "../assets/textures"))

def sanitize_name(name):
    return re.sub(r'[^a-zA-Z0-9_]', '_', name).lower()

def create_unique_textures():
    mappings = {}
    
    print(f"Scanning brushes in {len(generate_brushes.categories)} categories...")
    
    for cat_name, info in generate_brushes.categories.items():
        brushes = info["brushes"]
        for b_name, b_settings in brushes:
            # Find current tip texture
            current_tex = "tip_square.png" # Default if not specified (we saw checking specifically, but fallback is square)
            
            # Helper to find nested key
            if "shape" in b_settings and "tip_texture" in b_settings["shape"]:
                current_tex = b_settings["shape"]["tip_texture"]
            
            # Also check if it uses default from create_brush (empty string which falls back)
            # But the script replaces it.
            
            if not current_tex:
                 current_tex = "tip_square.png"

            # Create new unique name
            safe_cat = sanitize_name(cat_name)
            safe_name = sanitize_name(b_name)
            new_tex_name = f"tip_{safe_cat}_{safe_name}.png"
            
            src_path = os.path.join(ASSETS_DIR, current_tex)
            dst_path = os.path.join(ASSETS_DIR, new_tex_name)
            
            if not os.path.exists(src_path):
                print(f"WARNING: Source texture {current_tex} not found for {b_name}. Using tip_square.png")
                src_path = os.path.join(ASSETS_DIR, "tip_square.png")
            
            if os.path.exists(src_path):
                shutil.copy2(src_path, dst_path)
                print(f"Created {new_tex_name} from {current_tex}")
                mappings[(cat_name, b_name)] = new_tex_name
            else:
                print(f"ERROR: Could not find source {src_path} or fallback.")

    return mappings

if __name__ == "__main__":
    mappings = create_unique_textures()
    # verify
    print(f"Created {len(mappings)} unique textures.")
