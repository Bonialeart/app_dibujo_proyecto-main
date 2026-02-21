
import os
import sys
import re

# Add scripts dir to path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(SCRIPT_DIR)

import generate_brushes

def sanitize_name(name):
    return re.sub(r'[^a-zA-Z0-9_]', '_', name).lower()

def update_brush_definitions():
    # Detect range of categories in file
    filepath = os.path.join(SCRIPT_DIR, "generate_brushes.py")
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    start_line = -1
    end_line = -1
    
    for i, line in enumerate(lines):
        if line.strip().startswith("categories = {"):
            start_line = i
        if start_line != -1 and line.strip() == "}":
            end_line = i
            # Don't break immediately, find the closing brace at the right indentation level?
            # In the file, the closing brace is at line 272 (indentation 0).
            if line.startswith("}"):
                break
    
    if start_line == -1 or end_line == -1:
        print("Could not find categories dict in generate_brushes.py")
        return

    # Update the in-memory categories structure
    new_categories_code = "categories = {\n"
    
    for cat_name, info in generate_brushes.categories.items():
        new_categories_code += f'    "{cat_name}": {{\n'
        new_categories_code += f'        "icon": "{info["icon"]}",\n'
        new_categories_code += f'        "brushes": [\n'
        
        for name, settings in info["brushes"]:
            # Logic to update tip_texture
            safe_cat = sanitize_name(cat_name)
            safe_name = sanitize_name(name)
            new_tex = f"tip_{safe_cat}_{safe_name}.png"
            
            if "shape" not in settings:
                settings["shape"] = {}
            
            settings["shape"]["tip_texture"] = new_tex
            
            # Format settings dict as python string
            # We use repr() but we might want to keep it readable
            # repr() of a dict is usually single line. We can try to rely on that.
            settings_str = repr(settings)
            
            new_categories_code += f'            ("{name}", {settings_str}),\n'
            
        new_categories_code += "        ]\n"
        new_categories_code += "    },\n"
    new_categories_code += "}"

    # Replace lines
    new_lines = lines[:start_line] + [new_categories_code + "\n"] + lines[end_line+1:]
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

    print("Successfully updated generate_brushes.py with new texture names.")

if __name__ == "__main__":
    update_brush_definitions()
