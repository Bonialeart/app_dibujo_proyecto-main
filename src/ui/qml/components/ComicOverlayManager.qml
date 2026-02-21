import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ═══════════════════════════════════════════════════════════
// ComicOverlayManager - Manages editable panels & speech bubbles
// Sits on top of the canvas, transforms with zoom/pan
// ═══════════════════════════════════════════════════════════
Item {
    id: root
    
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    // Data models
    property var panelItems: []    // [{id, x, y, w, h, rotation}]
    property var bubbleItems: []   // [{id, x, y, w, h, type, text, tailAngle}]
    property int nextId: 1
    
    // Selection state
    property int selectedPanelId: -1
    property int selectedBubbleId: -1
    property bool hasSelection: selectedPanelId >= 0 || selectedBubbleId >= 0
    
    signal panelsChanged()
    signal bubblesChanged()
    
    // ── Public API ──
    
    function addPanelLayout(layoutType, gutterPx, borderPx, marginPx) {
        if (!targetCanvas) return
        
        var cw = targetCanvas.canvasWidth
        var ch = targetCanvas.canvasHeight
        var mx = marginPx
        var my = marginPx
        var iw = cw - 2 * mx
        var ih = ch - 2 * my
        var g = gutterPx
        
        var newPanels = []
        
        if (layoutType === "single") {
            newPanels = [{x: mx, y: my, w: iw, h: ih}]
        } else if (layoutType === "2col") {
            var cw2 = (iw - g) / 2
            newPanels = [
                {x: mx, y: my, w: cw2, h: ih},
                {x: mx + cw2 + g, y: my, w: cw2, h: ih}
            ]
        } else if (layoutType === "2row") {
            var rh = (ih - g) / 2
            newPanels = [
                {x: mx, y: my, w: iw, h: rh},
                {x: mx, y: my + rh + g, w: iw, h: rh}
            ]
        } else if (layoutType === "grid") {
            var topH = (ih - g) * 0.45
            var botH = ih - topH - g
            var c3 = (iw - 2 * g) / 3
            var c2r = (iw - g) / 2
            newPanels = [
                {x: mx, y: my, w: c3, h: topH},
                {x: mx + c3 + g, y: my, w: c3, h: topH},
                {x: mx + 2 * (c3 + g), y: my, w: c3, h: topH},
                {x: mx, y: my + topH + g, w: c2r, h: botH},
                {x: mx + c2r + g, y: my + topH + g, w: c2r, h: botH}
            ]
        } else if (layoutType === "manga") {
            var th2 = ih * 0.3
            var bh2 = ih - th2 - g
            var lw = iw * 0.5
            var rw = iw - lw - g
            var rh1 = (bh2 - g) * 0.55
            var rh2 = bh2 - rh1 - g
            newPanels = [
                {x: mx, y: my, w: iw, h: th2},
                {x: mx, y: my + th2 + g, w: lw, h: bh2},
                {x: mx + lw + g, y: my + th2 + g, w: rw, h: rh1},
                {x: mx + lw + g, y: my + th2 + g + rh1 + g, w: rw, h: rh2}
            ]
        } else if (layoutType === "4panel") {
            var c1w = iw * 0.45
            var c2w2 = iw - c1w - g
            var r1t = ih * 0.35
            var r1b = ih - r1t - g
            var r2t = ih * 0.55
            var r2b = ih - r2t - g
            newPanels = [
                {x: mx, y: my, w: c1w, h: r1t},
                {x: mx + c1w + g, y: my, w: c2w2, h: r2t},
                {x: mx, y: my + r1t + g, w: c1w, h: r1b},
                {x: mx + c1w + g, y: my + r2t + g, w: c2w2, h: r2b}
            ]
        } else if (layoutType === "strip") {
            var sh1 = ih * 0.38
            var sh2v = ih * 0.35
            var sh3 = ih - sh1 - sh2v - 2 * g
            newPanels = [
                {x: mx, y: my, w: iw, h: sh1},
                {x: mx, y: my + sh1 + g, w: iw, h: sh2v},
                {x: mx, y: my + sh1 + sh2v + 2 * g, w: iw, h: sh3}
            ]
        }
        
        // Add each panel with unique id
        for (var i = 0; i < newPanels.length; i++) {
            var p = newPanels[i]
            panelItems.push({
                id: nextId++,
                x: p.x, y: p.y,
                w: p.w, h: p.h,
                rotation: 0,
                borderWidth: borderPx || 6
            })
        }
        
        panelItems = panelItems.slice() // trigger binding update
        panelsChanged()
    }
    
    function addBubble(type, canvasX, canvasY) {
        var bw = 300, bh = 200
        if (type === "shout") { bw = 280; bh = 180 }
        else if (type === "thought") { bw = 260; bh = 180 }
        else if (type === "narration") { bw = 350; bh = 100 }
        
        bubbleItems.push({
            id: nextId++,
            x: canvasX - bw/2,
            y: canvasY - bh/2,
            w: bw, h: bh,
            type: type,
            text: "Text here...",
            tailAngle: 200,
            fontSize: 18
        })
        
        bubbleItems = bubbleItems.slice()
        bubblesChanged()
    }
    
    function clearAll() {
        panelItems = []
        bubbleItems = []
        selectedPanelId = -1
        selectedBubbleId = -1
        panelsChanged()
        bubblesChanged()
    }
    
    function deselectAll() {
        selectedPanelId = -1
        selectedBubbleId = -1
    }
    
    function deleteSelected() {
        if (selectedPanelId >= 0) {
            panelItems = panelItems.filter(function(p) { return p.id !== selectedPanelId })
            selectedPanelId = -1
            panelsChanged()
        }
        if (selectedBubbleId >= 0) {
            bubbleItems = bubbleItems.filter(function(b) { return b.id !== selectedBubbleId })
            selectedBubbleId = -1
            bubblesChanged()
        }
    }
    
    function flattenToLayer() {
        if (!targetCanvas) return
        if (panelItems.length === 0 && bubbleItems.length === 0) return
        
        // Flatten panels using the C++ backend
        if (panelItems.length > 0) {
            targetCanvas.drawPanelLayout("custom_overlay", 0, 6, 0)
            // Future: pass actual panel rects to C++ for accurate rendering
        }
        
        clearAll()
    }
    
    // ── Click-away deselect ──
    MouseArea {
        anchors.fill: parent
        enabled: root.hasSelection
        z: -1
        onClicked: root.deselectAll()
    }
    
    // ═══════════════ PANEL REPEATER ═══════════════
    Repeater {
        model: root.panelItems.length
        
        delegate: Item {
            id: panelDelegate
            
            property var panelData: root.panelItems[index] || {}
            property bool isSelected: panelData.id === root.selectedPanelId
            property real zoom: targetCanvas ? targetCanvas.zoomLevel : 1.0
            property real offX: targetCanvas ? targetCanvas.viewOffset.x * zoom : 0
            property real offY: targetCanvas ? targetCanvas.viewOffset.y * zoom : 0
            
            x: offX + panelData.x * zoom
            y: offY + panelData.y * zoom
            width: panelData.w * zoom
            height: panelData.h * zoom
            rotation: panelData.rotation || 0
            z: isSelected ? 50 : 10
            
            // Panel border rect
            Rectangle {
                id: panelRect
                anchors.fill: parent
                color: "transparent"
                border.color: isSelected ? accentColor : "#000000"
                border.width: (panelData.borderWidth || 6) * zoom
                radius: 0
                
                // Inner highlight when selected
                Rectangle {
                    visible: isSelected
                    anchors.fill: parent
                    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.06)
                    border.color: accentColor
                    border.width: 2
                }
            }
            
            // Click to select
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.selectedBubbleId = -1
                    root.selectedPanelId = panelData.id
                }
            }
            
            // ── DRAG HANDLE (center) ──
            MouseArea {
                id: panelDragArea
                anchors.fill: parent
                enabled: isSelected
                cursorShape: isSelected ? Qt.SizeAllCursor : Qt.ArrowCursor
                
                property real startX: 0
                property real startY: 0
                property real startPx: 0
                property real startPy: 0
                
                onPressed: {
                    startX = mouseX; startY = mouseY
                    startPx = panelData.x; startPy = panelData.y
                }
                onPositionChanged: {
                    if (pressed) {
                        var dx = (mouseX - startX) / zoom
                        var dy = (mouseY - startY) / zoom
                        panelData.x = startPx + dx
                        panelData.y = startPy + dy
                        root.panelItems = root.panelItems.slice()
                    }
                }
            }
            
            // ── RESIZE HANDLES (visible when selected) ──
            Repeater {
                model: isSelected ? [
                    {hx: 0, hy: 0, cursor: Qt.SizeFDiagCursor, edge: "tl"},
                    {hx: 1, hy: 0, cursor: Qt.SizeBDiagCursor, edge: "tr"},
                    {hx: 0, hy: 1, cursor: Qt.SizeBDiagCursor, edge: "bl"},
                    {hx: 1, hy: 1, cursor: Qt.SizeFDiagCursor, edge: "br"},
                    {hx: 0.5, hy: 0, cursor: Qt.SizeVerCursor, edge: "t"},
                    {hx: 0.5, hy: 1, cursor: Qt.SizeVerCursor, edge: "b"},
                    {hx: 0, hy: 0.5, cursor: Qt.SizeHorCursor, edge: "l"},
                    {hx: 1, hy: 0.5, cursor: Qt.SizeHorCursor, edge: "r"}
                ] : []
                
                delegate: Rectangle {
                    width: 14; height: 14; radius: 3
                    x: modelData.hx * panelDelegate.width - 7
                    y: modelData.hy * panelDelegate.height - 7
                    color: "white"
                    border.color: accentColor; border.width: 2
                    z: 100
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: modelData.cursor
                        
                        property real startMx: 0
                        property real startMy: 0
                        property real origX: 0
                        property real origY: 0
                        property real origW: 0
                        property real origH: 0
                        
                        onPressed: {
                            startMx = mouse.x + parent.x
                            startMy = mouse.y + parent.y
                            origX = panelData.x
                            origY = panelData.y
                            origW = panelData.w
                            origH = panelData.h
                        }
                        
                        onPositionChanged: {
                            if (!pressed) return
                            var dx = (mouse.x + parent.x - startMx) / zoom
                            var dy = (mouse.y + parent.y - startMy) / zoom
                            var e = modelData.edge
                            var minS = 40
                            
                            if (e === "tl" || e === "l" || e === "bl") {
                                var newX = origX + dx
                                var newW = origW - dx
                                if (newW > minS) { panelData.x = newX; panelData.w = newW }
                            }
                            if (e === "tr" || e === "r" || e === "br") {
                                var nw = origW + dx
                                if (nw > minS) panelData.w = nw
                            }
                            if (e === "tl" || e === "t" || e === "tr") {
                                var newY = origY + dy
                                var newH = origH - dy
                                if (newH > minS) { panelData.y = newY; panelData.h = newH }
                            }
                            if (e === "bl" || e === "b" || e === "br") {
                                var nh = origH + dy
                                if (nh > minS) panelData.h = nh
                            }
                            
                            root.panelItems = root.panelItems.slice()
                        }
                    }
                }
            }
            
            // ── Selected panel actions bar ──
            Rectangle {
                visible: isSelected
                anchors.top: parent.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                width: panelActionsRow.width + 20
                height: 36; radius: 18
                color: "#1a1a1e"
                border.color: "#333"; border.width: 1
                z: 200
                
                Row {
                    id: panelActionsRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                    // Duplicate
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: dupPanelMa.containsMouse ? "#333" : "transparent"
                        Text { text: "⧉"; color: "#aaa"; font.pixelSize: 14; anchors.centerIn: parent }
                        MouseArea {
                            id: dupPanelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.panelItems.push({
                                    id: root.nextId++,
                                    x: panelData.x + 30, y: panelData.y + 30,
                                    w: panelData.w, h: panelData.h,
                                    rotation: 0, borderWidth: panelData.borderWidth
                                })
                                root.panelItems = root.panelItems.slice()
                                root.panelsChanged()
                            }
                        }
                        ToolTip.visible: dupPanelMa.containsMouse; ToolTip.text: "Duplicate"; ToolTip.delay: 400
                    }
                    
                    // Delete
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: delPanelMa.containsMouse ? "#3a1515" : "transparent"
                        Text { text: "✕"; color: delPanelMa.containsMouse ? "#ff4444" : "#aaa"; font.pixelSize: 12; anchors.centerIn: parent }
                        MouseArea {
                            id: delPanelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteSelected()
                        }
                        ToolTip.visible: delPanelMa.containsMouse; ToolTip.text: "Delete"; ToolTip.delay: 400
                    }
                }
            }
        }
    }
    
    // ═══════════════ BUBBLE REPEATER ═══════════════
    Repeater {
        model: root.bubbleItems.length
        
        delegate: Item {
            id: bubbleDelegate
            
            property var bubbleData: root.bubbleItems[index] || {}
            property bool isSelected: bubbleData.id === root.selectedBubbleId
            property string bubbleType: bubbleData.type || "speech"
            property real zoom: targetCanvas ? targetCanvas.zoomLevel : 1.0
            property real offX: targetCanvas ? targetCanvas.viewOffset.x * zoom : 0
            property real offY: targetCanvas ? targetCanvas.viewOffset.y * zoom : 0
            
            x: offX + bubbleData.x * zoom
            y: offY + bubbleData.y * zoom
            width: bubbleData.w * zoom
            height: bubbleData.h * zoom
            z: isSelected ? 60 : 20
            
            // ── Bubble Shape ──
            Canvas {
                id: bubbleCanvas
                anchors.fill: parent
                anchors.margins: -20 * zoom // Extra room for tail
                
                property string bType: bubbleType
                property real tailAngle: bubbleData.tailAngle || 200
                property bool sel: isSelected
                
                onBTypeChanged: requestPaint()
                onTailAngleChanged: requestPaint()
                onSelChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    
                    var pad = 20 * zoom
                    var bx = pad, by = pad
                    var bw = width - 2 * pad, bh = height - 2 * pad
                    
                    ctx.fillStyle = "white"
                    ctx.strokeStyle = sel ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 1.0).toString() : "#000000"
                    ctx.lineWidth = 3 * zoom
                    ctx.lineJoin = "round"
                    
                    if (bType === "speech" || bType === "oval") {
                        // Oval speech bubble
                        ctx.beginPath()
                        ctx.ellipse(bx, by, bw, bh)
                        ctx.fill()
                        ctx.stroke()
                        
                        // Tail
                        var cx = bx + bw/2, cy = by + bh/2
                        var rad = tailAngle * Math.PI / 180
                        var tailLen = Math.min(bw, bh) * 0.4
                        var tx = cx + Math.cos(rad) * (bw/2 + tailLen * 0.4)
                        var ty = cy + Math.sin(rad) * (bh/2 + tailLen * 0.4)
                        var spread = 15 * zoom
                        var a1 = rad - 0.15, a2 = rad + 0.15
                        
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(a1) * bw*0.35, cy + Math.sin(a1) * bh*0.35)
                        ctx.lineTo(tx, ty)
                        ctx.lineTo(cx + Math.cos(a2) * bw*0.35, cy + Math.sin(a2) * bh*0.35)
                        ctx.fillStyle = "white"
                        ctx.fill()
                        ctx.stroke()
                        
                        // Re-draw bottom of ellipse to cover tail base
                        ctx.beginPath()
                        ctx.ellipse(bx + 2, by + 2, bw - 4, bh - 4)
                        ctx.fillStyle = "white"
                        ctx.fill()
                        
                    } else if (bType === "rect" || bType === "narration") {
                        // Rectangular narration box
                        var r = bType === "narration" ? 0 : 10 * zoom
                        ctx.beginPath()
                        ctx.roundedRect(bx, by, bw, bh, r, r)
                        ctx.fill()
                        ctx.stroke()
                        
                    } else if (bType === "thought") {
                        // Cloud thought bubble
                        ctx.beginPath()
                        var cx2 = bx + bw/2, cy2 = by + bh/2
                        var rx = bw/2, ry = bh/2
                        var bumps = 12
                        for (var i = 0; i < bumps; i++) {
                            var a = (i / bumps) * Math.PI * 2
                            var na = ((i + 1) / bumps) * Math.PI * 2
                            var bumpSize = 0.15
                            var px = cx2 + Math.cos(a) * rx
                            var py = cy2 + Math.sin(a) * ry
                            var npx = cx2 + Math.cos(na) * rx
                            var npy = cy2 + Math.sin(na) * ry
                            var cpx = cx2 + Math.cos((a + na)/2) * (rx * (1 + bumpSize))
                            var cpy = cy2 + Math.sin((a + na)/2) * (ry * (1 + bumpSize))
                            
                            if (i === 0) ctx.moveTo(px, py)
                            ctx.quadraticCurveTo(cpx, cpy, npx, npy)
                        }
                        ctx.closePath()
                        ctx.fill()
                        ctx.stroke()
                        
                        // Small thought circles
                        var trad = tailAngle * Math.PI / 180
                        for (var j = 1; j <= 3; j++) {
                            var dist = (bw/2 + 15 * j) * zoom / zoom
                            var dotR = (8 - j * 2) * zoom
                            var dotX = cx2 + Math.cos(trad) * dist * zoom
                            var dotY = cy2 + Math.sin(trad) * dist * zoom
                            ctx.beginPath()
                            ctx.ellipse(dotX - dotR, dotY - dotR, dotR*2, dotR*2)
                            ctx.fill()
                            ctx.stroke()
                        }
                        
                    } else if (bType === "shout") {
                        // Starburst / shout bubble
                        ctx.beginPath()
                        var cx3 = bx + bw/2, cy3 = by + bh/2
                        var points = 16
                        for (var k = 0; k < points; k++) {
                            var angle = (k / points) * Math.PI * 2 - Math.PI/2
                            var rOuter = (k % 2 === 0) ? 1.0 : 0.75
                            var prx = cx3 + Math.cos(angle) * bw/2 * rOuter
                            var pry = cy3 + Math.sin(angle) * bh/2 * rOuter
                            if (k === 0) ctx.moveTo(prx, pry)
                            else ctx.lineTo(prx, pry)
                        }
                        ctx.closePath()
                        ctx.fill()
                        ctx.stroke()
                    }
                }
            }
            
            // ── Text Content ──
            TextEdit {
                id: bubbleText
                anchors.centerIn: parent
                width: parent.width * 0.75
                text: bubbleData.text || ""
                color: "#000000"
                font.pixelSize: (bubbleData.fontSize || 18) * zoom
                font.family: bubbleType === "shout" ? "Impact" : "Comic Sans MS, sans-serif"
                font.bold: bubbleType === "shout"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: TextEdit.WordWrap
                readOnly: !isSelected
                selectByMouse: isSelected
                
                onTextChanged: {
                    if (bubbleData) bubbleData.text = text
                }
            }
            
            // ── Click to select ──
            MouseArea {
                anchors.fill: parent
                enabled: !isSelected
                onClicked: {
                    root.selectedPanelId = -1
                    root.selectedBubbleId = bubbleData.id
                }
            }
            
            // ── Drag (when selected) ──
            MouseArea {
                id: bubbleDrag
                anchors.fill: parent
                enabled: isSelected && !bubbleText.cursorVisible
                cursorShape: Qt.SizeAllCursor
                z: -1
                
                property real startX: 0
                property real startY: 0
                property real origBx: 0
                property real origBy: 0
                
                onPressed: {
                    startX = mouseX; startY = mouseY
                    origBx = bubbleData.x; origBy = bubbleData.y
                }
                onPositionChanged: {
                    if (pressed) {
                        bubbleData.x = origBx + (mouseX - startX) / zoom
                        bubbleData.y = origBy + (mouseY - startY) / zoom
                        root.bubbleItems = root.bubbleItems.slice()
                    }
                }
            }
            
            // ── Resize Handles ──
            Repeater {
                model: isSelected ? [
                    {hx: 0, hy: 0, cursor: Qt.SizeFDiagCursor, edge: "tl"},
                    {hx: 1, hy: 0, cursor: Qt.SizeBDiagCursor, edge: "tr"},
                    {hx: 0, hy: 1, cursor: Qt.SizeBDiagCursor, edge: "bl"},
                    {hx: 1, hy: 1, cursor: Qt.SizeFDiagCursor, edge: "br"}
                ] : []
                
                delegate: Rectangle {
                    width: 14; height: 14; radius: 7
                    x: modelData.hx * bubbleDelegate.width - 7
                    y: modelData.hy * bubbleDelegate.height - 7
                    color: "white"
                    border.color: accentColor; border.width: 2
                    z: 100
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: modelData.cursor
                        
                        property real sx: 0
                        property real sy: 0
                        property real oX: 0
                        property real oY: 0
                        property real oW: 0
                        property real oH: 0
                        
                        onPressed: {
                            sx = mouse.x + parent.x; sy = mouse.y + parent.y
                            oX = bubbleData.x; oY = bubbleData.y
                            oW = bubbleData.w; oH = bubbleData.h
                        }
                        onPositionChanged: {
                            if (!pressed) return
                            var dx = (mouse.x + parent.x - sx) / zoom
                            var dy = (mouse.y + parent.y - sy) / zoom
                            var e = modelData.edge
                            var ms = 60
                            
                            if (e === "tl") {
                                if (oW - dx > ms) { bubbleData.x = oX + dx; bubbleData.w = oW - dx }
                                if (oH - dy > ms) { bubbleData.y = oY + dy; bubbleData.h = oH - dy }
                            } else if (e === "tr") {
                                if (oW + dx > ms) bubbleData.w = oW + dx
                                if (oH - dy > ms) { bubbleData.y = oY + dy; bubbleData.h = oH - dy }
                            } else if (e === "bl") {
                                if (oW - dx > ms) { bubbleData.x = oX + dx; bubbleData.w = oW - dx }
                                if (oH + dy > ms) bubbleData.h = oH + dy
                            } else if (e === "br") {
                                if (oW + dx > ms) bubbleData.w = oW + dx
                                if (oH + dy > ms) bubbleData.h = oH + dy
                            }
                            root.bubbleItems = root.bubbleItems.slice()
                            bubbleCanvas.requestPaint()
                        }
                    }
                }
            }
            
            // ── Tail direction handle ──
            Rectangle {
                visible: isSelected && (bubbleType === "speech" || bubbleType === "oval" || bubbleType === "thought")
                width: 18; height: 18; radius: 9
                color: "#FFD700"
                border.color: "#aa8800"; border.width: 2
                z: 150
                
                property real tailRad: (bubbleData.tailAngle || 200) * Math.PI / 180
                x: bubbleDelegate.width/2 + Math.cos(tailRad) * (bubbleDelegate.width * 0.55) - 9
                y: bubbleDelegate.height/2 + Math.sin(tailRad) * (bubbleDelegate.height * 0.55) - 9
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.CrossCursor
                    
                    onPositionChanged: {
                        if (pressed) {
                            var gx = parent.x + mouse.x
                            var gy = parent.y + mouse.y
                            var cx = bubbleDelegate.width / 2
                            var cy = bubbleDelegate.height / 2
                            var angle = Math.atan2(gy - cy, gx - cx) * 180 / Math.PI
                            bubbleData.tailAngle = angle
                            root.bubbleItems = root.bubbleItems.slice()
                            bubbleCanvas.requestPaint()
                        }
                    }
                }
                
                ToolTip.visible: false
                ToolTip.text: "Drag to move tail"
            }
            
            // ── Bubble actions bar ──
            Rectangle {
                visible: isSelected
                anchors.top: parent.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                width: bubbleActionsRow.width + 20
                height: 36; radius: 18
                color: "#1a1a1e"
                border.color: "#333"; border.width: 1
                z: 200
                
                Row {
                    id: bubbleActionsRow
                    anchors.centerIn: parent
                    spacing: 6
                    
                    // Font size controls
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: fsMinus.containsMouse ? "#333" : "transparent"
                        Text { text: "A-"; color: "#aaa"; font.pixelSize: 11; anchors.centerIn: parent }
                        MouseArea {
                            id: fsMinus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bubbleData.fontSize = Math.max(8, (bubbleData.fontSize || 18) - 2)
                                root.bubbleItems = root.bubbleItems.slice()
                            }
                        }
                    }
                    
                    Text {
                        text: (bubbleData.fontSize || 18) + "pt"
                        color: "#888"; font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: fsPlus.containsMouse ? "#333" : "transparent"
                        Text { text: "A+"; color: "#aaa"; font.pixelSize: 11; anchors.centerIn: parent }
                        MouseArea {
                            id: fsPlus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bubbleData.fontSize = Math.min(72, (bubbleData.fontSize || 18) + 2)
                                root.bubbleItems = root.bubbleItems.slice()
                            }
                        }
                    }
                    
                    Rectangle { width: 1; height: 20; color: "#333"; anchors.verticalCenter: parent.verticalCenter }
                    
                    // Duplicate
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: dupBubbleMa.containsMouse ? "#333" : "transparent"
                        Text { text: "⧉"; color: "#aaa"; font.pixelSize: 14; anchors.centerIn: parent }
                        MouseArea {
                            id: dupBubbleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.bubbleItems.push({
                                    id: root.nextId++,
                                    x: bubbleData.x + 30, y: bubbleData.y + 30,
                                    w: bubbleData.w, h: bubbleData.h,
                                    type: bubbleData.type, text: bubbleData.text,
                                    tailAngle: bubbleData.tailAngle, fontSize: bubbleData.fontSize
                                })
                                root.bubbleItems = root.bubbleItems.slice()
                                root.bubblesChanged()
                            }
                        }
                    }
                    
                    // Delete
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: delBubbleMa.containsMouse ? "#3a1515" : "transparent"
                        Text { text: "✕"; color: delBubbleMa.containsMouse ? "#ff4444" : "#aaa"; font.pixelSize: 12; anchors.centerIn: parent }
                        MouseArea {
                            id: delBubbleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteSelected()
                        }
                    }
                }
            }
        }
    }
}
