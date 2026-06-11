#include "panel_manager.h"
#include <QDebug>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>

namespace artflow {

PanelManager::PanelManager(QObject *parent)
    : QObject(parent), m_leftDock(new PanelListModel(this)),
      m_leftDock2(new PanelListModel(this)),
      m_rightDock(new PanelListModel(this)),
      m_rightDock2(new PanelListModel(this)),
      m_bottomDock(new PanelListModel(this)),
      m_floating(new PanelListModel(this)) {
  
  QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
  QDir().mkpath(dataPath);
  QSettings settings(dataPath + "/workspaces.ini", QSettings::IniFormat);

  m_customWorkspaces = settings.value("General/customWorkspaces").toStringList();
  m_hiddenPanels = settings.value("General/hiddenPanels").toStringList();
  QString activeWs = settings.value("General/activeWorkspace", QStringLiteral("Ilustración")).toString();
  m_activeWorkspace = activeWs;

  // Try to load the current session. If it doesn't exist, fall back to loading the active workspace
  if (!loadLayoutHelper("__CurrentSession__", settings)) {
      loadWorkspace(activeWs);
  }
}

QVariantMap PanelManager::activeGroupTabs() const {
  QVariantMap map;
  for (auto it = m_activeGroupTabs.cbegin(); it != m_activeGroupTabs.cend();
       ++it) {
    map[it.key()] = it.value();
  }
  return map;
}

QStringList PanelManager::availableWorkspaces() const {
  QStringList list;
  list << QStringLiteral("Ilustración")
       << QStringLiteral("Manga/Comic")
       << QStringLiteral("Animación");
  list.append(m_customWorkspaces);
  return list;
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

QMap<QString, PanelInfo> PanelManager::createCatalog() const {
  QMap<QString, PanelInfo> catalog;
  catalog["brushes"] = makePanel("brushes", "Brushes", "brush.svg", "BrushLibraryPanel.qml");
  catalog["settings"] = makePanel("settings", "Ajuste de herramienta", "sliders.svg", "BrushSettingsPanel.qml");
  catalog["color"] = makePanel("color", "Color", "palette.svg", "ColorPanel.qml");
  catalog["layers"] = makePanel("layers", "Layers", "layers.svg", "LayerPanel.qml");
  catalog["navigator"] = makePanel("navigator", "Navigator", "compass.svg", "NavigatorPanel.qml");
  catalog["history"] = makePanel("history", "History", "undo.svg", "HistoryPanel.qml");
  catalog["info"] = makePanel("info", "Info", "info.svg", "InfoPanel.qml");
  catalog["reference"] = makePanel("reference", "Reference", "image.svg", "ReferencePanel.qml");
  catalog["timeline"] = makePanel("timeline", "Timeline", "video.svg", "TimelinePanel.qml");
  catalog["colorhistory"] = makePanel("colorhistory", "Color History", "colorhistory.svg", "ColorHistoryPanel.qml");
  return catalog;
}

// --- Workspace Loading ---

void PanelManager::loadWorkspace(const QString &name) {
  m_activeWorkspace = name;

  QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
  QDir().mkpath(dataPath);
  QSettings settings(dataPath + "/workspaces.ini", QSettings::IniFormat);

  // Check if there is a saved layout for this workspace name
  if (loadLayoutHelper("Workspace_" + name, settings)) {
      emit workspaceChanged();
      autoSave();
      return;
  }

  m_leftDock->clear();
  m_leftDock2->clear();
  m_rightDock->clear();
  m_rightDock2->clear();
  m_bottomDock->clear();
  m_floating->clear();
  m_activeGroupTabs.clear();

  // Predefined panel catalog
  auto catalog = createCatalog();
  auto pBrushes = catalog["brushes"];
  auto pSettings = catalog["settings"];
  auto pColor = catalog["color"];
  auto pLayers = catalog["layers"];
  auto pNavigator = catalog["navigator"];
  auto pHistory = catalog["history"];
  auto pInfo = catalog["info"];
  auto pReference = catalog["reference"];
  auto pTimeline = catalog["timeline"];

  if (name == QStringLiteral("Manga/Comic")) {
    // Manga workspace
    pBrushes.visible = true;
    m_leftDock->appendPanel(pBrushes);
    m_leftDock->appendPanel(pSettings);

    pLayers.visible = true;
    m_rightDock->appendPanel(pLayers);
    m_rightDock->appendPanel(pNavigator);
    m_rightDock->appendPanel(pHistory);

    pColor.visible = true;
    pColor.x = 200;
    pColor.y = 100;
    m_floating->appendPanel(pColor);
    m_floating->appendPanel(pReference);

    m_rightDock->appendPanel(pInfo);
    m_bottomDock->appendPanel(pTimeline);

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
    m_rightDock->appendPanel(pHistory);
    m_rightDock->appendPanel(pInfo);

    pTimeline.visible = true;
    m_bottomDock->appendPanel(pTimeline);

  } else {
    // Default "Ilustración" workspace
    pBrushes.visible = true;
    m_leftDock->appendPanel(pBrushes);
    m_leftDock->appendPanel(pSettings);

    pColor.visible = true;
    m_rightDock->appendPanel(pColor);
    pLayers.visible = true;
    m_rightDock->appendPanel(pLayers);
    m_rightDock->appendPanel(pNavigator);
    m_rightDock->appendPanel(pHistory);
    m_rightDock->appendPanel(pReference);

    m_rightDock->appendPanel(pInfo);
    m_bottomDock->appendPanel(pTimeline);
  }

  cleanDocks();
  emit workspaceChanged();
  emit activeTabChanged();

  autoSave();
}

// --- Workspace Registration & Management ---

void PanelManager::registerWorkspace(const QString &name) {
  if (name.isEmpty()) return;

  // Predefined default ones cannot be overwritten/registered again
  if (name == QStringLiteral("Ilustración") || name == QStringLiteral("Manga/Comic") || name == QStringLiteral("Animación")) {
    return;
  }

  if (!m_customWorkspaces.contains(name)) {
    m_customWorkspaces.append(name);
    emit workspacesChanged();
  }

  m_activeWorkspace = name;
  emit workspaceChanged();

  autoSave();
}

void PanelManager::deleteWorkspace(const QString &name) {
  if (name.isEmpty() || !m_customWorkspaces.contains(name)) return;

  m_customWorkspaces.removeAll(name);
  emit workspacesChanged();

  QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
  QSettings settings(dataPath + "/workspaces.ini", QSettings::IniFormat);
  settings.beginGroup("Workspace_" + name);
  settings.remove("");
  settings.endGroup();

  if (m_activeWorkspace == name) {
    loadWorkspace(QStringLiteral("Ilustración"));
  } else {
    autoSave();
  }
}

void PanelManager::resetCurrentWorkspace() {
  QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
  QSettings settings(dataPath + "/workspaces.ini", QSettings::IniFormat);
  settings.beginGroup("Workspace_" + m_activeWorkspace);
  settings.remove("");
  settings.endGroup();

  loadWorkspace(m_activeWorkspace);
}

void PanelManager::reloadCurrentWorkspace() {
  loadWorkspace(m_activeWorkspace);
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
  autoSave();
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
  autoSave();
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
  autoSave();
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
  autoSave();
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
  autoSave();
}

// --- Active Tab ---

void PanelManager::setActiveTab(const QString &groupId,
                                const QString &panelId) {
  if (groupId.isEmpty())
    return;
  m_activeGroupTabs[groupId] = panelId;
  emit activeTabChanged();
  autoSave();
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
  autoSave();
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

// --- Layout Serialization Helpers ---

void PanelManager::autoSave() {
  QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
  QDir().mkpath(dataPath);
  QSettings settings(dataPath + "/workspaces.ini", QSettings::IniFormat);

  settings.setValue("General/activeWorkspace", m_activeWorkspace);
  settings.setValue("General/customWorkspaces", m_customWorkspaces);
  settings.setValue("General/hiddenPanels", m_hiddenPanels);

  auto saveLayoutHelper = [&](const QString &groupName) {
    settings.beginGroup(groupName);

    auto saveDock = [&](const QString &dockName, PanelListModel *model) {
      QStringList list;
      for (int i = 0; i < model->count(); ++i) {
        list << model->panelAt(i).panelId;
      }
      settings.setValue(dockName, list);
    };

    saveDock("leftDock", m_leftDock);
    saveDock("leftDock2", m_leftDock2);
    saveDock("rightDock", m_rightDock);
    saveDock("rightDock2", m_rightDock2);
    saveDock("bottomDock", m_bottomDock);
    saveDock("floatingModel", m_floating);

    settings.setValue("leftCollapsed", m_leftCollapsed);
    settings.setValue("leftCollapsed2", m_leftCollapsed2);
    settings.setValue("rightCollapsed", m_rightCollapsed);
    settings.setValue("rightCollapsed2", m_rightCollapsed2);
    settings.setValue("bottomCollapsed", m_bottomCollapsed);

    settings.beginGroup("ActiveTabs");
    settings.remove("");
    for (auto it = m_activeGroupTabs.cbegin(); it != m_activeGroupTabs.cend(); ++it) {
      settings.setValue(it.key(), it.value());
    }
    settings.endGroup();

    settings.beginGroup("Panels");
    settings.remove("");
    auto savePanelProps = [&](PanelListModel *model) {
      for (int i = 0; i < model->count(); ++i) {
        PanelInfo p = model->panelAt(i);
        settings.beginGroup(p.panelId);
        settings.setValue("visible", p.visible);
        settings.setValue("groupId", p.groupId);
        settings.setValue("x", p.x);
        settings.setValue("y", p.y);
        settings.endGroup();
      }
    };

    savePanelProps(m_leftDock);
    savePanelProps(m_leftDock2);
    savePanelProps(m_rightDock);
    savePanelProps(m_rightDock2);
    savePanelProps(m_bottomDock);
    savePanelProps(m_floating);

    settings.endGroup(); // Panels
    settings.endGroup(); // groupName
  };

  saveLayoutHelper("__CurrentSession__");
  saveLayoutHelper("Workspace_" + m_activeWorkspace);
}

bool PanelManager::loadLayoutHelper(const QString &groupName, QSettings &settings) {
  if (!settings.childGroups().contains(groupName)) {
    return false;
  }

  settings.beginGroup(groupName);

  QStringList leftList = settings.value("leftDock").toStringList();
  QStringList leftList2 = settings.value("leftDock2").toStringList();
  QStringList rightList = settings.value("rightDock").toStringList();
  QStringList rightList2 = settings.value("rightDock2").toStringList();
  QStringList bottomList = settings.value("bottomDock").toStringList();
  QStringList floatingList = settings.value("floatingModel").toStringList();

  if (leftList.isEmpty() && leftList2.isEmpty() && rightList.isEmpty() && 
      rightList2.isEmpty() && bottomList.isEmpty() && floatingList.isEmpty()) {
    settings.endGroup();
    return false;
  }

  m_leftDock->clear();
  m_leftDock2->clear();
  m_rightDock->clear();
  m_rightDock2->clear();
  m_bottomDock->clear();
  m_floating->clear();
  m_activeGroupTabs.clear();

  m_leftCollapsed = settings.value("leftCollapsed", true).toBool();
  m_leftCollapsed2 = settings.value("leftCollapsed2", true).toBool();
  m_rightCollapsed = settings.value("rightCollapsed", true).toBool();
  m_rightCollapsed2 = settings.value("rightCollapsed2", true).toBool();
  m_bottomCollapsed = settings.value("bottomCollapsed", true).toBool();

  settings.beginGroup("ActiveTabs");
  QStringList keys = settings.allKeys();
  for (const QString &key : keys) {
    m_activeGroupTabs[key] = settings.value(key).toString();
  }
  settings.endGroup();

  QMap<QString, PanelInfo> catalog = createCatalog();

  auto loadDock = [&](const QStringList &panelIds, PanelListModel *model) {
    settings.beginGroup("Panels");
    for (const QString &panelId : panelIds) {
      if (!catalog.contains(panelId)) continue;
      // Skip redundant / legacy panels that have been merged into the unified settings panel
      if (panelId == "toolsettings" || panelId == "gradient" || panelId == "transform") continue;
      PanelInfo p = catalog[panelId];
      settings.beginGroup(panelId);
      p.visible = settings.value("visible", p.visible).toBool();
      p.groupId = settings.value("groupId", p.groupId).toString();
      p.x = settings.value("x", p.x).toReal();
      p.y = settings.value("y", p.y).toReal();
      settings.endGroup();
      model->appendPanel(p);
    }
    settings.endGroup();
  };

  loadDock(leftList, m_leftDock);
  loadDock(leftList2, m_leftDock2);
  loadDock(rightList, m_rightDock);
  loadDock(rightList2, m_rightDock2);
  loadDock(bottomList, m_bottomDock);
  loadDock(floatingList, m_floating);

  settings.endGroup(); // groupName

  // Handle missing or newly introduced catalog panels, appending them as invisible to floating model
  QMap<QString, PanelInfo> catalogLeft = catalog;
  auto removeFound = [&](PanelListModel *model) {
    for (int i = 0; i < model->count(); ++i) {
      catalogLeft.remove(model->panelAt(i).panelId);
    }
  };
  removeFound(m_leftDock);
  removeFound(m_leftDock2);
  removeFound(m_rightDock);
  removeFound(m_rightDock2);
  removeFound(m_bottomDock);
  removeFound(m_floating);

  for (auto it = catalogLeft.begin(); it != catalogLeft.end(); ++it) {
    PanelInfo p = it.value();
    p.visible = false;
    m_floating->appendPanel(p);
  }

  cleanDocks();
  emit dockStateChanged();
  emit activeTabChanged();
  return true;
}

// --- Panel Removal & Hidden List ---

void PanelManager::removePanelEverywhere(const QString &panelId) {
  bool removed = false;
  if (m_leftDock)   removed |= m_leftDock->removeById(panelId);
  if (m_leftDock2)  removed |= m_leftDock2->removeById(panelId);
  if (m_rightDock)  removed |= m_rightDock->removeById(panelId);
  if (m_rightDock2) removed |= m_rightDock2->removeById(panelId);
  if (m_bottomDock) removed |= m_bottomDock->removeById(panelId);
  if (m_floating)   removed |= m_floating->removeById(panelId);
  if (removed) {
    addHiddenPanel(panelId);
    cleanDocks();
    autoSave();
  }
}

void PanelManager::restorePanel(const QString &panelId) {
  // Remove from hidden list
  m_hiddenPanels.removeAll(panelId);
  emit hiddenPanelsChanged();

  // Look up the panel info in the catalog and re-add to a default dock
  // based on the current workspace layout. For simplicity we always
  // restore to the right dock (most common location for tool panels).
  auto catalog = createCatalog();
  if (!catalog.contains(panelId)) return;
  PanelInfo p = catalog[panelId];
  p.visible = true;

  if (m_activeWorkspace == QStringLiteral("Manga/Comic")) {
    if (panelId == "color" || panelId == "reference") {
      p.x = 200; p.y = 100;
      m_floating->appendPanel(p);
    } else {
      m_rightDock->appendPanel(p);
    }
  } else {
    m_rightDock->appendPanel(p);
  }

  cleanDocks();
  autoSave();
}

void PanelManager::addHiddenPanel(const QString &panelId) {
  if (panelId.isEmpty()) return;
  if (!m_hiddenPanels.contains(panelId)) {
    m_hiddenPanels.append(panelId);
    emit hiddenPanelsChanged();
    autoSave();
  }
}

void PanelManager::clearHiddenPanels() {
  if (m_hiddenPanels.isEmpty()) return;
  m_hiddenPanels.clear();
  emit hiddenPanelsChanged();
  autoSave();
}

bool PanelManager::isPanelHidden(const QString &panelId) const {
  return m_hiddenPanels.contains(panelId);
}

} // namespace artflow
