#ifndef DRAG_ZONE_CALCULATOR_H
#define DRAG_ZONE_CALCULATOR_H

#include "panel_list_model.h"
#include <QObject>
#include <QVariantMap>

namespace artflow {

/**
 * DragZoneCalculator - Performs the heavy per-frame drag calculations in C++.
 *
 * Replaces the JavaScript updateDragZones() and calculateHoverIndex() from
 * StudioCanvasLayout.qml. These functions were running loops on every mouse
 * move event during panel drag & drop, causing UI thread stalls.
 *
 * Usage from QML:
 *   var result = dragCalculator.calculateHoverIndex(localY, dockHeight, model)
 *   var zone   = dragCalculator.computeDragZone(gx, layoutWidth, leftBarW, ...)
 */
class DragZoneCalculator : public QObject {
  Q_OBJECT

public:
  explicit DragZoneCalculator(QObject *parent = nullptr);

  /**
   * calculateHoverIndex - Computes insertion/group index for a dock.
   *
   * @param localY         Mouse Y relative to the dock container
   * @param dockHeight     Total height of the dock container
   * @param model          The PanelListModel for this dock
   * @param insertZonePx   Size of the thin insertion zone at top/bottom
   * (default 15px)
   *
   * @return QVariantMap with keys:
   *   - "index"      (int)    Visual index for insertion
   *   - "mode"       (string) "insert" or "group"
   *   - "modelIndex" (int)    Actual model index of the target panel
   */
  Q_INVOKABLE QVariantMap calculateHoverIndex(qreal localY, qreal dockHeight,
                                              PanelListModel *model,
                                              int insertZonePx = 15) const;

  /**
   * computeDragZone - Determines which dock zone the cursor is in.
   *
   * @param gx               Global X of the cursor
   * @param layoutWidth      Total width of the studio layout
   * @param leftBarWidth     Width of the left icon bar
   * @param leftDockWidth    Width of the left dock (expanded or collapsed)
   * @param leftBar2Visible  Whether the second left icon bar is visible
   * @param leftBar2Width    Width of the second left icon bar
   * @param leftDock2Width   Width of the second left dock
   * @param rightBarWidth    Width of the right icon bar
   * @param rightDockWidth   Width of the right dock
   * @param rightBar2Visible Whether the second right icon bar is visible
   * @param rightBar2Width   Width of the second right icon bar
   * @param rightDock2Width  Width of the second right dock
   * @param leftCollapsed    Is left dock collapsed
   * @param leftCollapsed2   Is left2 dock collapsed
   * @param rightCollapsed   Is right dock collapsed
   * @param rightCollapsed2  Is right2 dock collapsed
   * @param leftExpandedW    Left dock expanded width
   * @param leftExpanded2W   Left2 dock expanded width
   * @param rightExpandedW   Right dock expanded width
   * @param rightExpanded2W  Right2 dock expanded width
   *
   * @return QVariantMap with keys:
   *   - "dock" (string)  "left", "left2", "right", "right2", or "" if none
   *   Returns empty map if cursor is in the center (no dock zone).
   */
  Q_INVOKABLE QVariantMap computeDragZone(
      qreal gx, qreal layoutWidth, qreal leftBarWidth, qreal leftDockWidth,
      bool leftBar2Visible, qreal leftBar2Width, qreal leftDock2Width,
      qreal rightBarWidth, qreal rightDockWidth, bool rightBar2Visible,
      qreal rightBar2Width, qreal rightDock2Width, bool leftCollapsed,
      bool leftCollapsed2, bool rightCollapsed, bool rightCollapsed2,
      qreal leftExpandedW, qreal leftExpanded2W, qreal rightExpandedW,
      qreal rightExpanded2W) const;
};

} // namespace artflow

#endif // DRAG_ZONE_CALCULATOR_H
