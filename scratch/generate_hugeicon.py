import os
import re
import sys

def camel_case(name):
    # Convert name like "scissors", "trash-2", "scissors-01" to CamelCase with "Icon" suffix
    # e.g., "scissors" -> "ScissorsIcon"
    # "trash-2" -> "Trash02Icon" or similar.
    # Let's clean up name:
    name = name.replace("-", " ")
    words = name.split()
    camel = "".join(w.capitalize() for w in words)
    if not camel.endswith("Icon"):
        camel += "Icon"
    return camel

def generate_svg(icon_name, output_dir):
    # Look for the JS file in node_modules/@hugeicons/core-free-icons/dist/esm/
    node_modules_path = os.path.join(os.getcwd(), "node_modules", "@hugeicons", "core-free-icons", "dist", "esm")
    
    # Try direct name
    js_filename = icon_name + ".js"
    js_path = os.path.join(node_modules_path, js_filename)
    
    if not os.path.exists(js_path):
        # Let's search case-insensitively or try common variations
        files = os.listdir(node_modules_path)
        matched_file = None
        for f in files:
            if f.lower() == js_filename.lower():
                matched_file = f
                break
        if matched_file:
            js_path = os.path.join(node_modules_path, matched_file)
            icon_name = matched_file[:-3] # Remove .js
        else:
            print(f"Error: Icon '{icon_name}' not found in {node_modules_path}")
            # List some similar names
            similar = [f[:-3] for f in files if icon_name.lower() in f.lower()][:10]
            if similar:
                print(f"Did you mean: {', '.join(similar)}?")
            return False
            
    print(f"Found icon definition at: {js_path}")
    with open(js_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Extract any SVG elements: ["tag", { ... }]
    # Matches tags like path, circle, rect, ellipse, polygon, line, etc.
    elements_matches = re.findall(r'\[\s*["\'](path|circle|rect|ellipse|polygon|line)["\']\s*,\s*({[^}]+})\s*\]', content)
    
    svg_elements = []
    for tag, attrs_str in elements_matches:
        # Find all key-value pairs in the JS object, e.g. cx: "12", strokeLinecap: "round"
        # Matches key: "value" or key: 'value'
        kv_pairs = re.findall(r'(\w+):\s*["\']([^"\']+)["\']', attrs_str)
        attrs = {}
        for k, v in kv_pairs:
            # Map camelCase to hyphen-case
            if k == "strokeWidth":
                attrs["stroke-width"] = v
            elif k == "strokeLinecap":
                attrs["stroke-linecap"] = v
            elif k == "strokeLinejoin":
                attrs["stroke-linejoin"] = v
            elif k in ["cx", "cy", "r", "d", "x", "y", "width", "height", "stroke", "fill"]:
                attrs[k] = v
                
        # Default styling rules
        if "stroke" not in attrs and "fill" not in attrs:
            attrs["stroke"] = "currentColor"
        elif attrs.get("fill") == "currentColor":
            attrs["stroke"] = "none"
            
        if "stroke" in attrs and attrs["stroke"] != "none" and "stroke-width" not in attrs:
            attrs["stroke-width"] = "1.5"
        if "stroke" in attrs and attrs["stroke"] != "none" and "stroke-linecap" not in attrs:
            attrs["stroke-linecap"] = "round"
        if "stroke" in attrs and attrs["stroke"] != "none" and "stroke-linejoin" not in attrs:
            attrs["stroke-linejoin"] = "round"
            
        attr_str = " ".join(f'{k}="{v}"' for k, v in attrs.items())
        svg_elements.append(f'  <{tag} {attr_str} />')
        
    if not svg_elements:
        print("Error: Could not parse any elements from JS file.")
        return False
        
    svg_content = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none">
{os.linesep.join(svg_elements)}
</svg>"""

    # Output filename
    if len(sys.argv) > 3:
        out_name = sys.argv[3]
        if out_name.endswith(".svg"):
            out_name = out_name[:-4]
    else:
        out_name = icon_name.lower()
        if out_name.endswith("icon"):
            out_name = out_name[:-4]
    
    # Add back hyphens for consistency if needed, or keep CamelCase as lower
    output_path = os.path.join(output_dir, f"{out_name}.svg")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(svg_content)
        
    print(f"Successfully generated: {output_path}")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python generate_hugeicon.py <IconName> [OutputDir] [CustomFileName]")
        sys.exit(1)
        
    icon_name = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.getcwd(), "assets", "icons")
    
    # Ensure camel case if user inputs "scissors" -> "ScissorsIcon"
    if not icon_name[0].isupper() or not icon_name.endswith("Icon"):
        icon_name = camel_case(icon_name)
        
    generate_svg(icon_name, output_dir)
