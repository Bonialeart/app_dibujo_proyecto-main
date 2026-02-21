#include "../include/stroke_undo_command.h"

namespace artflow {

StrokeUndoCommand::StrokeUndoCommand(LayerManager *manager, int layerIndex,
                                     std::unique_ptr<ImageBuffer> before,
                                     std::unique_ptr<ImageBuffer> after)
    : m_manager(manager), m_layerIndex(layerIndex), m_before(std::move(before)),
      m_after(std::move(after)) {}

void StrokeUndoCommand::undo() {
  Layer *layer = m_manager->getLayer(m_layerIndex);
  if (layer && m_before) {
    layer->buffer->copyFrom(*m_before);
    layer->dirty = true;
  }
}

void StrokeUndoCommand::redo() {
  Layer *layer = m_manager->getLayer(m_layerIndex);
  if (layer && m_after) {
    layer->buffer->copyFrom(*m_after);
    layer->dirty = true;
  }
}

} // namespace artflow
