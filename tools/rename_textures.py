import os
import json
import re

# Paths
PROJECT_ROOT = r"e:\app_dibujo_proyecto-main"
TEXTURES_DIR = os.path.join(PROJECT_ROOT, "assets", "textures")
BRUSHES_DIR = os.path.join(PROJECT_ROOT, "assets", "brushes")
CPP_SRC_DIR = os.path.join(PROJECT_ROOT, "src", "core", "cpp", "src")

# Manual mapping for specific cleanup preferences
# Old Name -> New Name
RENAME_MAP = {
    # Generated / Shapes
    "tip_generated_soft.png": "shape_soft_circle.png",
    "tip_generated_hard.png": "shape_hard_circle.png",
    "tip_generated_bristle.png": "shape_bristle.png",
    "tip_generated_splatter.png": "shape_splatter.png",
    "tip_generated_textured.png": "shape_textured.png",
    "tip_painting_round_brush.png": "shape_round.png", # The replaced one
    "tip_airbrushing_soft_airbrush.png": "shape_airbrush_soft.png", # The replaced one
    
    # Common Tips
    "tip_pencil.png": "tip_pencil_texture.png",
    "tip_hard.png": "tip_hard_round.png", 
    "tip_soft.png": "tip_soft_round.png",
    "tip_square.png": "tip_square.png",
    "tip_bristle.png": "tip_bristle_generic.png",
    
    # Paper/Grains
    "paper_grain.png": "grain_paper_standard.png",
    "watercolor_paper.png": "grain_watercolor_paper.png",
    "canvas_weave.png": "grain_canvas_weave.png",
    
    # Sketching
    "tip_sketching_hb_pencil.png": "pencil_hb.png",
    "tip_sketching_6b_real_pencil.png": "pencil_6b_real.png",
    
    # Painting
    "tip_painting_flat_brush.png": "paint_flat.png",
    "tip_painting_fan_brush.png": "paint_fan.png",
    "tip_painting_dry_brush.png": "paint_dry.png",
    
    # Inking
    "tip_inking_g_pen.png": "ink_g_pen.png",
    "tip_inking_real_g_pen.png": "ink_real_g_pen.png",
    
    # We remove 'tip_' prefix generally if not caught above
}

def generate_new_name(old_name):
    if old_name in RENAME_MAP:
        return RENAME_MAP[old_name]
    
    # Generic Rules
    new_name = old_name
    
    # Remove 'tip_' prefix
    if new_name.startswith("tip_"):
        new_name = new_name[4:]
        
    # Simplify categories
    # pattern: category_rest.png
    categories = ["painting_", "sketching_", "inking_", "airbrushing_", "calligraphy_", "artistic_", "charcoal_", "drawing_", "elements_", "industrial_", "luminance_", "sprays_", "textures_", "vintage_"]
    
    for cat in categories:
        if new_name.startswith(cat):
            new_name = new_name[len(cat):]
            break
            
    return new_name

def process_renames():
    # 1. Build full map
    files = os.listdir(TEXTURES_DIR)
    full_map = {}
    
    print("Plan de renombrado:")
    for f in files:
        if not f.endswith(".png"): continue
        new_name = generate_new_name(f)
        if new_name != f:
            full_map[f] = new_name
            print(f"  {f} -> {new_name}")
            
    # Check for collisions
    seen = set()
    for old, new in full_map.items():
        if new in seen:
            print(f"ERROR: Collision type for {new}! Aborting.")
            return
        seen.add(new)
        
    # 2. Rename Files
    print(f"\nRenaming {len(full_map)} files...")
    for old, new in full_map.items():
        old_path = os.path.join(TEXTURES_DIR, old)
        new_path = os.path.join(TEXTURES_DIR, new)
        try:
            os.rename(old_path, new_path)
        except OSError as e:
            print(f"Error renaming {old}: {e}")

    # 3. Update JSONs
    print("\nUpdating JSON brush presets...")
    json_files = [f for f in os.listdir(BRUSHES_DIR) if f.endswith(".json")]
    for jf in json_files:
        path = os.path.join(BRUSHES_DIR, jf)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Replace all occurrences
        new_content = content
        for old, new in full_map.items():
            # JSON strings
            new_content = new_content.replace(f'"{old}"', f'"{new}"')
            
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"  Updated {jf}")

    # 4. Update C++ Code (BrushPresetManager)
    print("\nUpdating C++ Defaults...")
    cpp_file = os.path.join(CPP_SRC_DIR, "brush_preset_manager.cpp")
    if os.path.exists(cpp_file):
        with open(cpp_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content
        for old, new in full_map.items():
            # C++ Strings
            new_content = new_content.replace(f'"{old}"', f'"{new}"')
            
        if new_content != content:
            with open(cpp_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"  Updated brush_preset_manager.cpp")
    else:
        print("Warning: brush_preset_manager.cpp not found.")

if __name__ == "__main__":
    process_renames()
