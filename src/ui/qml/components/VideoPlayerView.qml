import QtQuick
import QtQuick.Controls

// ═════════════════════════════════════════════════════════════════
//  VIDEO PLAYER VIEW — Placeholder while WebEngine for MinGW
//  is not available. Shows YouTube thumbnail + open button.
//  NOTE: QtWebEngineQuick is only available for MSVC build of Qt.
//  To enable in-app video: install Qt WebEngine for mingw_64.
// ═════════════════════════════════════════════════════════════════
Item {
    id: playerRoot

    // This file is intentionally minimal.
    // The full player fallback is handled directly in LearnCenterPage.qml
    property string videoUrl: ""

    // Signal that this "player" is actually not a real player
    // so LearnCenterPage knows to show fallback
    Component.onCompleted: {
        // Force the Loader to show as error so fallback is shown
        // by making this component immediately destroy itself
        // Actually we just let it be visible=false so fallback shows
    }
    visible: false
}
