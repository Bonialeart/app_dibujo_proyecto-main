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
    property Item selectedBubbleDelegate: null
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
    
    // ── Helper functions for Speech Bubbles ──
    function constrainTail(tx, ty, bw, bh, type) {
        var rx = bw / 2
        var ry = bh / 2
        var minDistance = 15
        
        if (type === "speech" || type === "oval" || type === "double_oval" || type === "thought") {
            var distRatio = Math.sqrt((tx * tx) / (rx * rx) + (ty * ty) / (ry * ry))
            var angle = Math.atan2(ty, tx)
            var boundX = rx * Math.cos(angle)
            var boundY = ry * Math.sin(angle)
            var targetX = boundX + minDistance * Math.cos(angle)
            var targetY = boundY + minDistance * Math.sin(angle)
            
            var currentDist = Math.sqrt(tx * tx + ty * ty)
            var targetDist = Math.sqrt(targetX * targetX + targetY * targetY)
            if (currentDist < targetDist) {
                return { x: targetX, y: targetY }
            }
        } else {
            var absX = Math.abs(tx)
            var absY = Math.abs(ty)
            var limX = rx + minDistance
            var limY = ry + minDistance
            
            if (absX < limX && absY < limY) {
                var diffX = limX - absX
                var diffY = limY - absY
                var newTx = tx
                var newTy = ty
                if (diffX < diffY) {
                    newTx = tx >= 0 ? limX : -limX
                } else {
                    newTy = ty >= 0 ? limY : -limY
                }
                return { x: newTx, y: newTy }
            }
        }
        return { x: tx, y: ty }
    }
    
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
        
        var tx = -bw * 0.4
        var ty = bh * 0.6
        
        bubbleItems.push({
            id: nextId++,
            x: canvasX - bw/2,
            y: canvasY - bh/2,
            w: bw, h: bh,
            type: type,
            text: "Dialogue...",
            tailX: tx,
            tailY: ty,
            tailWidth: 30,
            strokeColor: "#000000",
            fillColor: "#ffffff",
            strokeWidth: 3,
            cornerRadius: 16,
            fontSize: 18,
            autoResize: false,
            autoFitText: false,
            textColor: "#000000",
            fontFamily: "Comic Sans MS, sans-serif",
            bold: type === "shout",
            italic: false,
            alignment: Text.AlignHCenter
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
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Image {
                    source: "image://icons/close.svg"
                    width: 10; height: 10
                    anchors.centerIn: parent
                    opacity: cancelDrawMa.containsMouse ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
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
                        border.color: delPanelMa.containsMouse ? "#662222" : "transparent"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        
                        Image {
                            source: "image://icons/trash.svg"
                            width: 12; height: 12
                            anchors.centerIn: parent
                            opacity: delPanelMa.containsMouse ? 1.0 : 0.6
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        
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
            
            // Custom fully reactive QML properties
            property real bubbleX: bubbleData.x
            property real bubbleY: bubbleData.y
            property real bubbleW: bubbleData.w
            property real bubbleH: bubbleData.h
            
            property real strokeWidth: bubbleData.strokeWidth !== undefined ? bubbleData.strokeWidth : 3
            property string strokeColor: bubbleData.strokeColor !== undefined ? bubbleData.strokeColor : "#000000"
            property string fillColor: bubbleData.fillColor !== undefined ? bubbleData.fillColor : "#ffffff"
            property real cornerRadius: bubbleData.cornerRadius !== undefined ? bubbleData.cornerRadius : 16
            property real tailWidth: bubbleData.tailWidth !== undefined ? bubbleData.tailWidth : 30
            property real tailX: bubbleData.tailX !== undefined ? bubbleData.tailX : -bubbleW * 0.4
            property real tailY: bubbleData.tailY !== undefined ? bubbleData.tailY : bubbleH * 0.6
            
            property int fontSize: bubbleData.fontSize !== undefined ? bubbleData.fontSize : 18
            property bool autoResize: bubbleData.autoResize || false
            property bool autoFitText: bubbleData.autoFitText || false
            property string textColor: bubbleData.textColor !== undefined ? bubbleData.textColor : "#000000"
            property string fontFamily: bubbleData.fontFamily !== undefined ? bubbleData.fontFamily : "Comic Sans MS, sans-serif"
            property bool bold: bubbleData.bold !== undefined ? bubbleData.bold : (bubbleType === "shout")
            property bool italic: bubbleData.italic || false
            property int alignment: bubbleData.alignment !== undefined ? bubbleData.alignment : Text.AlignHCenter
            property string text: bubbleData.text || ""
            
            // Selection tracking
            onIsSelectedChanged: {
                if (isSelected) {
                    root.selectedBubbleDelegate = bubbleDelegate
                } else if (root.selectedBubbleDelegate === bubbleDelegate) {
                    root.selectedBubbleDelegate = null
                }
            }
            
            function keepTailConstrained() {
                if (bubbleType === "narration") return
                var constrained = root.constrainTail(tailX, tailY, bubbleW, bubbleH, bubbleType)
                if (Math.abs(tailX - constrained.x) > 0.05 || Math.abs(tailY - constrained.y) > 0.05) {
                    tailX = constrained.x
                    tailY = constrained.y
                }
            }
            
            Component.onCompleted: {
                keepTailConstrained()
            }
            
            // Sync back to plain JS object
            onBubbleXChanged: { if (bubbleData) bubbleData.x = bubbleX }
            onBubbleYChanged: { if (bubbleData) bubbleData.y = bubbleY }
            onBubbleWChanged: {
                if (bubbleData) bubbleData.w = bubbleW
                keepTailConstrained()
            }
            onBubbleHChanged: {
                if (bubbleData) bubbleData.h = bubbleH
                keepTailConstrained()
            }
            onStrokeWidthChanged: { if (bubbleData) bubbleData.strokeWidth = strokeWidth }
            onStrokeColorChanged: { if (bubbleData) bubbleData.strokeColor = strokeColor }
            onFillColorChanged: { if (bubbleData) bubbleData.fillColor = fillColor }
            onCornerRadiusChanged: { if (bubbleData) bubbleData.cornerRadius = cornerRadius }
            onTailWidthChanged: { if (bubbleData) bubbleData.tailWidth = tailWidth }
            onTailXChanged: {
                if (bubbleData) bubbleData.tailX = tailX
                keepTailConstrained()
            }
            onTailYChanged: {
                if (bubbleData) bubbleData.tailY = tailY
                keepTailConstrained()
            }
            onFontSizeChanged: { if (bubbleData) bubbleData.fontSize = fontSize }
            onAutoResizeChanged: { if (bubbleData) bubbleData.autoResize = autoResize }
            onAutoFitTextChanged: { if (bubbleData) bubbleData.autoFitText = autoFitText }
            onTextColorChanged: { if (bubbleData) bubbleData.textColor = textColor }
            onFontFamilyChanged: { if (bubbleData) bubbleData.fontFamily = fontFamily }
            onBoldChanged: { if (bubbleData) bubbleData.bold = bold }
            onItalicChanged: { if (bubbleData) bubbleData.italic = italic }
            onAlignmentChanged: { if (bubbleData) bubbleData.alignment = alignment }
            onTextChanged: { if (bubbleData) bubbleData.text = text }
            onBubbleTypeChanged: {
                if (bubbleData) bubbleData.type = bubbleType
                keepTailConstrained()
            }
            
            x: offX + bubbleX * zoom
            y: offY + bubbleY * zoom
            width: bubbleW * zoom
            height: bubbleH * zoom
            z: isSelected ? 60 : 20
            
            // ── Bubble Shape ──
            Canvas {
                id: bubbleCanvas
                anchors.fill: parent
                
                // Dynamically calculate margin to ensure the tail tip is never clipped in any direction
                property real extraPadding: Math.max(30, Math.max(Math.abs(tailX) - bubbleW/2, Math.abs(tailY) - bubbleH/2) + 20)
                anchors.margins: -extraPadding * zoom
                
                property string bType: bubbleType
                property bool sel: isSelected
                property real sWidth: strokeWidth
                property string sColor: strokeColor
                property string fColor: fillColor
                property real cRadius: cornerRadius
                property real tWidth: tailWidth
                property real tX: tailX
                property real tY: tailY
                
                onBTypeChanged: requestPaint()
                onSelChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onSWidthChanged: requestPaint()
                onSColorChanged: requestPaint()
                onFColorChanged: requestPaint()
                onCRadiusChanged: requestPaint()
                onTWidthChanged: requestPaint()
                onTXChanged: requestPaint()
                onTYChanged: requestPaint()
                
                Connections {
                    target: root
                    function onBubblesChanged() {
                        bubbleCanvas.requestPaint()
                    }
                }
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    
                    var pad = extraPadding * zoom
                    var bx = pad, by = pad
                    var bw = width - 2 * pad, bh = height - 2 * pad
                    var cx = width / 2, cy = height / 2
                    
                    var strokeColor = sColor
                    var fillColor = fColor
                    var strokeWidth = sWidth * zoom
                    var cornerRadius = cRadius * zoom
                    var tWidth = this.tWidth * zoom
                    
                    ctx.fillStyle = fillColor
                    ctx.strokeStyle = sel ? root.accentColor.toString() : strokeColor
                    ctx.lineWidth = strokeWidth
                    ctx.lineJoin = "round"
                    ctx.lineCap = "round"
                    
                    // Support offsets for double bubble base lower-right anchoring
                    var subCx = cx
                    var subCy = cy
                    var subBw = bw
                    var subBh = bh
                    if (bType === "double_oval" || bType === "double_rounded") {
                        var ox = bw * 0.12
                        var oy = bh * 0.12
                        subCx = cx + ox
                        subCy = cy + oy
                        subBw = bw * 0.76
                        subBh = bh * 0.76
                    }
                    
                    var tTipX = cx + tX * zoom
                    var tTipY = cy + tY * zoom
                    
                    var theta = Math.atan2(tTipY - subCy, tTipX - subCx)
                    
                    // Boundary raycast intersection point B
                    var bX = subCx
                    var bY = subCy
                    if (bType === "speech" || bType === "oval" || bType === "double_oval" || bType === "thought") {
                        // Ellipse intersection
                        bX = subCx + (subBw / 2) * Math.cos(theta)
                        bY = subCy + (subBh / 2) * Math.sin(theta)
                    } else {
                        // Rectangle intersection
                        var dx = Math.cos(theta)
                        var dy = Math.sin(theta)
                        var tx = dx !== 0 ? Math.abs((subBw / 2) / dx) : 999999
                        var ty = dy !== 0 ? Math.abs((subBh / 2) / dy) : 999999
                        var tVal = Math.min(tx, ty)
                        bX = subCx + tVal * dx
                        bY = subCy + tVal * dy
                    }
                    
                    // Calculate precise tail base angles and intersection points
                    var hasTail = (bType !== "narration" && bType !== "thought")
                    var a1X = 0, a1Y = 0, a2X = 0, a2Y = 0
                    var theta1 = 0, theta2 = 0
                    
                    if (hasTail) {
                        var rx = subBw / 2
                        var ry = subBh / 2
                        var rTheta = 0
                        if (bType === "rect" || bType === "rounded_rect" || bType === "double_rounded") {
                            var dx = Math.cos(theta)
                            var dy = Math.sin(theta)
                            var tx = dx !== 0 ? Math.abs((subBw / 2) / dx) : 999999
                            var ty = dy !== 0 ? Math.abs((subBh / 2) / dy) : 999999
                            rTheta = Math.min(tx, ty)
                        } else {
                            rTheta = 1.0 / Math.sqrt(Math.pow(Math.cos(theta) / rx, 2) + Math.pow(Math.sin(theta) / ry, 2))
                        }
                        
                        var deltaTheta = (tWidth / 2) / rTheta
                        theta1 = theta - deltaTheta
                        theta2 = theta + deltaTheta
                        
                        if (bType === "rect" || bType === "rounded_rect" || bType === "double_rounded") {
                            var a1 = getRectIntersection(subCx, subCy, subBw, subBh, theta1)
                            var a2 = getRectIntersection(subCx, subCy, subBw, subBh, theta2)
                            a1X = a1.x; a1Y = a1.y
                            a2X = a2.x; a2Y = a2.y
                        } else {
                            a1X = subCx + rx * Math.cos(theta1)
                            a1Y = subCy + ry * Math.sin(theta1)
                            a2X = subCx + rx * Math.cos(theta2)
                            a2Y = subCy + ry * Math.sin(theta2)
                        }
                    }
                    
                    function isAngleBetween(target, start, end) {
                        var t = (target % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI)
                        var s = (start % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI)
                        var e = (end % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI)
                        if (s <= e) {
                            return t >= s && t <= e
                        } else {
                            return t >= s || t <= e
                        }
                    }
                    
                    function getRectIntersection(cx, cy, w, h, phi) {
                        var dx = Math.cos(phi)
                        var dy = Math.sin(phi)
                        var tx = dx !== 0 ? Math.abs((w / 2) / dx) : 999999
                        var ty = dy !== 0 ? Math.abs((h / 2) / dy) : 999999
                        var tVal = Math.min(tx, ty)
                        return {
                            x: cx + tVal * dx,
                            y: cy + tVal * dy,
                            t: tVal
                        }
                    }
                    
                    function pathBubbleShape(c, type, subCx, subCy, subBw, subBh, cornerRadius, theta1, theta2, a1x, a1y, a2x, a2y, tTipX, tTipY) {
                        function getClockwiseDist(angle, base) {
                            var diff = angle - base
                            return (diff % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI)
                        }

                        if (type === "speech" || type === "oval") {
                            var rx = subBw / 2
                            var ry = subBh / 2
                            
                            var startA = theta2
                            var endA = theta1
                            if (endA <= startA) {
                                endA += 2 * Math.PI
                            }
                            
                            c.moveTo(subCx + rx * Math.cos(startA), subCy + ry * Math.sin(startA))
                            var steps = 60
                            for (var step = 1; step <= steps; step++) {
                                var t = startA + (endA - startA) * (step / steps)
                                c.lineTo(subCx + rx * Math.cos(t), subCy + ry * Math.sin(t))
                            }
                            
                            c.lineTo(tTipX, tTipY)
                            c.lineTo(subCx + rx * Math.cos(startA), subCy + ry * Math.sin(startA))
                            c.closePath()
                        } else if (type === "rect" || type === "rounded_rect" || type === "narration") {
                            var bx = subCx - subBw / 2
                            var by = subCy - subBh / 2
                            var bw = subBw
                            var bh = subBh
                            
                            var isRounded = (type === "rounded_rect")
                            
                            if (type === "narration") {
                                c.rect(bx, by, bw, bh)
                                return
                            }
                            
                            var corners = [
                                { x: bx, y: by, angle: Math.atan2(by - subCy, bx - subCx) },
                                { x: bx + bw, y: by, angle: Math.atan2(by - subCy, bx + bw - subCx) },
                                { x: bx + bw, y: by + bh, angle: Math.atan2(by + bh - subCy, bx + bw - subCx) },
                                { x: bx, y: by + bh, angle: Math.atan2(by + bh - subCy, bx - subCx) }
                            ]
                            
                            var activeCorners = []
                            for (var i = 0; i < 4; i++) {
                                var cr = corners[i]
                                if (isAngleBetween(cr.angle, theta2, theta1)) {
                                    activeCorners.push(cr)
                                }
                            }
                            
                            activeCorners.sort(function(a, b) {
                                return getClockwiseDist(a.angle, theta2) - getClockwiseDist(b.angle, theta2)
                            })
                            
                            c.moveTo(a2x, a2y)
                            
                            for (var j = 0; j < activeCorners.length; j++) {
                                var curr = activeCorners[j]
                                var nextPt = (j < activeCorners.length - 1) ? activeCorners[j + 1] : { x: a1x, y: a1y }
                                
                                if (isRounded) {
                                    c.arcTo(curr.x, curr.y, nextPt.x, nextPt.y, cornerRadius)
                                } else {
                                    c.lineTo(curr.x, curr.y)
                                }
                            }
                            
                            c.lineTo(a1x, a1y)
                            c.lineTo(tTipX, tTipY)
                            c.lineTo(a2x, a2y)
                        } else if (type === "shout") {
                            var rx = subBw / 2
                            var ry = subBh / 2
                            var spikyPoints = []
                            var points = 24
                            for (var k = 0; k < points; k++) {
                                var angle = (k / points) * Math.PI * 2 - Math.PI/2
                                var rOuter = (k % 2 === 0) ? 1.0 : 0.70
                                var prx = subCx + Math.cos(angle) * rx * rOuter
                                var pry = subCy + Math.sin(angle) * ry * rOuter
                                spikyPoints.push({ x: prx, y: pry, angle: angle })
                            }
                            
                            var activePoints = []
                            for (var i = 0; i < spikyPoints.length; i++) {
                                var pt = spikyPoints[i]
                                if (isAngleBetween(pt.angle, theta2, theta1)) {
                                    activePoints.push(pt)
                                }
                            }
                            
                            activePoints.sort(function(a, b) {
                                return getClockwiseDist(a.angle, theta2) - getClockwiseDist(b.angle, theta2)
                            })
                            
                            c.moveTo(a2x, a2y)
                            for (var i = 0; i < activePoints.length; i++) {
                                c.lineTo(activePoints[i].x, activePoints[i].y)
                            }
                            c.lineTo(a1x, a1y)
                            c.lineTo(tTipX, tTipY)
                            c.lineTo(a2x, a2y)
                        } else if (type === "thought") {
                            var rx = subBw/2, ry = subBh/2
                            var bumps = 12
                            for (var i = 0; i < bumps; i++) {
                                var a = (i / bumps) * Math.PI * 2
                                var na = ((i + 1) / bumps) * Math.PI * 2
                                var bumpSize = 0.15
                                var px = subCx + Math.cos(a) * rx
                                var py = subCy + Math.sin(a) * ry
                                var npx = subCx + Math.cos(na) * rx
                                var npy = subCy + Math.sin(na) * ry
                                var cpx = subCx + Math.cos((a + na)/2) * (rx * (1 + bumpSize))
                                var cpy = subCy + Math.sin((a + na)/2) * (ry * (1 + bumpSize))
                                
                                if (i === 0) c.moveTo(px, py)
                                c.quadraticCurveTo(cpx, cpy, npx, npy)
                            }
                        }
                    }
                    
                    function drawMainUnifiedPath(c) {
                        c.beginPath()
                        if (bType === "double_oval") {
                            // First bubble (no tail)
                            var dbOx = bw * 0.12
                            var dbOy = bh * 0.12
                            var dbW1 = bw * 0.76
                            var dbH1 = bh * 0.76
                            
                            c.ellipse(cx - dbOx - dbW1/2, cy - dbOy - dbH1/2, dbW1, dbH1)
                            
                            // Second bubble with tail
                            var dbCx = cx + dbOx
                            var dbCy = cy + dbOy
                            var dbBw = dbW1
                            var dbBh = dbH1
                            
                            var dbRx = dbBw / 2
                            var dbRy = dbBh / 2
                            var dbTheta = Math.atan2(tTipY - dbCy, tTipX - dbCx)
                            var dbRTheta = 1.0 / Math.sqrt(Math.pow(Math.cos(dbTheta) / dbRx, 2) + Math.pow(Math.sin(dbTheta) / dbRy, 2))
                            var dbDeltaTheta = (tWidth / 2) / dbRTheta
                            var dbT1 = dbTheta - dbDeltaTheta
                            var dbT2 = dbTheta + dbDeltaTheta
                            var dbA1x = dbCx + dbRx * Math.cos(dbT1)
                            var dbA1y = dbCy + dbRy * Math.sin(dbT1)
                            var dbA2x = dbCx + dbRx * Math.cos(dbT2)
                            var dbA2y = dbCy + dbRy * Math.sin(dbT2)
                            
                            pathBubbleShape(c, "oval", dbCx, dbCy, dbBw, dbBh, cornerRadius, dbT1, dbT2, dbA1x, dbA1y, dbA2x, dbA2y, tTipX, tTipY)
                        } else if (bType === "double_rounded") {
                            // First bubble (no tail)
                            var dbOx = bw * 0.12
                            var dbOy = bh * 0.12
                            var dbW1 = bw * 0.76
                            var dbH1 = bh * 0.76
                            
                            c.roundedRect(cx - dbOx - dbW1/2, cy - dbOy - dbH1/2, dbW1, dbH1, cornerRadius, cornerRadius)
                            
                            // Second bubble with tail
                            var dbCx = cx + dbOx
                            var dbCy = cy + dbOy
                            var dbBw = dbW1
                            var dbBh = dbH1
                            
                            var dbTheta = Math.atan2(tTipY - dbCy, tTipX - dbCx)
                            var dbDx = Math.cos(dbTheta)
                            var dbDy = Math.sin(dbTheta)
                            var dbTx = dbDx !== 0 ? Math.abs((dbBw / 2) / dbDx) : 999999
                            var dbTy = dbDy !== 0 ? Math.abs((dbBh / 2) / dbDy) : 999999
                            var dbRTheta = Math.min(dbTx, dbTy)
                            
                            var dbDeltaTheta = (tWidth / 2) / dbRTheta
                            var dbT1 = dbTheta - dbDeltaTheta
                            var dbT2 = dbTheta + dbDeltaTheta
                            
                            var dbA1 = getRectIntersection(dbCx, dbCy, dbBw, dbBh, dbT1)
                            var dbA2 = getRectIntersection(dbCx, dbCy, dbBw, dbBh, dbT2)
                            
                            pathBubbleShape(c, "rounded_rect", dbCx, dbCy, dbBw, dbBh, cornerRadius, dbT1, dbT2, dbA1.x, dbA1.y, dbA2.x, dbA2.y, tTipX, tTipY)
                        } else {
                            console.log("[drawMainUnifiedPath else]", "bType:", bType, "theta1:", theta1, "theta2:", theta2, "a1X:", a1X, "a1Y:", a1Y, "a2X:", a2X, "a2Y:", a2Y)
                            pathBubbleShape(c, bType, subCx, subCy, subBw, subBh, cornerRadius, theta1, theta2, a1X, a1Y, a2X, a2Y, tTipX, tTipY)
                        }
                    }
                    // ═══════════════ RENDER PASSES ═══════════════
                    if (bType === "double_oval" || bType === "double_rounded") {
                        // Double Bubble Merge Render
                        ctx.beginPath()
                        drawMainUnifiedPath(ctx)
                        if (fillColor !== "transparent") {
                            ctx.fillStyle = fillColor
                            ctx.fill()
                        }
                        
                        ctx.strokeStyle = sel ? root.accentColor.toString() : strokeColor
                        ctx.lineWidth = strokeWidth * 2
                        ctx.lineJoin = "round"
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        drawMainUnifiedPath(ctx)
                        ctx.stroke()
                        
                        if (fillColor !== "transparent") {
                            ctx.fillStyle = fillColor
                            ctx.beginPath()
                            drawMainUnifiedPath(ctx)
                            ctx.fill()
                        } else {
                            ctx.save()
                            ctx.globalCompositeOperation = "destination-out"
                            ctx.fillStyle = "rgba(0,0,0,1.0)"
                            ctx.beginPath()
                            drawMainUnifiedPath(ctx)
                            ctx.fill()
                            ctx.restore()
                        }
                    } else if (bType === "thought") {
                        // Thought Bubble Spiky Bumps & Dots
                        ctx.beginPath()
                        drawMainUnifiedPath(ctx)
                        if (fillColor !== "transparent") {
                            ctx.fillStyle = fillColor
                            ctx.fill()
                        }
                        ctx.strokeStyle = sel ? root.accentColor.toString() : strokeColor
                        ctx.lineWidth = strokeWidth
                        ctx.lineJoin = "round"
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        drawMainUnifiedPath(ctx)
                        ctx.stroke()
                        
                        // 3 thought circles
                        for (var j = 1; j <= 3; j++) {
                            var ratio = j / 4.0
                            var dotX = bX + (tTipX - bX) * ratio
                            var dotY = bY + (tTipY - bY) * ratio
                            var dotR = (10 - j * 2) * zoom
                            ctx.beginPath()
                            ctx.arc(dotX, dotY, dotR, 0, Math.PI * 2)
                            if (fillColor !== "transparent") {
                                ctx.fillStyle = fillColor
                                ctx.fill()
                            }
                            ctx.strokeStyle = sel ? root.accentColor.toString() : strokeColor
                            ctx.lineWidth = strokeWidth
                            ctx.stroke()
                        }
                    } else {
                        // Standard Bubbles (speech, oval, rect, rounded_rect, shout, narration)
                        ctx.beginPath()
                        drawMainUnifiedPath(ctx)
                        if (fillColor !== "transparent") {
                            ctx.fillStyle = fillColor
                            ctx.fill()
                        }
                        
                        ctx.strokeStyle = sel ? root.accentColor.toString() : strokeColor
                        ctx.lineWidth = strokeWidth
                        ctx.lineJoin = "round"
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        drawMainUnifiedPath(ctx)
                        ctx.stroke()
                    }
                }
            }
            
            Text {
                id: fitCalcText
                visible: false
                wrapMode: Text.Wrap
            }
            
            // ── Auto Adjusting helpers ──
            function updateAutoHeight() {
                if (!autoResize) return
                var ch = bubbleText.contentHeight
                var th = 0
                if (bubbleType === "rect" || bubbleType === "rounded_rect" || bubbleType === "double_rounded" || bubbleType === "narration") {
                    th = ch / zoom + 50
                } else {
                    th = (ch / zoom) * 1.414 + 40
                }
                th = Math.max(60, th)
                if (Math.abs(bubbleH - th) > 1.0) {
                    bubbleH = th
                }
            }
            
            function adjustFontSizeToFit() {
                if (!autoFitText) return
                
                var minFs = 8
                var maxFs = 60
                var bestFs = fontSize || 18
                
                var textToFit = bubbleText.text
                if (!textToFit || textToFit.trim() === "") return
                
                fitCalcText.text = textToFit
                fitCalcText.font.family = bubbleText.font.family
                fitCalcText.font.bold = bubbleText.font.bold
                fitCalcText.font.italic = bubbleText.font.italic
                fitCalcText.width = (bubbleType === "rect" || bubbleType === "narration" || bubbleType === "rounded_rect" || bubbleType === "double_rounded") ? bubbleW * 0.85 : bubbleW * 0.70
                
                var targetH = (bubbleType === "rect" || bubbleType === "narration" || bubbleType === "rounded_rect" || bubbleType === "double_rounded") ? bubbleH * 0.85 : bubbleH * 0.70
                
                var low = minFs
                var high = maxFs
                
                while (low <= high) {
                    var mid = Math.floor((low + high) / 2)
                    fitCalcText.font.pixelSize = mid
                    
                    if (fitCalcText.contentHeight <= targetH) {
                        bestFs = mid
                        low = mid + 1
                    } else {
                        high = mid - 1
                    }
                }
                
                if (fontSize !== bestFs) {
                    fontSize = bestFs
                }
            }
            
            onWidthChanged: {
                if (autoResize) updateAutoHeight()
                if (autoFitText) adjustFontSizeToFit()
            }
            onHeightChanged: {
                if (autoFitText) adjustFontSizeToFit()
            }
            
            Connections {
                target: root
                function onBubblesChanged() {
                    bubbleCanvas.requestPaint()
                    if (autoResize) updateAutoHeight()
                    if (autoFitText) adjustFontSizeToFit()
                }
            }
            
            // ── Text Content ──
            TextEdit {
                id: bubbleText
                anchors.centerIn: parent
                width: (bubbleType === "rect" || bubbleType === "narration" || bubbleType === "rounded_rect" || bubbleType === "double_rounded") ? parent.width * 0.85 : parent.width * 0.70
                text: bubbleDelegate.text
                color: textColor
                font.pixelSize: fontSize * zoom
                font.family: fontFamily
                font.bold: bold
                font.italic: italic
                horizontalAlignment: alignment
                verticalAlignment: Text.AlignVCenter
                wrapMode: TextEdit.WordWrap
                readOnly: !isSelected
                selectByMouse: isSelected
                
                onContentHeightChanged: {
                    if (autoResize) updateAutoHeight()
                    if (autoFitText) adjustFontSizeToFit()
                }
                onTextChanged: {
                    if (bubbleDelegate.text !== text) {
                        bubbleDelegate.text = text
                    }
                    if (autoResize) updateAutoHeight()
                    if (autoFitText) adjustFontSizeToFit()
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
                    origBx = bubbleX; origBy = bubbleY
                }
                onPositionChanged: {
                    if (pressed) {
                        bubbleX = origBx + (mouseX - startX) / zoom
                        bubbleY = origBy + (mouseY - startY) / zoom
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
                            oX = bubbleX; oY = bubbleY
                            oW = bubbleW; oH = bubbleH
                        }
                        onPositionChanged: {
                            if (!pressed) return
                            var dx = (mouse.x + parent.x - sx) / zoom
                            var dy = (mouse.y + parent.y - sy) / zoom
                            var e = modelData.edge
                            var ms = 60
                            
                            if (e === "tl") {
                                if (oW - dx > ms) { bubbleX = oX + dx; bubbleW = oW - dx }
                                if (oH - dy > ms) { bubbleY = oY + dy; bubbleH = oH - dy }
                            } else if (e === "tr") {
                                if (oW + dx > ms) bubbleW = oW + dx
                                if (oH - dy > ms) { bubbleY = oY + dy; bubbleH = oH - dy }
                            } else if (e === "bl") {
                                if (oW - dx > ms) { bubbleX = oX + dx; bubbleW = oW - dx }
                                if (oH + dy > ms) bubbleH = oH + dy
                            } else if (e === "br") {
                                if (oW + dx > ms) bubbleW = oW + dx
                                if (oH + dy > ms) bubbleH = oH + dy
                            }
                            bubbleCanvas.requestPaint()
                        }
                    }
                }
            }
            
            // ── Tail direction handle ──
            Rectangle {
                visible: isSelected && bubbleType !== "narration"
                width: 18; height: 18; radius: 9
                color: "#FFD700"
                border.color: "#aa8800"; border.width: 2
                z: 150
                
                x: bubbleDelegate.width / 2 + tailX * zoom - 9
                y: bubbleDelegate.height / 2 + tailY * zoom - 9
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.CrossCursor
                    
                    onPositionChanged: {
                        if (pressed) {
                            var p = bubbleDelegate.mapFromItem(this, mouse.x, mouse.y)
                            var cx = bubbleDelegate.width / 2
                            var cy = bubbleDelegate.height / 2
                            tailX = (p.x - cx) / zoom
                            tailY = (p.y - cy) / zoom
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
                                fontSize = Math.max(8, fontSize - 2)
                            }
                        }
                    }
                    
                    Text {
                        text: fontSize + "pt"
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
                                fontSize = Math.min(72, fontSize + 2)
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
                                    x: bubbleX + 30, y: bubbleY + 30,
                                    w: bubbleW, h: bubbleH,
                                    type: bubbleType, text: text,
                                    tailX: tailX, tailY: tailY,
                                    tailWidth: tailWidth, strokeWidth: strokeWidth,
                                    strokeColor: strokeColor, fillColor: fillColor,
                                    cornerRadius: cornerRadius, fontSize: fontSize,
                                    autoResize: autoResize, autoFitText: autoFitText,
                                    textColor: textColor, fontFamily: fontFamily,
                                    bold: bold, italic: italic, alignment: alignment
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
                        border.color: delBubbleMa.containsMouse ? "#662222" : "transparent"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        
                        Image {
                            source: "image://icons/trash.svg"
                            width: 12; height: 12
                            anchors.centerIn: parent
                            opacity: delBubbleMa.containsMouse ? 1.0 : 0.6
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        
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
                        border.color: delShpMa.containsMouse ? "#662222" : "transparent"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        
                        Image {
                            source: "image://icons/trash.svg"
                            width: 12; height: 12
                            anchors.centerIn: parent
                            opacity: delShpMa.containsMouse ? 1.0 : 0.6
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        
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
