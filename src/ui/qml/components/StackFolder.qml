import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth: 160; implicitHeight: 220
    
    property var thumbnails: [] 
    property string title: "Grupo"
    property bool isExpanded: false 

    readonly property var _thumbList: {
        if (!thumbnails) return []
        var arr = []
        var c = 0
        try {
            c = (thumbnails.count !== undefined) ? thumbnails.count : thumbnails.length
        } catch(e) { }
        
        if (!c || c <= 0) return []
        
        for (var i = 0; i < Math.min(c, 3); i++) {
            var item = null
            try {
                item = (thumbnails.get) ? thumbnails.get(i) : thumbnails[i]
            } catch(e) { }
            
            if (item === undefined || item === null) continue
            
            if (typeof item === "string") {
                if (item) arr.push(item)
            } else if (typeof item === "object") {
                // If it's a ListModel item wrapping a string from Python
                var path = item.modelData || item.display || item.value || ""
                if (!path && item.toString) {
                    var s = item.toString()
                    if (s.indexOf("file://") !== -1) path = s
                }
                if (path) arr.push(path)
            }
        }
        return arr
    }

    // 4. CONTENIDO DINÁMICO
    // Si está vacío, mostramos un icono de Carpeta elegante
    Item {
        anchors.centerIn: parent
        width: 130; height: 130
        visible: root._thumbList.length === 0
        
        Rectangle {
            anchors.fill: parent; radius: 24
            color: "#1c1c1e"; border.color: "#333"; border.width: 1
            Text { text: "📁"; font.pixelSize: 60; anchors.centerIn: parent; opacity: 0.5 }
        }
    }

    // Si tiene contenido, mostramos la pila (adaptativa)
    Repeater {
        model: Math.min(3, Math.max(1, root._thumbList.length))
        
        delegate: Item {
            id: cardWrapper
            width: 130; height: 130
            anchors.centerIn: parent
            z: 100 - index 
            visible: root._thumbList.length > 0

            // EFECTO DE PILA VISIBLE (Solo si hay > 1)
            rotation: {
                if (root._thumbList.length <= 1) return 0
                if (index === 0) return 0
                if (index === 1) return -7
                return 7
            }
            
            x: (root.isExpanded && root._thumbList.length > 1) ? (index === 1 ? -45 : 45) : 0
            y: (root.isExpanded && root._thumbList.length > 1) ? (index * 15) : 0

            Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "white" 
                border.color: "#ddd"
                border.width: 1
                clip: true
                
                Image {
                    anchors.fill: parent
                    anchors.margins: 4
                    source: (root._thumbList && root._thumbList.length > index) ? root._thumbList[index] : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    mipmap: true
                }
            }

            layer.enabled: true
            layer.samples: 8 // CALIDAD ULTRA: 8x Antialiasing para bordes perfectos
            layer.smooth: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowBlur: 0.6
                shadowColor: "black"; shadowOpacity: 0.3
                shadowVerticalOffset: 2 + index
            }
        }
    }

    Text {
        anchors.top: parent.bottom; anchors.topMargin: 15
        width: parent.width; horizontalAlignment: Text.AlignHCenter
        text: root.title; color: "#f0f0f5"; font.bold: true; font.pixelSize: 13; opacity: 0.8
    }
}
