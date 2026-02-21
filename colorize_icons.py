
import os

target_dir = "d:/app_dibujo_proyecto-main/assets/icons"

for filename in os.listdir(target_dir):
    if filename.endswith(".svg"):
        path = os.path.join(target_dir, filename)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace currentColor with white
            new_content = content.replace('currentColor', '#FFFFFF')
            
            # Write back
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filename}")
        except Exception as e:
            print(f"Error processing {filename}: {e}")
