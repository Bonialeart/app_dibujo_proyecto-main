#ifndef PANEL_MANAGER_H
#define PANEL_MANAGER_H

#include "panel_data.h"
#include "panel_list_model.h"
#include <QMap>
#include <QObject>
#include <QString>

class QSettings;

namespace artflow {

/**
 * PanelManager - Manages workspace panel layout (dock positions, visibility,
 *                grouping, drag-and-drop reordering).
 *
 * This replaces the StudioPanelManager.qml JavaScript logic with native C++.
 * QML only needs to read the models and call Q_INVOKABLE methods.
 */
class PanelManager : public QObject {
  Q_OBJECT

  // Models exposed to QML (read-only from QML side)
  Q_PROPERTY(artflow::PanelListModel *leftDockModel READ leftDockModel CONSTANT)
  Q_PROPERTY(
      artflow::PanelListModel *leftDockModel2 READ leftDockModel2 CONSTANT)
  Q_PROPERTY(
      artflow::PanelListModel *rightDockModel READ rightDockModel CONSTANT)
  Q_PROPERTY(
      artflow::PanelListModel *rightDockModel2 READ rightDockModel2 CONSTANT)
  Q_PROPERTY(
      artflow::PanelListModel *bottomDockModel READ bottomDockModel CONSTANT)
  Q_PROPERTY(artflow::PanelListModel *floatingModel READ floatingModel CONSTANT)

  // Collapsed state for each dock
  Q_PROPERTY(bool leftCollapsed READ leftCollapsed NOTIFY dockStateChanged)
  Q_PROPERTY(bool leftCollapsed2 READ leftCollapsed2 NOTIFY dockStateChanged)
  Q_PROPERTY(bool rightCollapsed READ rightCollapsed NOTIFY dockStateChanged)
  Q_PROPERTY(bool rightCollapsed2 READ rightCollapsed2 NOTIFY dockStateChanged)
  Q_PROPERTY(bool bottomCollapsed READ bottomCollapsed NOTIFY dockStateChanged)

  // Current workspace name
  Q_PROPERTY(
      QString activeWorkspace READ activeWorkspace NOTIFY workspaceChanged)

  // Available workspaces list
  Q_PROPERTY(QStringList availableWorkspaces READ availableWorkspaces NOTIFY workspacesChanged)

  // Active group tabs (QML reads this to know which tab is selected in a group)
  Q_PROPERTY(
      QVariantMap activeGroupTabs READ activeGroupTabs NOTIFY activeTabChanged)

public:
  explicit PanelManager(QObject *parent = nullptr);

  // Model accessors
  PanelListModel *leftDockModel() const { return m_leftDock; }
  PanelListModel *leftDockModel2() const { return m_leftDock2; }
  PanelListModel *rightDockModel() const { return m_rightDock; }
  PanelListModel *rightDockModel2() const { return m_rightDock2; }
  PanelListModel *bottomDockModel() const { return m_bottomDock; }
  PanelListModel *floatingModel() const { return m_floating; }

  // Collapsed state
  bool leftCollapsed() const { return m_leftCollapsed; }
  bool leftCollapsed2() const { return m_leftCollapsed2; }
  bool rightCollapsed() const { return m_rightCollapsed; }
  bool rightCollapsed2() const { return m_rightCollapsed2; }
  bool bottomCollapsed() const { return m_bottomCollapsed; }

  QString activeWorkspace() const { return m_activeWorkspace; }
  QStringList availableWorkspaces() const;
  QVariantMap activeGroupTabs() const;

  QStringList hiddenPanels() const { return m_hiddenPanels; }

  // --- Q_INVOKABLE methods called from QML ---

  // Load a predefined or custom workspace layout
  Q_INVOKABLE void loadWorkspace(const QString &name);

  // Register current layout as a new custom workspace
  Q_INVOKABLE void registerWorkspace(const QString &name);

  // Delete a custom workspace
  Q_INVOKABLE void deleteWorkspace(const QString &name);

  // Reset the current workspace to its default layout
  Q_INVOKABLE void resetCurrentWorkspace();

  // Reload the current workspace to its last saved layout
  Q_INVOKABLE void reloadCurrentWorkspace();

  // Toggle panel visibility (smart: opens dock if closed, switches tab, etc.)
  Q_INVOKABLE void togglePanel(const QString &panelId);

  // Collapse an entire dock side
  Q_INVOKABLE void collapseDock(const QString &dockSide);

  // Reorder a panel within its dock
  Q_INVOKABLE void reorderPanel(const QString &dockSide, int sourceIdx,
                                int targetIdx, const QString &mode);

  // Move a panel from any dock to a target dock
  Q_INVOKABLE void movePanel(const QString &panelId, const QString &targetDock,
                             int targetIndex = -1,
                             const QString &mode = "insert");

  // Move a panel to floating mode at a given position
  Q_INVOKABLE void movePanelToFloat(const QString &panelId, qreal x, qreal y);

  // Set active tab within a group
  Q_INVOKABLE void setActiveTab(const QString &groupId, const QString &panelId);

  // Set collapsed state by dock name directly from QML (e.g. via drag to
  // expand)
  Q_INVOKABLE void setDockCollapsedByName(const QString &dock, bool state);

  // Remove a panel from every dock (used by Ventana menu's "remove" action).
  // The panel is added to the hiddenPanels list so the Ventana menu won't
  // show it again. Auto-saves.
  Q_INVOKABLE void removePanelEverywhere(const QString &panelId);

  // Restore a previously hidden panel: removes it from hiddenPanels and
  // re-adds it to the right dock of the current workspace.
  Q_INVOKABLE void restorePanel(const QString &panelId);

  // All currently hidden panel ids (Ventana menu filter).
  Q_PROPERTY(QStringList hiddenPanels READ hiddenPanels NOTIFY hiddenPanelsChanged)

  // --- Helpers exposed to QML ---
  Q_INVOKABLE void clearHiddenPanels();
  Q_INVOKABLE bool isPanelHidden(const QString &panelId) const;
  Q_INVOKABLE void addHiddenPanel(const QString &panelId);

signals:
  void hiddenPanelsChanged();
  void dockStateChanged();
  void workspaceChanged();
  void workspacesChanged();
  void activeTabChanged();

private:
  // Find which model contains a panelId
  PanelListModel *findPanelModel(const QString &panelId) const;

  // Find model by dock side name
  PanelListModel *findDockModel(const QString &side) const;

  // Update collapsed states based on visibility
  void cleanDocks();

  // Set visibility for a panel (and optionally its group)
  void setDockVisibility(PanelListModel *model, const QString &panelId,
                         const QString &groupId, bool state);

  // Get collapsed state for a given model
  bool getDockCollapsed(PanelListModel *model) const;

  // Create the standard panel definitions
  static PanelInfo makePanel(const QString &id, const QString &name,
                             const QString &icon, const QString &source);

  // Auto-save the current layout state
  void autoSave();

  // Load a saved layout by group name, returns true if successful
  bool loadLayoutHelper(const QString &groupName, QSettings &settings);

  // Catalog of standard panels
  QMap<QString, PanelInfo> createCatalog() const;

  // --- Data ---
  PanelListModel *m_leftDock;
  PanelListModel *m_leftDock2;
  PanelListModel *m_rightDock;
  PanelListModel *m_rightDock2;
  PanelListModel *m_bottomDock;
  PanelListModel *m_floating;

  bool m_leftCollapsed = true;
  bool m_leftCollapsed2 = true;
  bool m_rightCollapsed = true;
  bool m_rightCollapsed2 = true;
  bool m_bottomCollapsed = true;

  QString m_activeWorkspace;
  QStringList m_customWorkspaces;
  QMap<QString, QString> m_activeGroupTabs;
  QStringList m_hiddenPanels;
};

} // namespace artflow

#endif // PANEL_MANAGER_H
