import os

file_path = r'src/ui/qml/main_pro.qml'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip_mode = False
skip_until_keyword = ""

# --- PART 1: Find QCanvasItem Block ---
# We iterate line by line and build new_lines
idx = 0
while idx < len(lines):
    line = lines[idx]
    
    # Check if we are at QCanvasItem Start
    if "QCanvasItem {" in line and "id: mainCanvas" in lines[idx+1]:
        print("Found QCanvasItem Block. Replacing with Flickable.")
        
        # Insert Flickable start
        new_lines.append("                Flickable {\n")
        new_lines.append("                    id: canvasFlickable\n")
        new_lines.append("                    anchors.fill: parent\n")
        new_lines.append("                    contentWidth: mainCanvas.width\n")
        new_lines.append("                    contentHeight: mainCanvas.height\n")
        new_lines.append("                    clip: true\n")
        new_lines.append("                    \n")
        new_lines.append("                    leftMargin: (width - contentWidth) > 0 ? (width - contentWidth) / 2 : 0\n")
        new_lines.append("                    topMargin: (height - contentHeight) > 0 ? (height - contentHeight) / 2 : 0\n")
        new_lines.append("\n")
        
        # Add QCanvasItem with modified properties
        # We need to preserve the indentation of QCanvasItem but modify anchors.fill
        # QCanvasItem { is at line, we append it indented? Or keep it?
        # QCanvasItem is usually indented by 16 spaces (4 tabs?) or whatever.
        # Let's check indentation.
        indent = line[:line.find("QCanvasItem")]
        new_lines.append(indent + "    QCanvasItem {\n") # Add extra indent
        
        # Skip next line (id: mainCanvas) and recreate it with extra indent
        idx += 1
        new_lines.append(indent + "        id: mainCanvas\n")
        
        # Skip next line (anchors.fill: parent) and replace with size logic
        idx += 1
        # Check if it was anchors.fill
        if "anchors.fill" in lines[idx]:
            new_lines.append(indent + "        width: canvasWidth * zoomLevel\n")
            new_lines.append(indent + "        height: canvasHeight * zoomLevel\n")
        else:
            # Maybe it wasn't anchors.fill, keep it but warn.
            new_lines.append(lines[idx]) 
        
        # Now we continue copying lines until we hit the end of QCanvasItem block.
        # This is tricky without parsing braces.
        # Strategy: The end of QCanvasItem is before "Rectangle { id: contextBar"?
        # Or before "id: contextBar"
        
        # We just continue scanning until we find `id: contextBar` or `// --- CONTEXT BAR`
        # and insert `    }\n` (closing QCanvasItem) `}\n` (closing Flickable) BEFORE it.
        # Wait, QCanvasItem has `}` at the end. We need to find THAT `}` and ensure we close Flickable AFTER it.
        # Finding the matching brace is hard.
        
        # Alternative: Just rely on indentation?
        # NO.
        
        # Let's assume QCanvasItem ends before `contextBar`.
        # So we continue loop. When we hit contextBar, we insert closing braces.
        # But QCanvasItem has its own closing brace which is already in `lines`.
        # We just need to insert `}` (for Flickable) after QCanvasItem's `}`.
        # Where is QCanvasItem's `}`? It's right before `contextBar`.
        
        idx += 1
        continue

    # Check for Closing of QCanvasItem (heuristic: before contextBar)
    if "id: contextBar" in line:
        # We assume the previous non-empty line was `}` for QCanvasItem.
        # So we insert `}` for Flickable before this line.
        new_lines.append("                }\n") # Closing Flickable
        print("Inserted closing brace for Flickable.")
        new_lines.append(line)
        idx += 1
        continue

    # --- PART 2: Replace Brush Settings Panel ---
    if "// === TOOL PROPERTIES PANEL" in line:
        print("Found Brush Settings Panel. replacing.")
        
        # Write the comment
        new_lines.append(line)
        
        # Skip the old block until we find the next section
        # The next section starts with `// === NEW HORIZONTAL SUB-TOOL BAR` or `id: subToolBar`
        skip_mode = True
        skip_until_keyword = "id: subToolBar"
        
        # Insert New Component
        new_lines.append("                BrushSettingsPanel {\n")
        new_lines.append("                    anchors.right: sideToolbar.left\n")
        new_lines.append("                    anchors.rightMargin: 15\n")
        new_lines.append("                    anchors.verticalCenter: sideToolbar.verticalCenter\n")
        new_lines.append("                    \n")
        new_lines.append("                    visible: isProjectActive && canvasPage.showToolSettings && (canvasPage.activeToolIdx >= 5 && canvasPage.activeToolIdx <= 9)\n")
        new_lines.append("                    z: 500\n")
        new_lines.append("                    \n")
        new_lines.append("                    // Animations\n")
        new_lines.append("                    opacity: visible ? 1.0 : 0.0\n")
        new_lines.append("                    scale: visible ? 1.0 : 0.95\n")
        new_lines.append("                    Behavior on opacity { NumberAnimation { duration: 150 } }\n")
        new_lines.append("                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }\n")
        new_lines.append("                    \n")
        new_lines.append("                    targetCanvas: mainCanvas\n")
        new_lines.append("                    activeToolIdx: canvasPage.activeToolIdx\n")
        new_lines.append("                    colorAccent: colorAccent\n")
        new_lines.append("                }\n")
        
        idx += 1
        continue
        
    if skip_mode:
        if skip_until_keyword in line:
            skip_mode = False
            # We found the next block. But wait, `id: subToolBar` is inside `Rectangle {`.
            # We skipped the `Rectangle {` of `subToolBar`?
            # No, `id: subToolBar` is usually the first line inside `Rectangle`.
            # We need to find `Rectangle` that contains `subToolBar`?
            # The keyword search might be too aggressive.
            
            # Let's search for `// === NEW HORIZONTAL SUB-TOOL BAR` instead if possible.
            # But line 1498 (in original) has it.
            # If we skip until `Rectangle {` that follows, it's safer.
            # Let's just use `// === NEW HORIZONTAL SUB-TOOL BAR` as stopper.
            pass
        elif "// === NEW HORIZONTAL SUB-TOOL BAR" in line:
             skip_mode = False
             new_lines.append(line)
             idx += 1
             continue
        
        if not skip_mode:
             # We just stopped skipping.
             # We need to verify if we consumed the line or not.
             # If we consumed it, append it.
             new_lines.append(line)
        
        idx += 1
        continue

    # Default Copy
    new_lines.append(line)
    idx += 1

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(''.join(new_lines))

print("Successfully updated main_pro.qml")
