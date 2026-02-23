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
    
    // Manga Guidelines
    property bool showMangaGuides: false
    property real mangaSafeMargin: 70
    property real mangaTrimMargin: 35
    
    // Data models
    property var panelItems: []    // [{id, x, y, w, h, rotation}]
    property var bubbleItems: []   // [{id, x, y, w, h, type, text, tailAngle}]
    property var shapeItems: []    // [{id, x, y, w, h, type, strokeColor, strokeWidth, fillColor, rotation}]
    property int nextId: 1
    
    // Throttle timer for zoom/pan redraws
    property real _zoom: targetCanvas ? targetCanvas.zoomLevel : 1.0
    property real _offX: targetCanvas ? targetCanvas.viewOffset.x * _zoom : 0
    property real _offY: targetCanvas ? targetCanvas.viewOffset.y * _zoom : 0
    
    // Unified panel redraw request (batched)
    function requestPanelRedraw() {
        panelRedrawTimer.restart()
    }
    
    Timer {
        id: panelRedrawTimer
        interval: 16  // ~60fps max
        repeat: false
        onTriggered: unifiedPanelCanvas.requestPaint()
    }
    
    // Selection state
    property int selectedPanelId: -1
    property int selectedBubbleId: -1
    property int selectedShapeId: -1
    property bool hasSelection: selectedPanelId >= 0 || selectedBubbleId >= 0 || selectedShapeId >= 0
    
    // Shape drawing mode
    property bool shapeDrawingActive: false
    property string shapeDrawingType: ""  // "rect", "ellipse", "line"
    property color shapeStrokeColor: "#000000"
    property real shapeStrokeWidth: 4
    property color shapeFillColor: "transparent"
    
    signal panelsChanged()
    signal bubblesChanged()
    signal shapesChanged()
    signal shapeDrawingFinished()
    
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
                borderWidth: borderPx || 6,
                pts: [{x:0,y:0}, {x:p.w,y:0}, {x:p.w,y:p.h}, {x:0,y:p.h}]
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
    
    function addShape(type, canvasX, canvasY, canvasW, canvasH) {
        shapeItems.push({
            id: nextId++,
            x: canvasX, y: canvasY,
            w: canvasW, h: canvasH,
            type: type,
            strokeColor: shapeStrokeColor.toString(),
            strokeWidth: shapeStrokeWidth,
            fillColor: shapeFillColor.toString(),
            rotation: 0
        })
        shapeItems = shapeItems.slice()
        shapesChanged()
    }
    
    function startShapeDrawing(type) {
        shapeDrawingActive = true
        shapeDrawingType = type
        deselectAll()
        console.log("[ComicOverlay] Shape drawing started: " + type)
    }
    
    function stopShapeDrawing() {
        shapeDrawingActive = false
        shapeDrawingType = ""
    }
    
    function clearAll() {
        panelItems = []
        bubbleItems = []
        shapeItems = []
        selectedPanelId = -1
        selectedBubbleId = -1
        selectedShapeId = -1
        panelsChanged()
        bubblesChanged()
        shapesChanged()
    }
    
    function deselectAll() {
        selectedPanelId = -1
        selectedBubbleId = -1
        selectedShapeId = -1
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
        if (selectedShapeId >= 0) {
            shapeItems = shapeItems.filter(function(s) { return s.id !== selectedShapeId })
            selectedShapeId = -1
            shapesChanged()
        }
    }
    
    function setSelectedBorderWidth(val) {
        if (selectedPanelId >= 0) {
            for (var i = 0; i < panelItems.length; i++) {
                if (panelItems[i].id === selectedPanelId) {
                    panelItems[i].borderWidth = val;
                    break;
                }
            }
            panelItems = panelItems.slice();
            panelsChanged();
        }
        if (selectedShapeId >= 0) {
            for (var j = 0; j < shapeItems.length; j++) {
                if (shapeItems[j].id === selectedShapeId) {
                    shapeItems[j].strokeWidth = val;
                    break;
                }
            }
            shapeItems = shapeItems.slice();
            shapesChanged();
        }
    }
    
    function setSelectedOpacity(val) {
        // Opacity can be handled by flattening or individual item property
        // For now let's just log or set a property if we add it to models
        console.log("[ComicOverlay] Opacity update requested:", val);
    }
    
    function flattenToLayer() {
        if (!targetCanvas) return
        if (panelItems.length === 0 && bubbleItems.length === 0 && shapeItems.length === 0) return
        
        // Flatten panels using the C++ backend
        if (panelItems.length > 0) {
            targetCanvas.drawPanelLayout("custom_overlay", 0, 6, 0)
        }
        
        clearAll()
    }
    
    // ── Click-away deselect ──
    MouseArea {
        anchors.fill: parent
        enabled: root.hasSelection && !root.shapeDrawingActive
        z: -1
        onClicked: root.deselectAll()
    }
    
    // ═══════════════ UNIFIED PANEL CANVAS ═══════════════
    // Single canvas draws ALL panels in one pass — much faster than
    // N individual Canvas items that each repaint on zoom/pan.
    Canvas {
        id: unifiedPanelCanvas
        anchors.fill: parent
        z: 10
        
        // Repaint when data changes
        Connections {
            target: root
            function onPanelsChanged() { root.requestPanelRedraw() }
        }
        // Repaint when zoom/offset changes (throttled)
        onVisibleChanged: if (visible) requestPaint()
        
        // Watch for zoom changes via the root properties
        property real _z: root._zoom
        property real _ox: root._offX
        property real _oy: root._offY
        on_ZChanged: root.requestPanelRedraw()
        on_OxChanged: root.requestPanelRedraw()
        on_OyChanged: root.requestPanelRedraw()
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var zoom = root._zoom
            var offX = root._offX
            var offY = root._offY
            
            // Draw Manga Guides (below panels)
            if (root.showMangaGuides && root.targetCanvas) {
                var cw = root.targetCanvas.canvasWidth * zoom
                var ch = root.targetCanvas.canvasHeight * zoom
                var safeM = root.mangaSafeMargin * zoom
                var trimM = root.mangaTrimMargin * zoom
                
                ctx.lineWidth = 1 * zoom
                if (ctx.lineWidth < 1) ctx.lineWidth = 1
                
                // Safe Area (Inner - Blue)
                ctx.strokeStyle = "rgba(0, 150, 255, 0.4)"
                ctx.strokeRect(offX + safeM, offY + safeM, cw - safeM*2, ch - safeM*2)
                
                // Trim Area / Crop Marks (Outer - Red)
                ctx.strokeStyle = "rgba(255, 0, 0, 0.4)"
                ctx.beginPath()
                
                var cmLen = 20 * zoom
                // Top-left
                ctx.moveTo(offX + trimM, offY + trimM - cmLen)
                ctx.lineTo(offX + trimM, offY + trimM)
                ctx.lineTo(offX + trimM - cmLen, offY + trimM)
                
                // Top-right
                ctx.moveTo(offX + cw - trimM, offY + trimM - cmLen)
                ctx.lineTo(offX + cw - trimM, offY + trimM)
                ctx.lineTo(offX + cw - trimM + cmLen, offY + trimM)
                
                // Bottom-left
                ctx.moveTo(offX + trimM, offY + ch - trimM + cmLen)
                ctx.lineTo(offX + trimM, offY + ch - trimM)
                ctx.lineTo(offX + trimM - cmLen, offY + ch - trimM)
                
                // Bottom-right
                ctx.moveTo(offX + cw - trimM, offY + ch - trimM + cmLen)
                ctx.lineTo(offX + cw - trimM, offY + ch - trimM)
                ctx.lineTo(offX + cw - trimM + cmLen, offY + ch - trimM)
                
                ctx.stroke()
            }
            
            var items = root.panelItems
            for (var i = 0; i < items.length; i++) {
                var pd = items[i]
                var sel = (pd.id === root.selectedPanelId)
                var bw = (pd.borderWidth || 6) * zoom
                ctx.strokeStyle = sel ? root.accentColor.toString() : "#000000"
                ctx.lineWidth = bw
                ctx.lineJoin = "miter"
                var p = pd.pts
                if (p && p.length === 4) {
                    ctx.beginPath()
                    ctx.moveTo(offX + (pd.x + p[0].x) * zoom, offY + (pd.y + p[0].y) * zoom)
                    ctx.lineTo(offX + (pd.x + p[1].x) * zoom, offY + (pd.y + p[1].y) * zoom)
                    ctx.lineTo(offX + (pd.x + p[2].x) * zoom, offY + (pd.y + p[2].y) * zoom)
                    ctx.lineTo(offX + (pd.x + p[3].x) * zoom, offY + (pd.y + p[3].y) * zoom)
                    ctx.closePath()
                } else {
                    ctx.beginPath()
                    ctx.rect(offX + pd.x * zoom + bw/2, offY + pd.y * zoom + bw/2,
                             pd.w * zoom - bw, pd.h * zoom - bw)
                }
                if (sel) {
                    ctx.fillStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.06).toString()
                    ctx.fill()
                }
                ctx.stroke()
            }
        }
    }
    
    // ═══════════════ SHAPE DRAWING OVERLAY ═══════════════
    // When shapeDrawingActive, intercept mouse to draw shapes
    MouseArea {
        id: shapeDrawArea
        anchors.fill: parent
        enabled: root.shapeDrawingActive
        z: 500
        cursorShape: Qt.CrossCursor
        hoverEnabled: true
        
        property real startX: 0
        property real startY: 0
        property bool drawing: false
        
        onPressed: function(mouse) {
            var zoom = targetCanvas ? targetCanvas.zoomLevel : 1.0
            var offX = targetCanvas ? targetCanvas.viewOffset.x * zoom : 0
            var offY = targetCanvas ? targetCanvas.viewOffset.y * zoom : 0
            startX = (mouse.x - offX) / zoom
            startY = (mouse.y - offY) / zoom
            drawing = true
            drawPreview.requestPaint()
        }
        
        onPositionChanged: function(mouse) {
            if (drawing) {
                drawPreview.requestPaint()
            }
        }
        
        onReleased: function(mouse) {
            if (!drawing) return
            drawing = false
            
            var zoom = targetCanvas ? targetCanvas.zoomLevel : 1.0
            var offX = targetCanvas ? targetCanvas.viewOffset.x * zoom : 0
            var offY = targetCanvas ? targetCanvas.viewOffset.y * zoom : 0
            var endX = (mouse.x - offX) / zoom
            var endY = (mouse.y - offY) / zoom
            
            // Calculate normalized rect
            var sx = Math.min(startX, endX)
            var sy = Math.min(startY, endY)
            var sw = Math.abs(endX - startX)
            var sh = Math.abs(endY - startY)
            
            // Minimum size check
            if (sw < 5 && sh < 5) {
                // Too small: use a default 100x100 shape
                sw = 100; sh = 100
                sx = startX - 50; sy = startY - 50
            }
            
            // For lines, store start/end as x,y,w,h (w=endX-startX, h=endY-startY)
            if (root.shapeDrawingType === "line") {
                root.addShape("line", startX, startY, endX - startX, endY - startY)
            } else {
                root.addShape(root.shapeDrawingType, sx, sy, sw, sh)
            }
            
            drawPreview.requestPaint()
            console.log("[ComicOverlay] Shape created: " + root.shapeDrawingType + " at " + sx + "," + sy + " size " + sw + "x" + sh)
        }
        
        // Live preview while drawing
        Canvas {
            id: drawPreview
            anchors.fill: parent
            visible: shapeDrawArea.drawing
            z: 501
            
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (!shapeDrawArea.drawing) return
                
                var zoom = targetCanvas ? targetCanvas.zoomLevel : 1.0
                var offX = targetCanvas ? targetCanvas.viewOffset.x * zoom : 0
                var offY = targetCanvas ? targetCanvas.viewOffset.y * zoom : 0
                
                var sx = shapeDrawArea.startX * zoom + offX
                var sy = shapeDrawArea.startY * zoom + offY
                var mx = shapeDrawArea.mouseX
                var my = shapeDrawArea.mouseY
                
                ctx.strokeStyle = root.shapeStrokeColor.toString()
                ctx.lineWidth = root.shapeStrokeWidth * zoom
                ctx.setLineDash([6, 4])
                
                if (root.shapeFillColor.toString() !== "transparent" && root.shapeFillColor.a > 0) {
                    ctx.fillStyle = Qt.rgba(root.shapeFillColor.r, root.shapeFillColor.g, root.shapeFillColor.b, 0.3).toString()
                } else {
                    ctx.fillStyle = "transparent"
                }
                
                if (root.shapeDrawingType === "rect") {
                    var rx = Math.min(sx, mx), ry = Math.min(sy, my)
                    var rw = Math.abs(mx - sx), rh = Math.abs(my - sy)
                    if (ctx.fillStyle !== "transparent") ctx.fillRect(rx, ry, rw, rh)
                    ctx.strokeRect(rx, ry, rw, rh)
                } else if (root.shapeDrawingType === "ellipse") {
                    var ex = Math.min(sx, mx), ey = Math.min(sy, my)
                    var ew = Math.abs(mx - sx), eh = Math.abs(my - sy)
                    ctx.beginPath()
                    ctx.ellipse(ex, ey, ew, eh)
                    if (ctx.fillStyle !== "transparent") ctx.fill()
                    ctx.stroke()
                } else if (root.shapeDrawingType === "line") {
                    ctx.beginPath()
                    ctx.moveTo(sx, sy)
                    ctx.lineTo(mx, my)
                    ctx.stroke()
                }
                
                ctx.setLineDash([])
            }
        }
    }
    
    // ── Shape drawing mode indicator ──
    Rectangle {
        visible: root.shapeDrawingActive
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: shapeIndicatorRow.width + 30
        height: 40
        radius: 20
        color: "#ee1a1a22"
        border.color: accentColor
        border.width: 1.5
        z: 600
        
        Row {
            id: shapeIndicatorRow
            anchors.centerIn: parent
            spacing: 10
            
            Text {
                text: root.shapeDrawingType === "rect" ? "✦ Draw Rectangle" :
                      root.shapeDrawingType === "ellipse" ? "✦ Draw Ellipse" : "✦ Draw Line"
                color: "white"
                font.pixelSize: 13
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: "— click & drag on canvas"
                color: "#888"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Rectangle {
                width: 1; height: 20; color: "#333"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Rectangle {
                width: 24; height: 24; radius: 12
                color: cancelDrawMa.containsMouse ? "#3a1515" : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                
                Text {
                    text: "✕"
                    color: cancelDrawMa.containsMouse ? "#ff4444" : "#aaa"
                    font.pixelSize: 12
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    id: cancelDrawMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.stopShapeDrawing()
                }
            }
        }
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
            
            // Panel border is now drawn by unifiedPanelCanvas above (single pass, much faster)
            // Keep an invisible Item for hit-testing the panel area

            
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
            
            // ── CORNER EDIT HANDLES (visible when selected) ──
            Repeater {
                model: isSelected ? [0, 1, 2, 3] : []
                
                delegate: Rectangle {
                    width: 16; height: 16; radius: 8
                    
                    property var pData: panelData.pts && panelData.pts.length === 4 ? panelData.pts : [{x:0,y:0}, {x:panelData.w,y:0}, {x:panelData.w,y:panelData.h}, {x:0,y:panelData.h}]
                    property real pX: pData[modelData].x * zoom
                    property real pY: pData[modelData].y * zoom
                    
                    x: pX - 8
                    y: pY - 8
                    color: "white"
                    border.color: accentColor; border.width: 2
                    z: 100
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.CrossCursor
                        
                        property real startMx: 0
                        property real startMy: 0
                        property real origX: 0
                        property real origY: 0
                        
                        onPressed: {
                            var p = panelDelegate.mapFromItem(this, mouse.x, mouse.y)
                            startMx = p.x
                            startMy = p.y
                            origX = pData[modelData].x
                            origY = pData[modelData].y
                        }
                        
                        onPositionChanged: {
                            if (!pressed) return
                            var p = panelDelegate.mapFromItem(this, mouse.x, mouse.y)
                            var dx = (p.x - startMx) / zoom
                            var dy = (p.y - startMy) / zoom
                            
                            var nx = origX + dx
                            var ny = origY + dy

                            // Edit the points to maintain a rectangle for "scaling"
                            var newPts = []
                            for(var i=0; i<4; i++) {
                                newPts.push({x: pData[i].x, y: pData[i].y})
                            }
                            
                            // Apply movement to the dragged point
                            newPts[modelData].x = nx
                            newPts[modelData].y = ny
                            
                            // Constraints to keep it rectangular (Standard scaling behavior)
                            if (modelData === 0) { // TL
                                newPts[1].y = ny; newPts[3].x = nx
                            } else if (modelData === 1) { // TR
                                newPts[0].y = ny; newPts[2].x = nx
                            } else if (modelData === 2) { // BR
                                newPts[3].y = ny; newPts[1].x = nx
                            } else if (modelData === 3) { // BL
                                newPts[2].y = ny; newPts[0].x = nx
                            }
                            
                            panelData.pts = newPts
                            // Also update W and H for consistency if needed
                            panelData.w = Math.abs(newPts[1].x - newPts[0].x)
                            panelData.h = Math.abs(newPts[3].y - newPts[0].y)
                            
                            root.panelItems = root.panelItems.slice()
                            root.requestPanelRedraw()
                        }
                    }
                }
            }
            
            // ── Selected panel actions bar ──
            Rectangle {
                visible: isSelected
                anchors.top: parent.bottom
                anchors.topMargin: 40
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
    
    // ═══════════════ SHAPE REPEATER ═══════════════
    Repeater {
        model: root.shapeItems.length
        
        delegate: Item {
            id: shapeDelegate
            
            property var shapeData: root.shapeItems[index] || {}
            property bool isSelected: shapeData.id === root.selectedShapeId
            property string shapeType: shapeData.type || "rect"
            property real zoom: targetCanvas ? targetCanvas.zoomLevel : 1.0
            property real offX: targetCanvas ? targetCanvas.viewOffset.x * zoom : 0
            property real offY: targetCanvas ? targetCanvas.viewOffset.y * zoom : 0
            
            // For line shapes, x/y/w/h store start and delta
            x: shapeType === "line" ? offX + Math.min(shapeData.x, shapeData.x + shapeData.w) * zoom - 5
                                    : offX + shapeData.x * zoom
            y: shapeType === "line" ? offY + Math.min(shapeData.y, shapeData.y + shapeData.h) * zoom - 5
                                    : offY + shapeData.y * zoom
            width: shapeType === "line" ? Math.abs(shapeData.w) * zoom + 10
                                       : shapeData.w * zoom
            height: shapeType === "line" ? Math.abs(shapeData.h) * zoom + 10
                                        : shapeData.h * zoom
            z: isSelected ? 55 : 15
            
            // Shape rendering
            Canvas {
                id: shapeCanvas
                anchors.fill: parent
                
                property bool sel: isSelected
                onSelChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d")
                    var w = width, h = height
                    ctx.clearRect(0, 0, w, h)
                    
                    var sd = shapeData
                    ctx.strokeStyle = isSelected ? accentColor.toString() : (sd.strokeColor || "#000000")
                    ctx.lineWidth = (sd.strokeWidth || 4) * zoom
                    ctx.lineJoin = "round"
                    ctx.lineCap = "round"
                    
                    var fc = sd.fillColor || "transparent"
                    if (fc !== "transparent") {
                        ctx.fillStyle = fc
                    }
                    
                    if (shapeType === "rect") {
                        var lw = ctx.lineWidth / 2
                        if (fc !== "transparent") ctx.fillRect(lw, lw, w - ctx.lineWidth, h - ctx.lineWidth)
                        ctx.strokeRect(lw, lw, w - ctx.lineWidth, h - ctx.lineWidth)
                    } else if (shapeType === "ellipse") {
                        var lw2 = ctx.lineWidth / 2
                        ctx.beginPath()
                        ctx.ellipse(lw2, lw2, w - ctx.lineWidth, h - ctx.lineWidth)
                        if (fc !== "transparent") ctx.fill()
                        ctx.stroke()
                    } else if (shapeType === "line") {
                        // Map line endpoints into local coords
                        var x1 = (sd.x - Math.min(sd.x, sd.x + sd.w)) * zoom + 5
                        var y1 = (sd.y - Math.min(sd.y, sd.y + sd.h)) * zoom + 5
                        var x2 = (sd.x + sd.w - Math.min(sd.x, sd.x + sd.w)) * zoom + 5
                        var y2 = (sd.y + sd.h - Math.min(sd.y, sd.y + sd.h)) * zoom + 5
                        ctx.beginPath()
                        ctx.moveTo(x1, y1)
                        ctx.lineTo(x2, y2)
                        ctx.stroke()
                    }
                    
                    // Selection box
                    if (isSelected) {
                        ctx.strokeStyle = accentColor.toString()
                        ctx.lineWidth = 1.5
                        ctx.setLineDash([4, 3])
                        ctx.strokeRect(0, 0, w, h)
                        ctx.setLineDash([])
                    }
                }
            }
            
            // Click to select
            MouseArea {
                anchors.fill: parent
                enabled: !root.shapeDrawingActive
                onClicked: {
                    root.selectedPanelId = -1
                    root.selectedBubbleId = -1
                    root.selectedShapeId = shapeData.id
                }
            }
            
            // Drag (when selected)
            MouseArea {
                id: shapeDragArea
                anchors.fill: parent
                enabled: isSelected && !root.shapeDrawingActive
                cursorShape: isSelected ? Qt.SizeAllCursor : Qt.ArrowCursor
                z: -1
                
                property real startMx: 0
                property real startMy: 0
                property real origX: 0
                property real origY: 0
                
                onPressed: {
                    startMx = mouseX; startMy = mouseY
                    origX = shapeData.x; origY = shapeData.y
                }
                onPositionChanged: {
                    if (pressed) {
                        var dx = (mouseX - startMx) / zoom
                        var dy = (mouseY - startMy) / zoom
                        shapeData.x = origX + dx
                        shapeData.y = origY + dy
                        root.shapeItems = root.shapeItems.slice()
                    }
                }
            }
            
            // Resize handles
            Repeater {
                model: isSelected && shapeType !== "line" ? [
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
                    width: 12; height: 12; radius: 3
                    x: modelData.hx * shapeDelegate.width - 6
                    y: modelData.hy * shapeDelegate.height - 6
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
                            oX = shapeData.x; oY = shapeData.y
                            oW = shapeData.w; oH = shapeData.h
                        }
                        onPositionChanged: {
                            if (!pressed) return
                            var dx = (mouse.x + parent.x - sx) / zoom
                            var dy = (mouse.y + parent.y - sy) / zoom
                            var e = modelData.edge
                            var ms = 10
                            
                            if (e === "tl" || e === "l" || e === "bl") {
                                if (oW - dx > ms) { shapeData.x = oX + dx; shapeData.w = oW - dx }
                            }
                            if (e === "tr" || e === "r" || e === "br") {
                                if (oW + dx > ms) shapeData.w = oW + dx
                            }
                            if (e === "tl" || e === "t" || e === "tr") {
                                if (oH - dy > ms) { shapeData.y = oY + dy; shapeData.h = oH - dy }
                            }
                            if (e === "bl" || e === "b" || e === "br") {
                                if (oH + dy > ms) shapeData.h = oH + dy
                            }
                            root.shapeItems = root.shapeItems.slice()
                            shapeCanvas.requestPaint()
                        }
                    }
                }
            }
            
            // Line endpoints (for line type)
            Repeater {
                model: isSelected && shapeType === "line" ? [
                    {ex: 0, ey: 0, label: "start"},
                    {ex: 1, ey: 1, label: "end"}
                ] : []
                
                delegate: Rectangle {
                    width: 14; height: 14; radius: 7
                    color: "white"
                    border.color: accentColor; border.width: 2
                    z: 100
                    
                    // Map to local coords of the delegate
                    property real localX: modelData.label === "start" 
                        ? (shapeData.x - Math.min(shapeData.x, shapeData.x + shapeData.w)) * zoom + 5
                        : (shapeData.x + shapeData.w - Math.min(shapeData.x, shapeData.x + shapeData.w)) * zoom + 5
                    property real localY: modelData.label === "start"
                        ? (shapeData.y - Math.min(shapeData.y, shapeData.y + shapeData.h)) * zoom + 5
                        : (shapeData.y + shapeData.h - Math.min(shapeData.y, shapeData.y + shapeData.h)) * zoom + 5
                    
                    x: localX - 7
                    y: localY - 7
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.CrossCursor
                        
                        property real sx: 0
                        property real sy: 0
                        property real origVal1: 0
                        property real origVal2: 0
                        
                        onPressed: {
                            sx = mouse.x + parent.x
                            sy = mouse.y + parent.y
                            if (modelData.label === "start") {
                                origVal1 = shapeData.x
                                origVal2 = shapeData.y
                            } else {
                                origVal1 = shapeData.w
                                origVal2 = shapeData.h
                            }
                        }
                        onPositionChanged: {
                            if (!pressed) return
                            var dx = (mouse.x + parent.x - sx) / zoom
                            var dy = (mouse.y + parent.y - sy) / zoom
                            
                            if (modelData.label === "start") {
                                shapeData.x = origVal1 + dx
                                shapeData.y = origVal2 + dy
                                shapeData.w -= dx
                                shapeData.h -= dy
                            } else {
                                shapeData.w = origVal1 + dx
                                shapeData.h = origVal2 + dy
                            }
                            root.shapeItems = root.shapeItems.slice()
                            shapeCanvas.requestPaint()
                        }
                    }
                }
            }
            
            // Actions bar when selected
            Rectangle {
                visible: isSelected
                anchors.top: parent.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                width: shapeActRow.width + 20
                height: 36; radius: 18
                color: "#1a1a1e"
                border.color: "#333"; border.width: 1
                z: 200
                
                Row {
                    id: shapeActRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                    // Duplicate
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: dupShpMa.containsMouse ? "#333" : "transparent"
                        Text { text: "⧉"; color: "#aaa"; font.pixelSize: 14; anchors.centerIn: parent }
                        MouseArea {
                            id: dupShpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.shapeItems.push({
                                    id: root.nextId++,
                                    x: shapeData.x + 20, y: shapeData.y + 20,
                                    w: shapeData.w, h: shapeData.h,
                                    type: shapeData.type,
                                    strokeColor: shapeData.strokeColor,
                                    strokeWidth: shapeData.strokeWidth,
                                    fillColor: shapeData.fillColor,
                                    rotation: 0
                                })
                                root.shapeItems = root.shapeItems.slice()
                                root.shapesChanged()
                            }
                        }
                        ToolTip.visible: dupShpMa.containsMouse; ToolTip.text: "Duplicate"; ToolTip.delay: 400
                    }
                    
                    // Delete
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: delShpMa.containsMouse ? "#3a1515" : "transparent"
                        Text { text: "✕"; color: delShpMa.containsMouse ? "#ff4444" : "#aaa"; font.pixelSize: 12; anchors.centerIn: parent }
                        MouseArea {
                            id: delShpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteSelected()
                        }
                        ToolTip.visible: delShpMa.containsMouse; ToolTip.text: "Delete"; ToolTip.delay: 400
                    }
                }
            }
        }
    }
}
