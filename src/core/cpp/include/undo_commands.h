#pragma once

#include "undo_command.h"
#include "layer_manager.h"
#include <QPainterPath>
#include <QVariant>
#include <memory>
#include <string>
#include <functional>

namespace artflow {

enum class LayerProperty {
  Opacity,
  BlendMode,
  Visible,
  Locked,
  AlphaLock,
  Clipped,
  Reference,
  Name
};

/**
 * LayerAddUndoCommand - Handles undo/redo for adding, duplicating, or grouping layers
 */
class LayerAddUndoCommand : public UndoCommand {
public:
  LayerAddUndoCommand(LayerManager *manager, int index, std::unique_ptr<Layer> layer,
                      int activeBefore, int activeAfter);

  void undo() override;
  void redo() override;
  std::string name() const override { return "Add Layer"; }

private:
  LayerManager *m_manager;
  int m_index;
  std::unique_ptr<Layer> m_layer;
  int m_activeBefore;
  int m_activeAfter;
  bool m_hasLayer;
};

/**
 * LayerRemoveUndoCommand - Handles undo/redo for removing a layer
 */
class LayerRemoveUndoCommand : public UndoCommand {
public:
  LayerRemoveUndoCommand(LayerManager *manager, int index, std::unique_ptr<Layer> layer,
                         int activeBefore, int activeAfter);

  void undo() override;
  void redo() override;
  std::string name() const override { return "Remove Layer"; }

private:
  LayerManager *m_manager;
  int m_index;
  std::unique_ptr<Layer> m_layer;
  int m_activeBefore;
  int m_activeAfter;
  bool m_hasLayer;
};

/**
 * LayerMoveUndoCommand - Handles undo/redo for reordering layers (and updating parentId/clipped)
 */
class LayerMoveUndoCommand : public UndoCommand {
public:
  LayerMoveUndoCommand(LayerManager *manager, int fromIndex, int toIndex,
                       int parentIdBefore, int parentIdAfter,
                       bool clippedBefore, bool clippedAfter,
                       int activeBefore, int activeAfter);

  void undo() override;
  void redo() override;
  std::string name() const override { return "Move Layer"; }

private:
  LayerManager *m_manager;
  int m_fromIndex;
  int m_toIndex;
  int m_parentIdBefore;
  int m_parentIdAfter;
  bool m_clippedBefore;
  bool m_clippedAfter;
  int m_activeBefore;
  int m_activeAfter;
};

/**
 * LayerPropertyUndoCommand - Handles undo/redo for metadata property updates
 */
class LayerPropertyUndoCommand : public UndoCommand {
public:
  LayerPropertyUndoCommand(LayerManager *manager, uint32_t layerStableId,
                           LayerProperty property, const QVariant &before, const QVariant &after);

  void undo() override;
  void redo() override;
  std::string name() const override;

private:
  LayerManager *m_manager;
  uint32_t m_layerStableId;
  LayerProperty m_property;
  QVariant m_before;
  QVariant m_after;

  void applyProperty(Layer *layer, const QVariant &value);
};

/**
 * LayerMergeUndoCommand - Handles undo/redo for merging down layers
 */
class LayerMergeUndoCommand : public UndoCommand {
public:
  LayerMergeUndoCommand(LayerManager *manager, int topIndex, std::unique_ptr<Layer> topLayer,
                        int bottomIndex, std::unique_ptr<ImageBuffer> bottomBefore,
                        std::unique_ptr<ImageBuffer> bottomAfter,
                        int activeBefore, int activeAfter);

  void undo() override;
  void redo() override;
  std::string name() const override { return "Merge Layers"; }

private:
  LayerManager *m_manager;
  int m_topIndex;
  std::unique_ptr<Layer> m_topLayer;
  int m_bottomIndex;
  std::unique_ptr<ImageBuffer> m_bottomBefore;
  std::unique_ptr<ImageBuffer> m_bottomAfter;
  int m_activeBefore;
  int m_activeAfter;
  bool m_hasTopLayer;
};

/**
 * SelectionUndoCommand - Handles undo/redo for selections
 */
class SelectionUndoCommand : public UndoCommand {
public:
  SelectionUndoCommand(std::function<void(const QPainterPath&, bool)> callback,
                       const QPainterPath &beforePath, bool beforeHasSelection,
                       const QPainterPath &afterPath, bool afterHasSelection);

  void undo() override;
  void redo() override;
  std::string name() const override { return "Selection Change"; }

private:
  std::function<void(const QPainterPath&, bool)> m_callback;
  QPainterPath m_beforePath;
  bool m_beforeHasSelection;
  QPainterPath m_afterPath;
  bool m_afterHasSelection;
};

} // namespace artflow
