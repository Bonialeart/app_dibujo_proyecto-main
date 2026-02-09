import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Slider {
    id: control
    
    // Custom Properties
    property color accentColor: "#4A90E2"
    property color trackColor: "#333333"
    property color handleColor: "#ffffff"
    
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 4
        width: control.availableWidth
        height: implicitHeight
        radius: 2
        color: trackColor
        
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: accentColor
            radius: 2
        }
    }
    
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 16
        implicitHeight: 16
        radius: 8
        color: handleColor
        border.color: "#111"
        border.width: 1
        
        // Shadow for depth
        layer.enabled: true
        /* layer.effect: DropShadow {
            transparentBorder: true
            color: "#50000000"
            radius: 4
            samples: 8
        } */
    }
}
