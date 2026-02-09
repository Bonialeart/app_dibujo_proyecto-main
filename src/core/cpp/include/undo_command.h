#pragma once
#include <string>

namespace artflow {

/**
 * UndoCommand - Base class for all undoable actions
 */
class UndoCommand {
public:
  virtual ~UndoCommand() = default;
  virtual void undo() = 0;
  virtual void redo() = 0;
  virtual std::string name() const = 0;
};

} // namespace artflow
