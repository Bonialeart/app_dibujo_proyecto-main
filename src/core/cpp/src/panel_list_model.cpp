#include "panel_list_model.h"

namespace artflow {

PanelListModel::PanelListModel(QObject *parent) : QAbstractListModel(parent) {}

int PanelListModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid())
    return 0;
  return m_panels.size();
}

QVariant PanelListModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() < 0 || index.row() >= m_panels.size())
    return {};

  const auto &p = m_panels[index.row()];
  switch (role) {
  case PanelIdRole:
    return p.panelId;
  case NameRole:
    return p.name;
  case IconRole:
    return p.icon;
  case SourceRole:
    return p.source;
  case VisibleRole:
    return p.visible;
  case GroupIdRole:
    return p.groupId;
  case XRole:
    return p.x;
  case YRole:
    return p.y;
  }
  return {};
}

bool PanelListModel::setData(const QModelIndex &index, const QVariant &value,
                             int role) {
  if (!index.isValid() || index.row() < 0 || index.row() >= m_panels.size())
    return false;

  auto &p = m_panels[index.row()];
  switch (role) {
  case VisibleRole:
    p.visible = value.toBool();
    break;
  case GroupIdRole:
    p.groupId = value.toString();
    break;
  case XRole:
    p.x = value.toReal();
    break;
  case YRole:
    p.y = value.toReal();
    break;
  default:
    return false;
  }

  emit dataChanged(index, index, {role});
  return true;
}

QHash<int, QByteArray> PanelListModel::roleNames() const {
  return {
      {PanelIdRole, "panelId"},
      {NameRole, "name"},
      {IconRole, "icon"},
      {SourceRole, "source"},
      {VisibleRole, "visible"},
      {GroupIdRole, "groupId"},
      {XRole, "x"},
      {YRole, "y"},
  };
}

Qt::ItemFlags PanelListModel::flags(const QModelIndex &index) const {
  if (!index.isValid())
    return Qt::NoItemFlags;
  return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

// --- Manipulation API ---

void PanelListModel::appendPanel(const PanelInfo &info) {
  int row = m_panels.size();
  beginInsertRows(QModelIndex(), row, row);
  m_panels.append(info);
  endInsertRows();
  emitCountChanged();
}

void PanelListModel::removeAt(int index) {
  if (index < 0 || index >= m_panels.size())
    return;
  beginRemoveRows(QModelIndex(), index, index);
  m_panels.removeAt(index);
  endRemoveRows();
  emitCountChanged();
}

void PanelListModel::insertAt(int index, const PanelInfo &info) {
  if (index < 0)
    index = 0;
  if (index > m_panels.size())
    index = m_panels.size();
  beginInsertRows(QModelIndex(), index, index);
  m_panels.insert(index, info);
  endInsertRows();
  emitCountChanged();
}

void PanelListModel::clear() {
  if (m_panels.isEmpty())
    return;
  beginResetModel();
  m_panels.clear();
  endResetModel();
  emitCountChanged();
}

PanelInfo PanelListModel::panelAt(int index) const {
  if (index < 0 || index >= m_panels.size())
    return {};
  return m_panels[index];
}

int PanelListModel::count() const { return m_panels.size(); }

int PanelListModel::findById(const QString &panelId) const {
  for (int i = 0; i < m_panels.size(); ++i) {
    if (m_panels[i].panelId == panelId)
      return i;
  }
  return -1;
}

bool PanelListModel::hasAnyVisible() const {
  for (const auto &p : m_panels) {
    if (p.visible)
      return true;
  }
  return false;
}

void PanelListModel::setAllVisible(bool visible) {
  for (int i = 0; i < m_panels.size(); ++i) {
    if (m_panels[i].visible != visible) {
      m_panels[i].visible = visible;
      auto idx = index(i);
      emit dataChanged(idx, idx, {VisibleRole});
    }
  }
}

void PanelListModel::setVisible(int idx, bool visible) {
  if (idx < 0 || idx >= m_panels.size())
    return;
  if (m_panels[idx].visible == visible)
    return;
  m_panels[idx].visible = visible;
  auto mi = index(idx);
  emit dataChanged(mi, mi, {VisibleRole});
}

void PanelListModel::setGroupId(int idx, const QString &groupId) {
  if (idx < 0 || idx >= m_panels.size())
    return;
  if (m_panels[idx].groupId == groupId)
    return;
  m_panels[idx].groupId = groupId;
  auto mi = index(idx);
  emit dataChanged(mi, mi, {GroupIdRole});
}

// --- QML ListModel compatibility ---

QVariantMap PanelListModel::get(int idx) const {
  QVariantMap map;
  if (idx < 0 || idx >= m_panels.size())
    return map;

  const auto &p = m_panels[idx];
  map["panelId"] = p.panelId;
  map["name"] = p.name;
  map["icon"] = p.icon;
  map["source"] = p.source;
  map["visible"] = p.visible;
  map["groupId"] = p.groupId;
  map["x"] = p.x;
  map["y"] = p.y;
  return map;
}

void PanelListModel::setProperty(int idx, const QString &property,
                                 const QVariant &value) {
  if (idx < 0 || idx >= m_panels.size())
    return;

  auto &p = m_panels[idx];
  int role = -1;

  if (property == QStringLiteral("visible")) {
    p.visible = value.toBool();
    role = VisibleRole;
  } else if (property == QStringLiteral("groupId")) {
    p.groupId = value.toString();
    role = GroupIdRole;
  } else if (property == QStringLiteral("x")) {
    p.x = value.toReal();
    role = XRole;
  } else if (property == QStringLiteral("y")) {
    p.y = value.toReal();
    role = YRole;
  }

  if (role >= 0) {
    auto mi = index(idx);
    emit dataChanged(mi, mi, {role});
  }
}

void PanelListModel::emitCountChanged() { emit countChanged(); }

} // namespace artflow
