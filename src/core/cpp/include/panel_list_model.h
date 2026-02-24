#ifndef PANEL_LIST_MODEL_H
#define PANEL_LIST_MODEL_H

#include "panel_data.h"
#include <QAbstractListModel>
#include <QVector>

namespace artflow {

/**
 * PanelListModel - QAbstractListModel exposing a list of PanelInfo to QML.
 * Replaces the QML ListModel that was doing all the logic in JavaScript.
 */
class PanelListModel : public QAbstractListModel {
  Q_OBJECT
  Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
  enum Roles {
    PanelIdRole = Qt::UserRole + 1,
    NameRole,
    IconRole,
    SourceRole,
    VisibleRole,
    GroupIdRole,
    XRole,
    YRole
  };

  explicit PanelListModel(QObject *parent = nullptr);

  // QAbstractListModel interface
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role) const override;
  bool setData(const QModelIndex &index, const QVariant &value,
               int role) override;
  QHash<int, QByteArray> roleNames() const override;
  Qt::ItemFlags flags(const QModelIndex &index) const override;

  // --- QML ListModel compatibility ---
  // These methods make QAbstractListModel behave like QML ListModel
  // so that existing QML code using model.get(i).panelId still works.
  Q_INVOKABLE QVariantMap get(int index) const;
  Q_INVOKABLE void setProperty(int index, const QString &property,
                               const QVariant &value);

  // --- C++ API used by PanelManager ---
  void appendPanel(const PanelInfo &info);
  void removeAt(int index);
  void insertAt(int index, const PanelInfo &info);
  void clear();
  PanelInfo panelAt(int index) const;
  int count() const;

  // Find panel index by id, returns -1 if not found
  int findById(const QString &panelId) const;

  // Visibility helpers
  bool hasAnyVisible() const;
  void setAllVisible(bool visible);
  void setVisible(int index, bool visible);
  void setGroupId(int index, const QString &groupId);

signals:
  void countChanged();

private:
  void emitCountChanged();
  QVector<PanelInfo> m_panels;
};

} // namespace artflow

#endif // PANEL_LIST_MODEL_H
