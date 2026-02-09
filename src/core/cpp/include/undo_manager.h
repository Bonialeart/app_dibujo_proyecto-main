#pragma once
#include "undo_command.h"
#include <memory>
#include <vector>


namespace artflow {

/**
 * UndoManager - Manages the undo and redo stacks
 */
class UndoManager {
public:
  UndoManager(int maxLevels = 50);
  ~UndoManager();

  // Add a new command to the undo stack
  void pushCommand(std::unique_ptr<UndoCommand> command);

  // Perform undo/redo
  void undo();
  void redo();

  // State checks
  bool canUndo() const;
  bool canRedo() const;

  // Clear stacks
  void clear();

  // Settings
  void setMaxLevels(int levels);
  int maxLevels() const { return m_maxLevels; }

private:
  int m_maxLevels;
  std::vector<std::unique_ptr<UndoCommand>> m_undoStack;
  std::vector<std::unique_ptr<UndoCommand>> m_redoStack;
};

} // namespace artflow
