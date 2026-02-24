#ifndef PANEL_DATA_H
#define PANEL_DATA_H

#include <QString>

namespace artflow {

/**
 * PanelInfo - Describes a single UI panel (brushes, layers, color, etc.)
 */
struct PanelInfo {
    QString panelId;
    QString name;
    QString icon;
    QString source;  // QML component file name
    bool visible = false;
    QString groupId; // Empty = independent panel, non-empty = grouped/tabbed
    qreal x = 0;     // For floating panels
    qreal y = 0;     // For floating panels
};

} // namespace artflow

#endif // PANEL_DATA_H
