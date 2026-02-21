import os

file_path = r'src/ui/qml/views/CanvasPage.qml'
if not os.path.exists(file_path):
    print(f"File not found: {file_path}")
    exit(1)

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line 666 (1-based) is index 665
start_idx = 665
# Line 1056 (1-based) is index 1055. We want to include it in deletion.
end_idx = 1056

# Verify content to be sure (optional but good practice)
print(f"Deleting lines {start_idx+1} to {end_idx}:")
print(lines[start_idx].strip())
print("...")
print(lines[end_idx-1].strip())

if "Rectangle {" not in lines[start_idx]:
    print("WARNING: Start line does not look like Rectangle {")
    # exit(1) # Proceed with caution or just check manualy

del lines[start_idx:end_idx]

new_content = """                // === TOOL PROPERTIES PANEL (Brush Settings - Premium Floating Panel) ===
                BrushSettingsPanel {
                    anchors.right: sideToolbar.left
                    anchors.rightMargin: 15
                    anchors.verticalCenter: sideToolbar.verticalCenter
                    
                    visible: isProjectActive && canvasPage.showToolSettings && (canvasPage.activeToolIdx >= 3 && canvasPage.activeToolIdx <= 10)
                    z: 500
                    
                    // Animations
                    opacity: visible ? 1.0 : 0.0
                    scale: visible ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    
                    targetCanvas: mainCanvas
                    activeToolIdx: canvasPage.activeToolIdx
                    colorAccent: canvasPage.colorAccent
                }
"""

lines.insert(start_idx, new_content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(''.join(lines))

print("Successfully replaced content.")
