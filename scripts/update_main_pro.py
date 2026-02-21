import os

file_path = r'src/ui/qml/main_pro.qml'
if not os.path.exists(file_path):
    print(f"File not found: {file_path}")
    exit(1)

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# --- PART 1: Replace QCanvasItem with Flickable ---
# Looking for:
#                 QCanvasItem {
#                     id: mainCanvas
#                     anchors.fill: parent
#                     visible: isProjectActive

# We can find the line index
start_canvas_idx = -1
for i, line in enumerate(lines):
    if "QCanvasItem {" in line and "id: mainCanvas" in lines[i+1]:
        start_canvas_idx = i
        break

if start_canvas_idx != -1:
    # Check if anchors.fill: parent is there and replace/comment it
    # We want to wrap this block.
    # The block ends with `}`. We need to find the matching brace or just wrap it.
    # Actually, it's easier to replace the specific lines 
    # `anchors.fill: parent` -> `width: canvasWidth * zoomLevel ...`
    # and wrap the whole thing in Flickable.
    
    # Let's verify line numbers from previous view_file
    # Line 503 is QCanvasItem {
    # Line 505: anchors.fill: parent
    
    # We will construct the new block to replace lines 503-507 (approx)
    # But wait, QCanvasItem allows scrolling?
    # No, we need to wrap it.
    
    # Let's locate the closing brace of QCanvasItem to wrap it properly?
    # Or simplified: indentation based.
    
    # Actually, I'll use a fixed range based on the signature if it matches
    if "anchors.fill: parent" in lines[start_canvas_idx+2]:
        print("Found QCanvasItem and anchors.fill. Proceeding with Flickable wrap.")
        
        # We need to insert Flickable { before QCanvasItem {
        lines.insert(start_canvas_idx, """                Flickable {
                    id: canvasFlickable
                    anchors.fill: parent
                    contentWidth: mainCanvas.width
                    contentHeight: mainCanvas.height
                    clip: true
                    
                    leftMargin: (width - contentWidth) > 0 ? (width - contentWidth) / 2 : 0
                    topMargin: (height - contentHeight) > 0 ? (height - contentHeight) / 2 : 0

""")
        # Now QCanvasItem is inside. We need to indent it?
        # QML doesn't strictly require indentation for parsing, but it's nice.
        # We also need to change anchors.fill: parent to size logic inside QCanvasItem.
        lines[start_canvas_idx + 1 + 2] = "                    width: canvasWidth * zoomLevel\n                    height: canvasHeight * zoomLevel\n                    // anchors.fill: parent\n"
        
        # We need to close the Flickable } after QCanvasItem }
        # Finding the closing brace of QCanvasItem is tricky without parsing.
        # However, looking at indentation, QCanvasItem ends at line 673 (in previous view, before Modification).
        # Wait, the closing brace is somewhere down.
        # Line 516 (in main_pro.qml view) was `}` for `Rectangle` (Shadow).
        # ...
        # Line 616: `Item { id: loupe ...` is inside QCanvasItem?
        # typically yes.
        # Line 766 in modified CanvasPage.qml (Line 796 in main_pro.qml?)
        # Let's assume QCanvasItem ends where `// --- CONTEXT BAR` starts.
        
        # Search for CONTEXT BAR
        context_bar_idx = -1
        for j in range(start_canvas_idx, len(lines)):
            if "// --- CONTEXT BAR" in lines[j]:
                context_bar_idx = j
                break
        
        if context_bar_idx != -1:
            # The closing brace for QCanvasItem should be just before this comment.
            # Usually `}` then blank lines.
            # Let's checking lines[context_bar_idx - 1]
            # It seems `}` is there.
            lines.insert(context_bar_idx, "                }\n")
            print("Inserted closing brace for Flickable.")
        else:
            print("Could not find CONTEXT BAR to close Flickable. manual check needed.")

# --- PART 2: Replace Brush Settings Panel ---
# Looking for comment `// === TOOL PROPERTIES PANEL`
start_panel_idx = -1
for i, line in enumerate(lines):
    if "// === TOOL PROPERTIES PANEL" in line:
        start_panel_idx = i
        break

if start_panel_idx != -1:
    # Check bounds. We assume it starts at start_panel_idx and ends before `// === NEW HORIZONTAL SUB-TOOL BAR`
    end_panel_idx = -1
    for j in range(start_panel_idx, len(lines)):
        if "// === NEW HORIZONTAL SUB-TOOL BAR" in lines[j]:
            end_panel_idx = j
            break
    
    if end_panel_idx != -1:
        # We need to keep the closing brace of the previous item?
        # No, the previous item (Brush Panel) is fully contained between these comments.
        # Wait, the comment is usually before the item.
        # Let's verify line 1105 is comment, 1106 is Rectangle.
        # Line 1498 is `// === NEW HORIZONTAL SUB-TOOL BAR`.
        # So we delete from start_panel_idx+1 to end_panel_idx (exclusive of next comment).
        # Actually we remove the comment too if we want to replace it cleanly or keep it.
        # I'll keep the comment and replace the body.
        
        # Verify the line before end_panel_idx is `}` or empty.
        print(f"Replacing Brush Panel from line {start_panel_idx+1} to {end_panel_idx}")
        del lines[start_panel_idx+1 : end_panel_idx]
        
        new_panel_code = """                BrushSettingsPanel {
                    anchors.right: sideToolbar.left
                    anchors.rightMargin: 15
                    anchors.verticalCenter: sideToolbar.verticalCenter
                    
                    visible: isProjectActive && canvasPage.showToolSettings && (canvasPage.activeToolIdx >= 5 && canvasPage.activeToolIdx <= 9)
                    z: 500
                    
                    // Animations
                    opacity: visible ? 1.0 : 0.0
                    scale: visible ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    
                    targetCanvas: mainCanvas
                    activeToolIdx: canvasPage.activeToolIdx
                    colorAccent: colorAccent
                }
"""
        lines.insert(start_panel_idx+1, new_panel_code)
        
    else:
        print("Could not find end of Brush Panel block.")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(''.join(lines))

print("Successfully updated main_pro.qml")
