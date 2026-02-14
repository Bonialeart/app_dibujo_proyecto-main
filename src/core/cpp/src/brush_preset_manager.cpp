#include "../include/brush_preset_manager.h"
#include <QCoreApplication>
#include <QDebug>
#include <QDirIterator>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <algorithm>

namespace artflow {

BrushPresetManager *BrushPresetManager::s_instance = nullptr;

BrushPresetManager *BrushPresetManager::instance() {
  if (!s_instance) {
    s_instance = new BrushPresetManager();
  }
  return s_instance;
}

void BrushPresetManager::loadFromDirectory(const QString &path) {
  QDir dir(path);
  if (!dir.exists()) {
    qDebug() << "BrushPresetManager: Directory not found:" << path;
    return;
  }

  QStringList filters;
  filters << "*.json";

  QDirIterator it(path, filters, QDir::Files, QDirIterator::Subdirectories);
  int count = 0;

  qDebug() << "BrushPresetManager: Scanning directory:" << path;
  while (it.hasNext()) {
    it.next();
    QFile file(it.filePath());
    if (!file.open(QIODevice::ReadOnly)) {
      qWarning() << "BrushPresetManager: Failed to open file:" << it.filePath();
      continue;
    }

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();

    if (doc.isNull() || !doc.isObject()) {
      qWarning() << "BrushPresetManager: Invalid JSON in:" << it.filePath();
      continue;
    }

    QJsonObject root = doc.object();

    // Check if it's a group file or a single preset
    if (root.contains("brushes")) {
      // It's a group file
      BrushGroup group = BrushGroup::fromJson(root);
      // Merge into existing group or add new
      BrushGroup &target = ensureGroup(group.name, group.icon);
      for (auto &b : group.brushes) {
        target.brushes.push_back(std::move(b));
      }
      count += group.brushes.size();
      qDebug() << "BrushPresetManager: Loaded group" << group.name << "with"
               << group.brushes.size() << "brushes from" << it.fileName();
    } else {
      // Single preset file
      BrushPreset preset = BrushPreset::fromJson(root);
      addPreset(preset);
      count++;
      qDebug() << "BrushPresetManager: Loaded preset" << preset.name << "from"
               << it.fileName();
    }
  }

  qDebug() << "BrushPresetManager: Loaded" << count << "presets from" << path;
}

bool BrushPresetManager::savePreset(const BrushPreset &preset,
                                    const QString &directory) {
  QString dir = directory;
  if (dir.isEmpty()) {
    dir = QCoreApplication::applicationDirPath() + "/brushes/user";
  }

  QDir().mkpath(dir);

  // Sanitize filename
  QString filename = preset.name;
  filename.replace(QRegularExpression("[^a-zA-Z0-9_\\-]"), "_");
  filename = filename.toLower() + ".json";

  QFile file(dir + "/" + filename);
  if (!file.open(QIODevice::WriteOnly)) {
    qDebug() << "BrushPresetManager: Cannot save to" << file.fileName();
    return false;
  }

  QJsonDocument doc(preset.toJson());
  file.write(doc.toJson(QJsonDocument::Indented));
  file.close();

  qDebug() << "BrushPresetManager: Saved" << preset.name << "to"
           << file.fileName();
  return true;
}

std::vector<const BrushPreset *> BrushPresetManager::allPresets() const {
  std::vector<const BrushPreset *> result;
  for (const auto &group : m_groups) {
    for (const auto &preset : group.brushes) {
      result.push_back(&preset);
    }
  }
  return result;
}

const BrushPreset *BrushPresetManager::findByName(const QString &name) const {
  for (const auto &group : m_groups) {
    for (const auto &preset : group.brushes) {
      if (preset.name.compare(name, Qt::CaseInsensitive) == 0) {
        return &preset;
      }
    }
  }
  return nullptr;
}

const BrushPreset *BrushPresetManager::findByUUID(const QString &uuid) const {
  for (const auto &group : m_groups) {
    for (const auto &preset : group.brushes) {
      if (preset.uuid == uuid)
        return &preset;
    }
  }
  return nullptr;
}

std::vector<const BrushPreset *>
BrushPresetManager::presetsInCategory(const QString &category) const {
  std::vector<const BrushPreset *> result;
  for (const auto &group : m_groups) {
    if (group.name.compare(category, Qt::CaseInsensitive) == 0) {
      for (const auto &preset : group.brushes) {
        result.push_back(&preset);
      }
    }
  }
  return result;
}

QStringList BrushPresetManager::brushNames() const {
  QStringList result;
  for (const auto &group : m_groups) {
    for (const auto &preset : group.brushes) {
      result.append(preset.name);
    }
  }
  return result;
}

void BrushPresetManager::addPreset(const BrushPreset &preset) {
  BrushGroup &group = ensureGroup(preset.category);
  group.brushes.push_back(preset);
}

void BrushPresetManager::removePreset(const QString &uuid) {
  for (auto &group : m_groups) {
    auto it =
        std::remove_if(group.brushes.begin(), group.brushes.end(),
                       [&](const BrushPreset &p) { return p.uuid == uuid; });
    group.brushes.erase(it, group.brushes.end());
  }
}

bool BrushPresetManager::updatePreset(const BrushPreset &preset) {
  for (auto &group : m_groups) {
    for (auto &existing : group.brushes) {
      if (existing.uuid == preset.uuid) {
        existing = preset;
        return true;
      }
    }
  }
  return false;
}

BrushPreset BrushPresetManager::duplicatePreset(const QString &uuid,
                                                const QString &newName) {
  const BrushPreset *original = findByUUID(uuid);
  if (!original) {
    return BrushPreset();
  }

  BrushPreset copy = *original;
  copy.uuid = BrushPreset::generateUUID();
  copy.name = newName.isEmpty() ? original->name + " Copy" : newName;
  addPreset(copy);
  return copy;
}

BrushGroup &BrushPresetManager::ensureGroup(const QString &name,
                                            const QString &icon) {
  for (auto &g : m_groups) {
    if (g.name.compare(name, Qt::CaseInsensitive) == 0) {
      return g;
    }
  }

  BrushGroup newGroup;
  newGroup.name = name;

  // Auto-generate icon from first two letters
  if (icon.isEmpty()) {
    QStringList words = name.split(' ', Qt::SkipEmptyParts);
    if (words.size() >= 2) {
      newGroup.icon = words[0].left(1).toUpper() + words[1].left(1).toUpper();
    } else {
      newGroup.icon = name.left(2).toUpper();
    }
  } else {
    newGroup.icon = icon;
  }

  m_groups.push_back(newGroup);
  return m_groups.back();
}

// ============================================================
// Default Presets (Fallback when no JSON files exist)
// ============================================================
void BrushPresetManager::loadDefaults() {
  // Only load defaults if no presets are already loaded
  if (!m_groups.empty())
    return;

  qDebug() << "BrushPresetManager: Loading built-in default presets...";

  // Helper lambda for convenience
  auto addBrush = [this](const QString &cat, const QString &bName, float size,
                         float opacity, float hardness, float spacing,
                         float streamline, const QString &grainTex = "",
                         float grainScale = 1.0f, float grainIntensity = 0.5f,
                         const QString &tipTex = "", float wetness = 0.0f,
                         float smudge = 0.0f, bool sizeByPressure = true,
                         bool opacityByPressure = false,
                         float velocityDyn = 0.0f, float jitter = 0.0f,
                         float flow = 1.0f, float calli = 0.0f) {
    BrushPreset p;
    p.uuid = BrushPreset::generateUUID();
    p.name = bName;
    p.category = cat;
    p.defaultSize = size;
    p.defaultOpacity = opacity;
    p.defaultHardness = hardness;
    p.defaultFlow = flow;
    p.stroke.spacing = spacing;
    p.stroke.streamline = streamline;

    if (!grainTex.isEmpty()) {
      p.grain.texture = grainTex;
      p.grain.scale = grainScale;
      p.grain.intensity = grainIntensity;
    }
    if (!tipTex.isEmpty()) {
      p.shape.tipTexture = tipTex;
    }
    p.shape.calligraphic = calli;

    p.wetMix.wetness = wetness;
    p.wetMix.pull = smudge;

    // Dynamics
    if (sizeByPressure) {
      p.sizeDynamics.baseValue = 1.0f;
      p.sizeDynamics.minLimit = 0.1f;
    } else {
      p.sizeDynamics.baseValue = 1.0f;
      p.sizeDynamics.minLimit = 1.0f; // No variation
    }

    if (opacityByPressure) {
      p.opacityDynamics.baseValue = 1.0f;
      p.opacityDynamics.minLimit = 0.0f;
    } else {
      p.opacityDynamics.baseValue = 1.0f;
      p.opacityDynamics.minLimit = 1.0f;
    }

    p.sizeDynamics.velocityInfluence = velocityDyn;
    p.sizeDynamics.jitter = jitter;

    addPreset(p);
  };

  // ==================== SKETCHING ====================
  addBrush("Sketching", "Pencil HB", 8, 0.7f, 0.2f, 0.05f, 0.25f,
           "paper_grain.png", 200.0f, 0.6f, "tip_pencil.png", 0, 0, true, true,
           0, 0.08f);
  addBrush("Sketching", "Pencil 6B", 20, 0.9f, 0.4f, 0.04f, 0.1f,
           "paper_grain.png", 200.0f, 0.6f, "tip_pencil.png", 0, 0, true, true,
           0, 0.12f);
  addBrush("Sketching", "Mechanical", 2.5f, 0.95f, 0.95f, 0.008f, 0.3f,
           "paper_grain.png", 450.0f, 0.75f, "tip_hard.png", 0, 0, true, true,
           0, 0.01f, 1.0f, 0.4f);

  // ==================== INKING ====================
  addBrush("Inking", "Ink Pen", 12, 1.0f, 1.0f, 0.015f, 0.75f, "", 0, 0,
           "tip_hard.png", 0, 0, true, false, -0.2f, 0, 1.0f, 0.8f);
  addBrush("Inking", "G-Pen", 18, 1.0f, 0.98f, 0.01f, 0.8f, "", 0, 0,
           "tip_hard.png", 0, 0, true, false, -0.15f, 0, 1.0f, 0.9f);
  addBrush("Inking", "Maru Pen", 6, 1.0f, 1.0f, 0.01f, 0.6f, "", 0, 0,
           "tip_hard.png");
  addBrush("Inking", "Marker", 28, 0.35f, 0.95f, 0.03f, 0.15f, "", 0, 0,
           "tip_square.png", 0, 0, false, true);

  // ==================== WATERCOLOR ====================
  addBrush("Watercolor", "Watercolor", 50, 0.3f, 0.15f, 0.08f, 0.45f,
           "watercolor_paper.png", 80.0f, 0.5f, "tip_watercolor.png", 0.5f, 0,
           true, false, 0, 0.06f);
  addBrush("Watercolor", "Watercolor Wet", 60, 0.25f, 0.05f, 0.1f, 0.5f,
           "watercolor_paper.png", 60.0f, 0.4f, "tip_watercolor.png", 0.95f, 0,
           true, false, 0, 0.1f);

  // ==================== PAINTING ====================
  addBrush("Painting", "Oil Paint", 40, 0.95f, 0.75f, 0.015f, 0.35f,
           "canvas_weave.png", 150.0f, 0.7f, "tip_bristle.png", 0, 0.4f, true,
           false, 0, 0);
  addBrush("Painting", "Acrylic", 38, 0.98f, 0.85f, 0.02f, 0.25f,
           "canvas_weave.png", 150.0f, 0.5f, "tip_bristle.png", 0, 0.25f, true,
           false);
  addBrush("Painting", "The Blender", 50, 0.6f, 0.5f, 0.02f, 0.0f, "", 0, 0,
           "tip_soft.png", 0.8f, 0.3f, true, false);
  addBrush("Painting", "Smudge Tool", 40, 1.0f, 0.3f, 0.01f, 0.0f, "", 0, 0,
           "tip_soft.png", 0.2f, 0.95f, true, false);

  // ==================== OIL PAINTING ====================
  addBrush("Oil Painting", "Óleo Classic Flat", 60, 1.0f, 0.9f, 0.04f, 0.0f, "",
           0, 0, "oil_flat_pro.png", 0.6f, 0.1f, true, false, 0, 0, 0.35f);
  addBrush("Oil Painting", "Óleo Round Bristle", 45, 0.95f, 0.7f, 0.05f, 0.0f,
           "", 0, 0, "oil_filbert_pro.png", 0.75f, 0.2f, true, true, 0, 0,
           0.4f);
  addBrush("Oil Painting", "Óleo Impasto Knife", 80, 1.0f, 1.0f, 0.02f, 0.0f,
           "", 0, 0, "oil_knife_pro.png", 0.1f, 0.8f, false, false, 0, 0, 0.8f);
  addBrush("Oil Painting", "Óleo Dry Scumble", 70, 0.8f, 0.5f, 0.08f, 0.0f, "",
           0, 0, "oil_flat_pro.png", 0, 0.1f, false, true, 0, 0, 0.15f);
  addBrush("Oil Painting", "Óleo Wet Blender", 90, 0.0f, 0.2f, 0.04f, 0.0f, "",
           0, 0, "oil_filbert_pro.png", 1.0f, 0.95f, true, false, 0, 0, 0.5f);

  // ==================== AIRBRUSH ====================
  addBrush("Airbrush", "Soft", 100, 0.08f, 0.0f, 0.15f, 0.1f, "", 0, 0,
           "tip_soft.png", 0, 0, false, true);
  addBrush("Airbrush", "Hard", 45, 0.2f, 0.8f, 0.08f, 0.1f, "", 0, 0,
           "tip_hard.png", 0, 0, false, true, 0, 0.15f);

  // ==================== ERASER ====================
  addBrush("Eraser", "Eraser Soft", 45, 0.85f, 0.15f, 0.08f, 0.0f);
  addBrush("Eraser", "Eraser Hard", 22, 1.0f, 0.98f, 0.03f, 0.0f);

  qDebug() << "BrushPresetManager: Loaded" << allPresets().size()
           << "default presets in" << m_groups.size() << "groups";
}

} // namespace artflow
