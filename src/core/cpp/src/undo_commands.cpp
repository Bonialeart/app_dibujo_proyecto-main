#include "../include/undo_commands.h"

namespace artflow {

// ==================== LayerAddUndoCommand ====================

LayerAddUndoCommand::LayerAddUndoCommand(LayerManager *manager, int index,
                                         std::unique_ptr<Layer> layer,
                                         int activeBefore, int activeAfter)
    : m_manager(manager), m_index(index), m_layer(std::move(layer)),
      m_activeBefore(activeBefore), m_activeAfter(activeAfter), m_hasLayer(false) {}

void LayerAddUndoCommand::undo() {
  if (!m_hasLayer) {
    m_layer = m_manager->takeLayer(m_index);
    m_hasLayer = true;
    m_manager->setActiveLayer(m_activeBefore);
  }
}

void LayerAddUndoCommand::redo() {
  if (m_hasLayer && m_layer) {
    m_manager->insertLayer(m_index, std::move(m_layer));
    m_hasLayer = false;
    m_manager->setActiveLayer(m_activeAfter);
  }
}


// ==================== LayerRemoveUndoCommand ====================

LayerRemoveUndoCommand::LayerRemoveUndoCommand(LayerManager *manager, int index,
                                               std::unique_ptr<Layer> layer,
                                               int activeBefore, int activeAfter)
    : m_manager(manager), m_index(index), m_layer(std::move(layer)),
      m_activeBefore(activeBefore), m_activeAfter(activeAfter), m_hasLayer(true) {}

void LayerRemoveUndoCommand::undo() {
  if (m_hasLayer && m_layer) {
    m_manager->insertLayer(m_index, std::move(m_layer));
    m_hasLayer = false;
    m_manager->setActiveLayer(m_activeBefore);
  }
}

void LayerRemoveUndoCommand::redo() {
  if (!m_hasLayer) {
    m_layer = m_manager->takeLayer(m_index);
    m_hasLayer = true;
    m_manager->setActiveLayer(m_activeAfter);
  }
}


// ==================== LayerMoveUndoCommand ====================

LayerMoveUndoCommand::LayerMoveUndoCommand(LayerManager *manager, int fromIndex, int toIndex,
                                           int parentIdBefore, int parentIdAfter,
                                           bool clippedBefore, bool clippedAfter,
                                           int activeBefore, int activeAfter)
    : m_manager(manager), m_fromIndex(fromIndex), m_toIndex(toIndex),
      m_parentIdBefore(parentIdBefore), m_parentIdAfter(parentIdAfter),
      m_clippedBefore(clippedBefore), m_clippedAfter(clippedAfter),
      m_activeBefore(activeBefore), m_activeAfter(activeAfter) {}

void LayerMoveUndoCommand::undo() {
  m_manager->moveLayer(m_toIndex, m_fromIndex);
  Layer *l = m_manager->getLayer(m_fromIndex);
  if (l) {
    l->parentId = m_parentIdBefore;
    l->clipped = m_clippedBefore;
  }
  m_manager->setActiveLayer(m_activeBefore);
}

void LayerMoveUndoCommand::redo() {
  m_manager->moveLayer(m_fromIndex, m_toIndex);
  Layer *l = m_manager->getLayer(m_toIndex);
  if (l) {
    l->parentId = m_parentIdAfter;
    l->clipped = m_clippedAfter;
  }
  m_manager->setActiveLayer(m_activeAfter);
}


// ==================== LayerPropertyUndoCommand ====================

LayerPropertyUndoCommand::LayerPropertyUndoCommand(LayerManager *manager, uint32_t layerStableId,
                                                   LayerProperty property,
                                                   const QVariant &before, const QVariant &after)
    : m_manager(manager), m_layerStableId(layerStableId), m_property(property),
      m_before(before), m_after(after) {}

void LayerPropertyUndoCommand::undo() {
  Layer *layer = m_manager->getLayerByStableId(m_layerStableId);
  if (layer) {
    applyProperty(layer, m_before);
  }
}

void LayerPropertyUndoCommand::redo() {
  Layer *layer = m_manager->getLayerByStableId(m_layerStableId);
  if (layer) {
    applyProperty(layer, m_after);
  }
}

std::string LayerPropertyUndoCommand::name() const {
  switch (m_property) {
    case LayerProperty::Opacity: return "Change Layer Opacity";
    case LayerProperty::BlendMode: return "Change Layer Blend Mode";
    case LayerProperty::Visible: return "Toggle Layer Visibility";
    case LayerProperty::Locked: return "Toggle Layer Lock";
    case LayerProperty::AlphaLock: return "Toggle Layer Alpha Lock";
    case LayerProperty::Clipped: return "Toggle Layer Clipping";
    case LayerProperty::Reference: return "Toggle Layer Reference";
    case LayerProperty::Name: return "Rename Layer";
  }
  return "Modify Layer Property";
}

void LayerPropertyUndoCommand::applyProperty(Layer *layer, const QVariant &value) {
  switch (m_property) {
    case LayerProperty::Opacity:
      layer->opacity = value.toFloat();
      layer->markDirty();
      break;
    case LayerProperty::BlendMode:
      layer->blendMode = static_cast<BlendMode>(value.toInt());
      layer->markDirty();
      break;
    case LayerProperty::Visible:
      layer->visible = value.toBool();
      layer->markDirty();
      if (layer->type == Layer::Type::Group) {
        uint32_t groupStableId = layer->stableId;
        for (int i = 0; i < m_manager->getLayerCount(); ++i) {
          Layer *child = m_manager->getLayer(i);
          if (child && child->parentId == (int)groupStableId) {
            child->visible = value.toBool();
            child->markDirty();
          }
        }
      }
      break;
    case LayerProperty::Locked:
      layer->locked = value.toBool();
      break;
    case LayerProperty::AlphaLock:
      layer->alphaLock = value.toBool();
      break;
    case LayerProperty::Clipped:
      layer->clipped = value.toBool();
      layer->markDirty();
      break;
    case LayerProperty::Reference:
      layer->reference = value.toBool();
      break;
    case LayerProperty::Name:
      layer->name = value.toString().toStdString();
      break;
  }
}


// ==================== LayerMergeUndoCommand ====================

LayerMergeUndoCommand::LayerMergeUndoCommand(LayerManager *manager, int topIndex,
                                             std::unique_ptr<Layer> topLayer,
                                             int bottomIndex,
                                             std::unique_ptr<ImageBuffer> bottomBefore,
                                             std::unique_ptr<ImageBuffer> bottomAfter,
                                             int activeBefore, int activeAfter)
    : m_manager(manager), m_topIndex(topIndex), m_topLayer(std::move(topLayer)),
      m_bottomIndex(bottomIndex), m_bottomBefore(std::move(bottomBefore)),
      m_bottomAfter(std::move(bottomAfter)), m_activeBefore(activeBefore),
      m_activeAfter(activeAfter), m_hasTopLayer(true) {}

void LayerMergeUndoCommand::undo() {
  Layer *bottom = m_manager->getLayer(m_bottomIndex);
  if (bottom && m_bottomBefore) {
    bottom->buffer->copyFrom(*m_bottomBefore);
    bottom->markDirty();
  }
  if (m_hasTopLayer && m_topLayer) {
    m_manager->insertLayer(m_topIndex, std::move(m_topLayer));
    m_hasTopLayer = false;
  }
  m_manager->setActiveLayer(m_activeBefore);
}

void LayerMergeUndoCommand::redo() {
  Layer *bottom = m_manager->getLayer(m_bottomIndex);
  if (bottom && m_bottomAfter) {
    bottom->buffer->copyFrom(*m_bottomAfter);
    bottom->markDirty();
  }
  if (!m_hasTopLayer) {
    m_topLayer = m_manager->takeLayer(m_topIndex);
    m_hasTopLayer = true;
  }
  m_manager->setActiveLayer(m_activeAfter);
}


// ==================== SelectionUndoCommand ====================

SelectionUndoCommand::SelectionUndoCommand(std::function<void(const QPainterPath&, bool)> callback,
                                           const QPainterPath &beforePath, bool beforeHasSelection,
                                           const QPainterPath &afterPath, bool afterHasSelection)
    : m_callback(callback), m_beforePath(beforePath), m_beforeHasSelection(beforeHasSelection),
      m_afterPath(afterPath), m_afterHasSelection(afterHasSelection) {}

void SelectionUndoCommand::undo() {
  if (m_callback) {
    m_callback(m_beforePath, m_beforeHasSelection);
  }
}

void SelectionUndoCommand::redo() {
  if (m_callback) {
    m_callback(m_afterPath, m_afterHasSelection);
  }
}

} // namespace artflow
