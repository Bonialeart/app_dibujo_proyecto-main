import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ArtFlow 1.0

Popup {
    id: root
    
    property var canvasItem: null
    // Array plano [x,y, x,y...]
    property var currentPoints: canvasItem ? canvasItem.pressureCurvePoints : [0,0, 1,1]
    
    modal: true // Mejor modal true para evitar confusiones de foco, aunque pidiste false antes. Volvamos a false si prefieres, pero true es más estable para diálogos complejos. Mantendré FALSE como pediste.
    dim: false
    focus: true
    width: 850
    height: 550
    anchors.centerIn: parent
    


    background: Rectangle {
        color: "#1e1e1e"
        border.color: "#333"
        radius: 12
        // Sombra suave real
        layer.enabled: true
    }
    
    // --- Header ---
    Rectangle {
        id: header
        width: parent.width; height: 50
        color: "transparent"
        border.width: 0
        
        Text {
            text: "Editor de Curva de Presión"
            color: "#e0e0e0"
            font.pixelSize: 18
            font.weight: Font.Medium
            anchors.centerIn: parent
        }
        
        Button {
            text: "✕"
            width: 40; height: 40
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 10
            background: Rectangle { color: "transparent"; radius: 20 }
            contentItem: Text { text: "✕"; color: "white"; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: root.close()
        }
    }
    
    RowLayout {
        anchors.fill: parent; anchors.topMargin: 60; anchors.bottomMargin: 20; anchors.leftMargin: 20; anchors.rightMargin: 20
        spacing: 20
        
        // --- EDITOR (Izquierda) ---
        Rectangle {
            Layout.fillHeight: true; Layout.preferredWidth: 450
            color: "#151515"
            border.color: "#333"
            radius: 8
            clip: true
            
            // Grid Background
            Canvas {
                id: bgCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    var w = width; var h = height
                    ctx.clearRect(0, 0, w, h)
                    
                    // Grid principal
                    ctx.strokeStyle = "#252525"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    for(var i=1; i<4; i++) {
                        ctx.moveTo(w*i/4, 0); ctx.lineTo(w*i/4, h);
                        ctx.moveTo(0, h*i/4); ctx.lineTo(w, h*i/4);
                    }
                    ctx.stroke()
                    
                    // Eje diagonal de referencia (lineal)
                    ctx.strokeStyle = "#333"
                    ctx.setLineDash([5, 5])
                    ctx.beginPath(); ctx.moveTo(0, h); ctx.lineTo(w, 0); ctx.stroke();
                    ctx.setLineDash([])
                }
            }

            // Curve Line
            Canvas {
                id: editorCanvas
                anchors.fill: parent
                // Renderizar cuando cambien los puntos
                onPaint: {
                    var ctx = getContext("2d")
                    var w = width; var h = height
                    ctx.clearRect(0, 0, w, h)
    
                    var rawPts = root._visualPoints
                    if (!rawPts || rawPts.length < 2) return

                    // Parse & Sort
                    var pts = []
                    for(var i=0; i<rawPts.length; i+=2) {
                        pts.push({x: rawPts[i], y: rawPts[i+1]})
                    }
                    pts.sort(function(a,b){ return a.x - b.x })
                    var n = pts.length
                    if (n < 2) return

                    // Calculate Tangents (Monotone Cubic Hermite)
                    var d = []
                    var m = []
                    for(var i=0; i<n-1; i++) {
                        var dx = pts[i+1].x - pts[i].x
                        var dy = pts[i+1].y - pts[i].y
                        d[i] = (dx < 0.0001) ? 0 : dy/dx
                    }
                    if (n > 0) {
                        m[0] = d[0]
                        m[n-1] = d[n-2]
                        for(var i=1; i<n-1; i++) {
                            if (d[i-1]*d[i] <= 0) m[i] = 0
                            else m[i] = (d[i-1] + d[i]) * 0.5
                        }
                    }

                    // Helper Eval
                    function evalS(x) {
                        if (x <= pts[0].x) return pts[0].y
                        if (x >= pts[n-1].x) return pts[n-1].y
                        
                        // Find segment
                        var i = 0
                        for(var k=0; k<n-1; k++) {
                            if (x >= pts[k].x && x <= pts[k+1].x) { i=k; break }
                        }
                        
                        var h_val = pts[i+1].x - pts[i].x
                        if (h_val < 0.0001) return pts[i].y
                        
                        var t = (x - pts[i].x) / h_val
                        var t2 = t*t
                        var t3 = t2*t
                        var h00 = 2*t3 - 3*t2 + 1
                        var h10 = t3 - 2*t2 + t
                        var h01 = -2*t3 + 3*t2
                        var h11 = t3 - t2
                        return h00*pts[i].y + h10*h_val*m[i] + h01*pts[i+1].y + h11*h_val*m[i+1]
                    }

                    // Draw Smooth Curve
                    ctx.strokeStyle = "#00d4aa"
                    ctx.lineWidth = 3
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    
                    var startVal = evalS(0)
                    ctx.moveTo(0, h - (startVal*h))
                    
                    // Draw segments
                    var step = 2 // px resolution
                    for(var px=step; px<=w; px+=step) {
                        var t = px / w
                        var val = evalS(t)
                        val = Math.max(0, Math.min(1, val)) // Clamp
                        ctx.lineTo(px, h - (val*h))
                    }
                    // Ensure last point
                    var endVal = Math.max(0, Math.min(1, evalS(1)))
                    ctx.lineTo(w, h - (endVal*h))
                    
                    ctx.stroke()
                    
                    // Fill gradient
                    var grad = ctx.createLinearGradient(0, 0, 0, h)
                    grad.addColorStop(0, "rgba(0, 212, 170, 0.2)")
                    grad.addColorStop(1, "rgba(0, 212, 170, 0.0)")
                    ctx.fillStyle = grad
                    ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath(); ctx.fill()
                }
            }
            
            // Área de Interacción Global (Crear puntos)
            MouseArea {
                anchors.fill: parent
                // Solo doble click para crear
                onDoubleClicked: (mouse) => {
                    var nx = mouse.x / width
                    var ny = 1.0 - (mouse.y / height)
                    addPoint(nx, ny)
                }
            }
            
            // Handles (Puntos de control)
            Repeater {
                model: (root._visualPoints.length / 2)
                
                Item {
                    id: handle
                    width: 20; height: 20
                    // Centrar el handle
                    x: (root._visualPoints[index*2] * parent.width) - width/2
                    y: ((1.0 - root._visualPoints[index*2+1]) * parent.height) - height/2
                    
                    // El círculo visual
                    Rectangle {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        radius: 6
                        color: "#1e1e1e"
                        border.color: handleMA.pressed ? "#ffffff" : "#00d4aa"
                        border.width: 2
                        
                        Rectangle {
                            anchors.centerIn: parent; width: 16; height: 16; radius: 8
                            color: "transparent"; border.color: "#00d4aa"; border.width: 1; opacity: 0.3
                            visible: handleMA.containsMouse
                        }
                    }
                    
                    MouseArea {
                        id: handleMA
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: false
                        
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                var mapped = mapToItem(parent.parent, mouse.x, mouse.y)
                                var nx = mapped.x / parent.parent.width
                                var ny = 1.0 - (mapped.y / parent.parent.height)
                                updatePointJs(index, nx, ny, false) // No ordenar durante drag visual
                            }
                        }
                        
                        onReleased: {
                            sortPoints() // Ordenar y limpiar al soltar
                            savePoints()
                        }
                        
                        // Click derecho borrar
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                if (index > 0 && index < (root._visualPoints.length/2 - 1)) {
                                     removePoint(index)
                                }
                            }
                        }
                    }
                }
            }
            
            // Texto ayuda
            Text {
                text: "Doble clic: Añadir punto | Arrastrar: Mover | Clic derecho: Borrar"
                color: "#666"
                font.pixelSize: 11
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 8
            }
        }
        
        // --- TEST AREA (Derecha) ---
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 12
            
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: "#121214"
                radius: 8
                border.color: "#333"
                clip: true
                
                Item {
                    id: testCanvas
                    anchors.fill: parent
                    function setCurvePoints(pts) {}
                    function clear() {}
                }
                
                Button {
                     text: "Limpiar"
                     anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 10
                     background: Rectangle { color: "#333"; radius: 4 }
                     contentItem: Text { text: "Limpiar"; color: "white"; font.pixelSize: 12; anchors.centerIn: parent }
                     width: 60; height: 24
                     onClicked: testCanvas.clear()
                }
            }
            
            RowLayout {
                spacing: 10
                Button {
                    text: "Restablecer"
                    Layout.fillWidth: true
                    background: Rectangle { color: "#333"; radius: 4 }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: {
                        var def = [0.0, 0.0, 1.0, 1.0]
                        root._visualPoints = def
                        savePoints()
                    }
                }
                Button {
                    text: "Guardar"
                    Layout.fillWidth: true
                    background: Rectangle { color: "#00d4aa"; radius: 4 }
                    contentItem: Text { text: parent.text; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: root.close()
                }
            }
        }
    }
    
    // Propiedad local puramente para visualización UI (Rápida y síncrona)
    property var _visualPoints: [0,0, 1,1]
    
    // Al abrir, copiamos del backend a local
    onOpened: {
        if (canvasItem && canvasItem.pressureCurvePoints) {
            var backendPts = canvasItem.pressureCurvePoints
            var copy = []
            for(var i=0; i<backendPts.length; i++) copy.push(backendPts[i])
            _visualPoints = copy
        }
        editorCanvas.requestPaint()
    }
    
    // Cuando cambia LOCAL (por interacción usuario) -> Actualizamos Backend y Canvas
    on_VisualPointsChanged: {
        editorCanvas.requestPaint()
        
        // Sincronizar con backend de forma segura
        if (canvasItem) canvasItem.setCurvePoints(_visualPoints)
        if (testCanvas) testCanvas.setCurvePoints(_visualPoints)
    }

    // --- LÓGICA JS ---

    function addPoint(x, y) {
        var pts = clonePoints()
        pts.push(x); pts.push(y);
        _visualPoints = sortPointsArray(pts)
        savePoints()
    }
    
    function removePoint(idx) {
        var pts = []
        var curr = _visualPoints
        var targetIndex = idx * 2
        for(var i=0; i<curr.length; i+=2) {
             if (i !== targetIndex) {
                 pts.push(curr[i])
                 pts.push(curr[i+1])
             }
        }
        _visualPoints = pts
        savePoints()
    }

    function savePoints() {
        // Guardar en persistencia (C++)
        if (typeof preferencesManager !== "undefined") {
            preferencesManager.pressureCurve = _visualPoints
        }
    }
    
    function updatePointJs(idx, x, y, doSort) {
        var pts = clonePoints()
        
        // Clamp
        x = Math.max(0, Math.min(1, x))
        y = Math.max(0, Math.min(1, y))
        
        // Lock endpoints X
        if (idx === 0) x = 0;
        if (idx === (pts.length/2 - 1)) x = 1.0;
        
        pts[idx*2] = x
        pts[idx*2+1] = y
        
        if (doSort) {
            _visualPoints = sortPointsArray(pts)
        } else {
            _visualPoints = pts // Asignación directa provoca update de UI
        }
    }
    
    // Helpers
    function clonePoints() {
        var pts = []
        var curr = _visualPoints
        for(var i=0; i<curr.length; i++) pts.push(curr[i])
        return pts
    }
    
    function sortPointsArray(pts) {
        var pairs = []
        for(var i=0; i<pts.length; i+=2) pairs.push({x: pts[i], y: pts[i+1]})
        pairs.sort(function(a,b){ return a.x - b.x })
        var newPts = []
        for(var i=0; i<pairs.length; i++) { newPts.push(pairs[i].x); newPts.push(pairs[i].y); }
        return newPts
    }
}
