#include "panel_manager.h"
#include <QDebug>

namespace artflow {

PanelManager::PanelManager(QObject *parent)
    : QObject(parent), m_leftDock(new PanelListModel(this)),
      m_leftDock2(new PanelListModel(this)),
      m_rightDock(new PanelListModel(this)),
      m_rightDock2(new PanelListModel(this)),
      m_bottomDock(new PanelListModel(this)),
      m_floating(new PanelListModel(this)) {
  loadWorkspace(QStringLiteral("Ilustración"));
}

QVariantMap PanelManager::activeGroupTabs() const {
  QVariantMap map;
  for (auto it = m_activeGroupTabs.cbegin(); it != m_activeGroupTabs.cend();
       ++it) {
    map[it.key()] = it.value();
  }
  return map;
}

// --- Factory helper ---

PanelInfo PanelManager::makePanel(const QString &id, const QString &name,
                                  const QString &icon, const QString &source) {
  PanelInfo p;
  p.panelId = id;
  p.name = name;
  p.icon = icon;
  p.source = source;
  p.visible = false;
  return p;
}

// --- Workspace Loading ---

void PanelManager::loadWorkspace(const QString &name) {
  m_activeWorkspace = name;

  m_leftDock->clear();
  m_leftDock2->clear();
  m_rightDock->clear();
  m_rightDock2->clear();
  m_bottomDock->clear();
  m_floating->clear();
  m_activeGroupTabs.clear();

  // Predefined panel catalog
  auto pBrushes =
      makePanel("brushes", "Brushes", "brush.svg", "BrushLibraryPanel.qml");
  auto pSettings = makePanel("settings", "StudioConfig", "sliders.svg",
                             "BrushSettingsPanel.qml");
  auto pColor = makePanel("color", "Color", "palette.svg", "ColorPanel.qml");
  auto pLayers = makePanel("layers", "Layers", "layers.svg", "LayerPanel.qml");
  auto pNavigator =
      makePanel("navigator", "Navigator", "compass.svg", "NavigatorPanel.qml");
  auto pHistory =
      makePanel("history", "History", "undo.svg", "HistoryPanel.qml");
  auto pInfo = makePanel("info", "Info", "sliders.svg", "InfoPanel.qml");
  auto pToolSettings = makePanel("toolsettings", "Tool Settings", "tool.svg",
                                 "ToolSettingsPanel.qml");
  auto pReference =
      makePanel("reference", "Reference", "image.svg", "ReferencePanel.qml");
  auto pTimeline =
      makePanel("timeline", "Timeline", "video.svg", "TimelinePanel.qml");

  if (name == QStringLiteral("Manga/Comic")) {
    // Manga workspace
    pBrushes.visible = true;
    m_leftDock->appendPanel(pBrushes);
    m_leftDock->appendPanel(pSettings);
    m_leftDock->appendPanel(pToolSettings);

    pLayers.visible = true;
    m_rightDock->appendPanel(pLayers);
    m_rightDock->appendPanel(pNavigator);
    m_rightDock->appendPanel(pHistory);

    pColor.visible = true;
    pColor.x = 200;
    pColor.y = 100;
    m_floating->appendPanel(pColor);
    m_floating->appendPanel(pReference);

  } else if (name == QStringLiteral("Animación")) {
    // Animation workspace
    pBrushes.visible = true;
    m_leftDock->appendPanel(pBrushes);
    m_leftDock->appendPanel(pSettings);

    pLayers.visible = true;
    m_rightDock->appendPanel(pLayers);
    pColor.visible = true;
    m_rightDock->appendPanel(pColor);
    m_rightDock->appendPanel(pNavigator);
    m_rightDock->appendPanel(pReference);

    pTimeline.visible = true;
    m_bottomDock->appendPanel(pTimeline);

  } else {
    // Default "Ilustración" workspace
    pBrushes.visible = true;
    m_leftDock->appendPanel(pBrushes);
    m_leftDock->appendPanel(pSettings);
    m_leftDock->appendPanel(pToolSettings);

    pColor.visible = true;
    m_rightDock->appendPanel(pColor);
    pLayers.visible = true;
    m_rightDock->appendPanel(pLayers);
    m_rightDock->appendPanel(pNavigator);
    m_rightDock->appendPanel(pHistory);
    m_rightDock->appendPanel(pReference);
  }

  cleanDocks();
  emit workspaceChanged();
  emit activeTabChanged();
}

// --- Panel Toggle ---

void PanelManager::togglePanel(const QString &panelId) {
  PanelListModel *model = findPanelModel(panelId);
  if (!model || model == m_floating)
    return;

  int idx = model->findById(panelId);
  if (idx < 0)
    return;

  PanelInfo panel = model->panelAt(idx);
  bool currentlyVisible = panel.visible;
  QString groupId = panel.groupId;
  bool isDockClosed = getDockCollapsed(model);

  if (isDockClosed) {
    // Case 1: Dock is closed → open it with this panel
    if (!groupId.isEmpty())
      setActiveTab(groupId, panelId);
    setDockVisibility(model, panelId, groupId, true);
  } else {
    if (!groupId.isEmpty()) {
      QString currentTab = m_activeGroupTabs.value(groupId);
      if (currentlyVisible && currentTab != panelId) {
        // Case 2: Switch to another tab in the same group
        setActiveTab(groupId, panelId);
      } else {
        // Case 3: Toggle current tab's group
        setDockVisibility(model, panelId, groupId, !currentlyVisible);
      }
    } else {
      // Case 4: Independent panel toggle
      setDockVisibility(model, panelId, QString(), !currentlyVisible);
    }
  }

  if (!groupId.isEmpty()) {
    if (!m_activeGroupTabs.contains(groupId))
      setActiveTab(groupId, panelId);
  }

  cleanDocks();
}

// --- Dock Visibility ---

void PanelManager::setDockVisibility(PanelListModel *model,
                                     const QString &panelId,
                                     const QString &groupId, bool state) {
  if (state) {
    // Hide all others to prevent stacking (unless in the same group)
    model->setAllVisible(false);
  }

  for (int i = 0; i < model->count(); ++i) {
    PanelInfo p = model->panelAt(i);
    if (p.panelId == panelId || (!groupId.isEmpty() && p.groupId == groupId)) {
      model->setVisible(i, state);
    }
  }
}

void PanelManager::collapseDock(const QString &dockSide) {
  PanelListModel *m = findDockModel(dockSide);
  if (!m)
    return;
  m->setAllVisible(false);
  cleanDocks();
}

// --- Reorder ---

void PanelManager::reorderPanel(const QString &dockSide, int sourceIdx,
                                int targetIdx, const QString &mode) {
  PanelListModel *m = findDockModel(dockSide);
  if (!m || sourceIdx < 0 || targetIdx < 0 || sourceIdx >= m->count() ||
      targetIdx >= m->count())
    return;

  PanelInfo src = m->panelAt(sourceIdx);
  PanelInfo tgt = m->panelAt(targetIdx);

  PanelInfo clone = src;

  if (mode == QStringLiteral("group")) {
    QString gId = tgt.groupId.isEmpty() ? (QStringLiteral("grp_") + tgt.panelId)
                                        : tgt.groupId;
    m->setGroupId(targetIdx, gId);
    clone.groupId = gId;

    m->removeAt(sourceIdx);
    int adjTgt = (sourceIdx < targetIdx) ? (targetIdx - 1) : targetIdx;
    m->insertAt(adjTgt + 1, clone);
    setActiveTab(gId, clone.panelId);
  } else {
    clone.groupId.clear();
    m->removeAt(sourceIdx);
    int adjTgt = (sourceIdx < targetIdx) ? (targetIdx - 1) : targetIdx;
    if (mode == QStringLiteral("before"))
      m->insertAt(adjTgt, clone);
    else
      m->insertAt(adjTgt + 1, clone);
  }

  cleanDocks();
}

// --- Move Panel Between Docks ---

void PanelManager::movePanel(const QString &panelId, const QString &targetDock,
                             int targetIndex, const QString &mode) {
  PanelListModel *sourceModel = findPanelModel(panelId);
  if (!sourceModel)
    return;

  int srcIdx = sourceModel->findById(panelId);
  if (srcIdx < 0)
    return;

  PanelInfo panel = sourceModel->panelAt(srcIdx);
  panel.visible = true;
  sourceModel->removeAt(srcIdx);

  PanelListModel *destModel = findDockModel(targetDock);
  if (!destModel) {
    // Put it back if target is invalid
    sourceModel->appendPanel(panel);
    return;
  }

  if (mode == QStringLiteral("group") && targetIndex >= 0 &&
      targetIndex < destModel->count()) {
    PanelInfo tgt = destModel->panelAt(targetIndex);
    QString gId = tgt.groupId.isEmpty() ? (QStringLiteral("grp_") + tgt.panelId)
                                        : tgt.groupId;

    destModel->setGroupId(targetIndex, gId);
    panel.groupId = gId;
    destModel->insertAt(targetIndex + 1, panel);
    setActiveTab(gId, panel.panelId);
  } else {
    panel.groupId.clear();
    if (targetIndex >= 0 && targetIndex <= destModel->count())
      destModel->insertAt(targetIndex, panel);
    else
      destModel->appendPanel(panel);
  }

  setDockCollapsedByName(targetDock, false);
  cleanDocks();
}

// --- Float ---

void PanelManager::movePanelToFloat(const QString &panelId, qreal x, qreal y) {
  PanelListModel *sourceModel = findPanelModel(panelId);
  if (!sourceModel)
    return;

  int srcIdx = sourceModel->findById(panelId);
  if (srcIdx < 0)
    return;

  PanelInfo panel = sourceModel->panelAt(srcIdx);
  panel.visible = true;
  panel.groupId.clear();
  panel.x = x;
  panel.y = y;
  sourceModel->removeAt(srcIdx);

  m_floating->appendPanel(panel);
  cleanDocks();
}

// --- Active Tab ---

void PanelManager::setActiveTab(const QString &groupId,
                                const QString &panelId) {
  if (groupId.isEmpty())
    return;
  m_activeGroupTabs[groupId] = panelId;
  emit activeTabChanged();
}

// --- Helpers ---

PanelListModel *PanelManager::findPanelModel(const QString &panelId) const {
  PanelListModel *models[] = {m_leftDock,   m_leftDock2,  m_rightDock,
                              m_rightDock2, m_bottomDock, m_floating};
  for (auto *m : models) {
    if (m->findById(panelId) >= 0)
      return m;
  }
  return nullptr;
}

PanelListModel *PanelManager::findDockModel(const QString &side) const {
  if (side == QStringLiteral("left"))
    return m_leftDock;
  if (side == QStringLiteral("left2"))
    return m_leftDock2;
  if (side == QStringLiteral("right"))
    return m_rightDock;
  if (side == QStringLiteral("right2"))
    return m_rightDock2;
  if (side == QStringLiteral("bottom"))
    return m_bottomDock;
  return nullptr;
}

bool PanelManager::getDockCollapsed(PanelListModel *model) const {
  if (model == m_leftDock)
    return m_leftCollapsed;
  if (model == m_leftDock2)
    return m_leftCollapsed2;
  if (model == m_rightDock)
    return m_rightCollapsed;
  if (model == m_rightDock2)
    return m_rightCollapsed2;
  if (model == m_bottomDock)
    return m_bottomCollapsed;
  return true;
}

void PanelManager::setDockCollapsedByName(const QString &dock, bool state) {
  if (dock == QStringLiteral("left"))
    m_leftCollapsed = state;
  else if (dock == QStringLiteral("left2"))
    m_leftCollapsed2 = state;
  else if (dock == QStringLiteral("right"))
    m_rightCollapsed = state;
  else if (dock == QStringLiteral("right2"))
    m_rightCollapsed2 = state;
  else if (dock == QStringLiteral("bottom"))
    m_bottomCollapsed = state;
  else
    return;
  emit dockStateChanged();
}

void PanelManager::cleanDocks() {
  bool oldL = m_leftCollapsed;
  bool oldL2 = m_leftCollapsed2;
  bool oldR = m_rightCollapsed;
  bool oldR2 = m_rightCollapsed2;
  bool oldB = m_bottomCollapsed;

  m_leftCollapsed = !m_leftDock->hasAnyVisible();
  m_leftCollapsed2 = !m_leftDock2->hasAnyVisible();
  m_rightCollapsed = !m_rightDock->hasAnyVisible();
  m_rightCollapsed2 = !m_rightDock2->hasAnyVisible();
  m_bottomCollapsed = !m_bottomDock->hasAnyVisible();

  if (oldL != m_leftCollapsed || oldL2 != m_leftCollapsed2 ||
      oldR != m_rightCollapsed || oldR2 != m_rightCollapsed2 ||
      oldB != m_bottomCollapsed) {
    emit dockStateChanged();
  }
}

} // namespace artflow
