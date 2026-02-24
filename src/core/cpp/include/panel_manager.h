#ifndef PANEL_MANAGER_H
#define PANEL_MANAGER_H

#include "panel_data.h"
#include "panel_list_model.h"
#include <QMap>
#include <QObject>
#include <QString>

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
  QVariantMap activeGroupTabs() const;

  // --- Q_INVOKABLE methods called from QML ---

  // Load a predefined workspace layout
  Q_INVOKABLE void loadWorkspace(const QString &name);

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

signals:
  void dockStateChanged();
  void workspaceChanged();
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

  // Set collapsed state by dock name
  void setDockCollapsedByName(const QString &dock, bool state);

  // Create the standard panel definitions
  static PanelInfo makePanel(const QString &id, const QString &name,
                             const QString &icon, const QString &source);

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
  QMap<QString, QString> m_activeGroupTabs;
};

} // namespace artflow

#endif // PANEL_MANAGER_H
