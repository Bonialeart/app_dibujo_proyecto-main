#pragma once

#include "brush_preset.h"
#include <QDir>
#include <QJsonDocument>
#include <QString>
#include <map>
#include <memory>
#include <vector>

namespace artflow {

class BrushPresetManager {
public:
  static BrushPresetManager *instance();

  // Load all presets from a directory (JSON files)
  void loadFromDirectory(const QString &path);

  // Save a preset to a JSON file
  bool savePreset(const BrushPreset &preset, const QString &directory = "");

  // Get all groups
  const std::vector<BrushGroup> &groups() const { return m_groups; }

  // Get all presets (flat list across all groups)
  std::vector<const BrushPreset *> allPresets() const;

  // Find a preset by name (case-insensitive)
  const BrushPreset *findByName(const QString &name) const;

  // Find a preset by UUID
  const BrushPreset *findByUUID(const QString &uuid) const;

  // Get presets from a specific category
  std::vector<const BrushPreset *>
  presetsInCategory(const QString &category) const;

  // Get available brush names (for QML)
  QStringList brushNames() const;

  // Add/remove presets
  void addPreset(const BrushPreset &preset);
  void removePreset(const QString &uuid);
  bool
  updatePreset(const BrushPreset &preset); // Update existing preset by UUID
  BrushPreset duplicatePreset(const QString &uuid, const QString &newName);

  // Default presets (embedded fallback)
  void loadDefaults();

private:
  BrushPresetManager() = default;
  static BrushPresetManager *s_instance;

  std::vector<BrushGroup> m_groups;

  // Ensure a group exists, create if not
  BrushGroup &ensureGroup(const QString &name, const QString &icon = "");
};

} // namespace artflow
