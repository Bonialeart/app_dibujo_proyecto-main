#pragma once
#include "image_buffer.h"
#include "layer_manager.h"
#include "undo_command.h"
#include <memory>


namespace artflow {

/**
 * StrokeUndoCommand - Handles undo/redo for brush strokes
 * Stores a copy of the layer buffer before and after the stroke.
 */
class StrokeUndoCommand : public UndoCommand {
public:
  StrokeUndoCommand(LayerManager *manager, int layerIndex,
                    std::unique_ptr<ImageBuffer> before,
                    std::unique_ptr<ImageBuffer> after);

  void undo() override;
  void redo() override;
  std::string name() const override { return "Brush Stroke"; }

private:
  LayerManager *m_manager;
  int m_layerIndex;
  std::unique_ptr<ImageBuffer> m_before;
  std::unique_ptr<ImageBuffer> m_after;
};

} // namespace artflow
