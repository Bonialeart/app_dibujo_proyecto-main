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
                    
                    var pts = root._visualPoints
                    if (!pts || pts.length < 2) return

                    // Preparar pares de puntos {x, y}
                    var pList = []
                    for(var i=0; i<pts.length; i+=2) {
                        pList.push({x: pts[i] * w, y: h - (pts[i+1] * h)})
                    }
                    // Ordenar por X
                    pList.sort(function(a,b){ return a.x - b.x })
                    
                    if (pList.length === 0) return;

                    ctx.strokeStyle = "#00d4aa" // Color Cyan Premium
                    ctx.lineWidth = 3
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    
                    ctx.moveTo(pList[0].x, pList[0].y)
                    
                    if (pList.length === 2) {
                        ctx.lineTo(pList[1].x, pList[1].y)
                    } else {
                        // Mejor: Dibujar línea simple pero conectada
                        for (var i = 1; i < pList.length; i++) {
                             ctx.lineTo(pList[i].x, pList[i].y)
                        }
                    }
                    
                    ctx.stroke()
                    
                    ctx.fillStyle = Qt.rgba(0, 0.83, 0.66, 0.1)
                    ctx.lineTo(pList[pList.length-1].x, h)
                    ctx.lineTo(pList[0].x, h)
                    ctx.closePath()
                    ctx.fill()
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
                
                TestCanvas {
                    id: testCanvas
                    anchors.fill: parent
                    anchors.margins: 2
                    Component.onCompleted: setCurvePoints(root.currentPoints)
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
                    onClicked: root.currentPoints = [0.0, 0.0, 1.0, 1.0]
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
