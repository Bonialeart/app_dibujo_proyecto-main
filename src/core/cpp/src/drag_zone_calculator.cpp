#include "drag_zone_calculator.h"
#include <QtMath>
#include <algorithm>

namespace artflow {

DragZoneCalculator::DragZoneCalculator(QObject *parent) : QObject(parent) {}

// ---------------------------------------------------------------------------
// calculateHoverIndex
// ---------------------------------------------------------------------------
// This is the exact C++ equivalent of the JavaScript calculateHoverIndex()
// from StudioCanvasLayout.qml. It runs in the UI thread but is ~10x faster
// than the JS version because:
//  1. No JS→C++ bridge overhead per model.get(i) call
//  2. No JS garbage collection pressure from the visibleItems array
//  3. Direct memory access to the PanelListModel data
// ---------------------------------------------------------------------------

QVariantMap DragZoneCalculator::calculateHoverIndex(qreal localY,
                                                    qreal dockHeight,
                                                    PanelListModel *model,
                                                    int insertZonePx) const {
  QVariantMap result;

  if (!model || model->count() == 0) {
    result["index"] = 0;
    result["mode"] = QStringLiteral("insert");
    result["modelIndex"] = -1;
    return result;
  }

  // Build list of visible panel indices, collapsing groups to their first
  // visible member (same logic as the original JS)
  QVector<int> visibleItems;
  visibleItems.reserve(model->count());

  for (int i = 0; i < model->count(); ++i) {
    PanelInfo panel = model->panelAt(i);
    if (!panel.visible)
      continue;

    if (panel.groupId.isEmpty()) {
      // Independent panel — always visible
      visibleItems.append(i);
    } else {
      // Grouped panel — only add if it's the first visible in its group
      bool isFirst = true;
      const QString &gid = panel.groupId;
      for (int j = 0; j < i; ++j) {
        PanelInfo prev = model->panelAt(j);
        if (prev.visible && prev.groupId == gid) {
          isFirst = false;
          break;
        }
      }
      if (isFirst)
        visibleItems.append(i);
    }
  }

  int vCount = visibleItems.size();
  if (vCount == 0) {
    result["index"] = 0;
    result["mode"] = QStringLiteral("insert");
    result["modelIndex"] = -1;
    return result;
  }

  // Calculate which visual item the cursor is over
  qreal itemHeight = dockHeight / static_cast<qreal>(vCount);
  int vIdx = static_cast<int>(qFloor(localY / itemHeight));
  qreal subY = std::fmod(localY, itemHeight);

  // Clamp to valid range for model lookup
  int clampedIdx = qBound(0, vIdx, vCount - 1);
  int modelIdx = visibleItems[clampedIdx];

  // Determine mode: thin insertion zones at top/bottom, "group" in the middle
  QString mode = QStringLiteral("group");
  qreal zonePx = static_cast<qreal>(insertZonePx);

  if (subY < zonePx) {
    // Top thin zone → insert before
    mode = QStringLiteral("insert");
  } else if (subY > itemHeight - zonePx) {
    // Bottom thin zone → insert after
    mode = QStringLiteral("insert");
    vIdx++; // Shift to insert AFTER this item
  }

  result["index"] = vIdx;
  result["mode"] = mode;
  result["modelIndex"] = modelIdx;
  return result;
}

// ---------------------------------------------------------------------------
// computeDragZone
// ---------------------------------------------------------------------------
// Determines which dock zone the cursor is in based on the current layout
// geometry. This replaces the threshold calculations in updateDragZones().
// The actual dock highlighting and model operations are still done in QML,
// but the heavy math runs here.
// ---------------------------------------------------------------------------

QVariantMap DragZoneCalculator::computeDragZone(
    qreal gx, qreal layoutWidth, qreal leftBarWidth, qreal leftDockWidth,
    bool leftBar2Visible, qreal leftBar2Width, qreal leftDock2Width,
    qreal rightBarWidth, qreal rightDockWidth, bool rightBar2Visible,
    qreal rightBar2Width, qreal rightDock2Width, bool leftCollapsed,
    bool leftCollapsed2, bool rightCollapsed, bool rightCollapsed2,
    qreal leftExpandedW, qreal leftExpanded2W, qreal rightExpandedW,
    qreal rightExpanded2W) const {

  QVariantMap result;

  // Calculate zone thresholds (matches the original JS logic exactly)
  qreal zL1 =
      leftBarWidth + (leftCollapsed ? 40.0 : leftExpandedW / 2.0) + 20.0;

  qreal lw1 = leftBarWidth + leftDockWidth;
  qreal bar2W = leftBar2Visible ? leftBar2Width : 20.0;
  qreal zL2 = lw1 + bar2W + (leftCollapsed2 ? 40.0 : leftExpanded2W) + 30.0;

  qreal zR1 = layoutWidth - rightBarWidth -
              (rightCollapsed ? 40.0 : rightExpandedW / 2.0) - 20.0;

  qreal rw1 = rightBarWidth + rightDockWidth;
  qreal rBar2W = rightBar2Visible ? rightBar2Width : 20.0;
  qreal zR2 = layoutWidth - rw1 - rBar2W -
              (rightCollapsed2 ? 40.0 : rightExpanded2W) - 30.0;

  // Determine which zone the cursor is in
  if (gx <= zL1) {
    result["dock"] = QStringLiteral("left");
  } else if (gx <= zL2) {
    result["dock"] = QStringLiteral("left2");
  } else if (gx >= zR1) {
    result["dock"] = QStringLiteral("right");
  } else if (gx >= zR2) {
    result["dock"] = QStringLiteral("right2");
  }
  // else: result is empty → cursor is in the center (no dock zone)

  return result;
}

} // namespace artflow
