#include "../include/undo_manager.h"

namespace artflow {

UndoManager::UndoManager(int maxLevels) : m_maxLevels(maxLevels) {}

UndoManager::~UndoManager() { clear(); }

void UndoManager::pushCommand(std::unique_ptr<UndoCommand> command) {
  if (!command)
    return;

  m_undoStack.push_back(std::move(command));
  m_redoStack.clear(); // New action invalidates redo stack

  // Keep within limits
  if (m_undoStack.size() > static_cast<size_t>(m_maxLevels)) {
    m_undoStack.erase(m_undoStack.begin());
  }
}

void UndoManager::undo() {
  if (!canUndo())
    return;

  auto command = std::move(m_undoStack.back());
  m_undoStack.pop_back();

  command->undo();
  m_redoStack.push_back(std::move(command));
}

void UndoManager::redo() {
  if (!canRedo())
    return;

  auto command = std::move(m_redoStack.back());
  m_redoStack.pop_back();

  command->redo();
  m_undoStack.push_back(std::move(command));
}

bool UndoManager::canUndo() const { return !m_undoStack.empty(); }

bool UndoManager::canRedo() const { return !m_redoStack.empty(); }

void UndoManager::clear() {
  m_undoStack.clear();
  m_redoStack.clear();
}

void UndoManager::setMaxLevels(int levels) {
  m_maxLevels = levels;
  while (m_undoStack.size() > static_cast<size_t>(m_maxLevels)) {
    m_undoStack.erase(m_undoStack.begin());
  }
}

} // namespace artflow
