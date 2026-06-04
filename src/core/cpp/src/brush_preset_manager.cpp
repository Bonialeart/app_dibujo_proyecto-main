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
      
      // Map group name to consolidated category
      QString mappedGroupName = group.name;
      static const QMap<QString, QString> categoryMapping = {
          {"Sketching", "Sketch & Ink"},
          {"Inking", "Sketch & Ink"},
          {"Drawing", "Sketch & Ink"},
          {"Charcoal", "Sketch & Ink"},
          {"Calligraphy", "Sketch & Ink"},
          {"Manga", "Sketch & Ink"},
          
          {"Painting", "Paint & Blend"},
          {"Watercolor", "Paint & Blend"},
          {"Oil Painting", "Paint & Blend"},
          {"Oil Brushes", "Paint & Blend"},
          {"Oil Pro", "Paint & Blend"},
          {"Artistic", "Paint & Blend"},
          
          {"Airbrush", "Airbrush"},
          {"Airbrushing", "Airbrush"},
          {"Sprays", "Airbrush"},
          {"Textures", "Airbrush"},
          {"Custom Textures", "Airbrush"},
          {"Luminance", "Airbrush"},
          {"Abstract", "Airbrush"},
          {"Elements", "Airbrush"},
          {"Vintage", "Airbrush"},
          {"Industrial", "Airbrush"},
          
          {"Eraser", "Eraser"}
      };

      QString lowerCat = group.name.trimmed();
      for (auto it = categoryMapping.begin(); it != categoryMapping.end(); ++it) {
        if (it.key().compare(lowerCat, Qt::CaseInsensitive) == 0) {
          mappedGroupName = it.value();
          break;
        }
      }

      // Merge into existing group or add new
      BrushGroup &target = ensureGroup(mappedGroupName, group.icon);
      for (auto &b : group.brushes) {
        b.category = mappedGroupName;
        target.brushes.push_back(std::move(b));
      }
      count += group.brushes.size();
      qDebug() << "BrushPresetManager: Loaded group" << mappedGroupName << "with"
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
  QString mappedCategory = preset.category;

  // Group all standard preset categories into fewer master categories
  static const QMap<QString, QString> categoryMapping = {
      {"Sketching", "Sketch & Ink"},
      {"Inking", "Sketch & Ink"},
      {"Drawing", "Sketch & Ink"},
      {"Charcoal", "Sketch & Ink"},
      {"Calligraphy", "Sketch & Ink"},
      {"Manga", "Sketch & Ink"},
      
      {"Painting", "Paint & Blend"},
      {"Watercolor", "Paint & Blend"},
      {"Oil Painting", "Paint & Blend"},
      {"Oil Brushes", "Paint & Blend"},
      {"Oil Pro", "Paint & Blend"},
      {"Artistic", "Paint & Blend"},
      
      {"Airbrush", "Airbrush"},
      {"Airbrushing", "Airbrush"},
      {"Sprays", "Airbrush"},
      {"Textures", "Airbrush"},
      {"Custom Textures", "Airbrush"},
      {"Luminance", "Airbrush"},
      {"Abstract", "Airbrush"},
      {"Elements", "Airbrush"},
      {"Vintage", "Airbrush"},
      {"Industrial", "Airbrush"},
      
      {"Eraser", "Eraser"}
  };

  QString lowerCat = preset.category.trimmed();
  for (auto it = categoryMapping.begin(); it != categoryMapping.end(); ++it) {
    if (it.key().compare(lowerCat, Qt::CaseInsensitive) == 0) {
      mappedCategory = it.value();
      break;
    }
  }

  // Also verify by preset name heuristics if the category is empty or generic
  if (mappedCategory.isEmpty() || mappedCategory.compare("Default", Qt::CaseInsensitive) == 0) {
    if (preset.name.contains("Eraser", Qt::CaseInsensitive)) {
      mappedCategory = "Eraser";
    } else if (preset.name.contains("Airbrush", Qt::CaseInsensitive) || preset.name.contains("Spray", Qt::CaseInsensitive)) {
      mappedCategory = "Airbrush";
    } else if (preset.name.contains("Pencil", Qt::CaseInsensitive) || preset.name.contains("Ink", Qt::CaseInsensitive) || preset.name.contains("Pen", Qt::CaseInsensitive)) {
      mappedCategory = "Sketch & Ink";
    } else {
      mappedCategory = "Paint & Blend";
    }
  }

  BrushPreset updatedPreset = preset;
  updatedPreset.category = mappedCategory;

  BrushGroup &group = ensureGroup(mappedCategory);
  group.brushes.push_back(updatedPreset);
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

  // ==================== SKETCH & INK ====================
  addBrush("Sketch & Ink", "Pencil HB", 8, 0.7f, 0.2f, 0.05f, 0.25f,
           "grain_sketch_paper.png", 200.0f, 0.6f, "pincel_texturizado.png", 0, 0, true, true,
           0, 0.08f);
  addBrush("Sketch & Ink", "Pencil 6B", 20, 0.9f, 0.4f, 0.04f, 0.1f,
           "carboncillo.png", 200.0f, 0.6f, "textured.png", 0, 0, true, true,
           0, 0.12f);
  addBrush("Sketch & Ink", "Mechanical", 2.5f, 0.95f, 0.95f, 0.008f, 0.3f,
           "carboncillo.png", 450.0f, 0.75f, "portaminas.png", 0, 0, true, true,
           0, 0.01f, 1.0f, 0.4f);
  addBrush("Sketch & Ink", "Ink Pen", 12, 1.0f, 1.0f, 0.015f, 0.75f, "", 0, 0,
           "ink_roller.png", 0, 0, true, false, -0.2f, 0, 1.0f, 0.8f);
  addBrush("Sketch & Ink", "G-Pen", 18, 1.0f, 0.98f, 0.01f, 0.8f, "", 0, 0,
           "ink_g_pen.png", 0, 0, true, false, -0.15f, 0, 1.0f, 0.9f);
  addBrush("Sketch & Ink", "Maru Pen", 6, 1.0f, 1.0f, 0.01f, 0.6f, "", 0, 0,
           "ink_maru_pen.png");
  addBrush("Sketch & Ink", "Marker", 28, 0.35f, 0.95f, 0.03f, 0.15f, "", 0, 0,
           "paint_flat.png", 0, 0, false, true);

  // --- BRAND NEW CUSTOM SKETCH & INK BRUSHES ---
  addBrush("Sketch & Ink", "Carboncillo Pro", 24, 0.85f, 0.35f, 0.06f, 0.0f,
           "carboncillo.png", 180.0f, 0.7f, "carboncillo.png", 0, 0, true, true, 0, 0.15f);
  addBrush("Sketch & Ink", "Tiza Creyón", 30, 0.9f, 0.45f, 0.05f, 0.0f,
           "tiza.png", 150.0f, 0.65f, "tiza.png", 0, 0, true, true);
  addBrush("Sketch & Ink", "Lápiz Triangular", 16, 0.95f, 0.8f, 0.02f, 0.2f,
           "grain_sketch_paper.png", 220.0f, 0.5f, "triangular.png", 0, 0, true, true);
  addBrush("Sketch & Ink", "Tinta China Pro", 14, 1.0f, 0.95f, 0.012f, 0.7f,
           "", 0, 0, "tinta_china.png", 0, 0, true, false);

  // ==================== PAINT & BLEND ====================
  addBrush("Paint & Blend", "Acuarela clásica", 50, 0.3f, 0.15f, 0.08f, 0.45f,
           "pincel_redondo.sut.1.layer.png", 80.0f, 0.5f, "shape_round.png", 0.78f, 0,
           true, false, 0, 0.06f);
  {
    BrushPreset &wcPreset = m_groups.back().brushes.back();
    wcPreset.wetMix.dilution = 0.18f;
    wcPreset.wetMix.bleed = 0.65f;
    wcPreset.wetMix.absorptionRate = 0.28f;
    wcPreset.wetMix.dryingTime = 2.5f;
    wcPreset.pigment.granulation = 0.35f;
    wcPreset.pigment.flow = 0.70f;
    wcPreset.pigment.staining = 0.38f;
    wcPreset.bloom.enabled = true;
    wcPreset.bloom.intensity = 0.50f;
    wcPreset.bloom.radius = 16.0f;
    wcPreset.edgeDarkening.enabled = true;
    wcPreset.edgeDarkening.intensity = 0.55f;
    wcPreset.edgeDarkening.width = 0.18f;
  }

  addBrush("Paint & Blend", "Acuarela aguada", 60, 0.25f, 0.05f, 0.1f, 0.5f,
           "acuarela_aguada.sut.2.layer.png", 25.0f, 0.8f, "acuarela_aguada.sut.3.layer.png", 0.88f, 0,
           true, false, 0, 0.1f);
  {
    BrushPreset &wcPreset = m_groups.back().brushes.back();
    wcPreset.wetMix.wetness = 0.88f;
    wcPreset.wetMix.dilution = 0.80f;
    wcPreset.wetMix.bleed = 0.92f;
    wcPreset.wetMix.absorptionRate = 0.05f;
    wcPreset.wetMix.dryingTime = 5.0f;
    wcPreset.pigment.granulation = 0.20f;
    wcPreset.pigment.flow = 0.65f;
    wcPreset.bloom.enabled = true;
    wcPreset.bloom.intensity = 0.45f;
    wcPreset.bloom.radius = 24.0f;
    wcPreset.edgeDarkening.enabled = true;
    wcPreset.edgeDarkening.intensity = 0.75f;
    wcPreset.edgeDarkening.width = 0.18f;
    wcPreset.dualBrush.enabled = true;
    wcPreset.dualBrush.tipTexture = "acuarela_aguada_4.png";
    wcPreset.dualBrush.scale = 1.25f;
    wcPreset.dualBrush.rotation = 0.0f;
    wcPreset.dualBrush.blendMode = "multiply";
  }

  addBrush("Paint & Blend", "Acuarela salpicaduras", 75, 0.4f, 0.1f, 0.25f, 0.1f,
           "salpicaduras.sut.1.layer.png", 120.0f, 0.6f, "salpicaduras.sut.2.layer.png", 0.65f, 0,
           true, false, 0, 0.35f);
  {
    BrushPreset &wcPreset = m_groups.back().brushes.back();
    wcPreset.wetMix.dilution = 0.3f;
    wcPreset.wetMix.bleed = 0.7f;
    wcPreset.wetMix.absorptionRate = 0.4f;
    wcPreset.wetMix.dryingTime = 1.8f;
    wcPreset.pigment.granulation = 0.6f;
    wcPreset.pigment.flow = 0.80f;
    wcPreset.bloom.enabled = true;
    wcPreset.bloom.intensity = 0.75f;
    wcPreset.bloom.radius = 12.0f;
    wcPreset.edgeDarkening.enabled = true;
    wcPreset.edgeDarkening.intensity = 0.70f;
    wcPreset.edgeDarkening.width = 0.22f;
  }
  addBrush("Paint & Blend", "Oil Paint", 40, 0.95f, 0.75f, 0.015f, 0.35f,
           "grain_canvas_weave.png", 150.0f, 0.7f, "oil_bristle_pro.png", 0, 0.4f, true,
           false, 0, 0);
  addBrush("Paint & Blend", "Acrylic", 38, 0.98f, 0.85f, 0.02f, 0.25f,
           "grain_canvas_weave.png", 150.0f, 0.5f, "wet_acrylic.png", 0, 0.25f, true,
           false);
  addBrush("Paint & Blend", "The Blender", 50, 0.6f, 0.5f, 0.02f, 0.0f, "", 0, 0,
           "soft_blend.png", 0.8f, 0.3f, true, false);
  {
    BrushPreset &p = m_groups.back().brushes.back();
    p.wetMix.blendOnly = true;
    p.defaultOpacity = 0.0f;
  }

  addBrush("Paint & Blend", "Smudge Tool", 40, 1.0f, 0.3f, 0.01f, 0.0f, "", 0, 0,
           "smudge_textured.png", 0.2f, 0.95f, true, false);
  {
    BrushPreset &p = m_groups.back().brushes.back();
    p.wetMix.blendOnly = true;
    p.defaultOpacity = 0.0f;
  }

  addBrush("Paint & Blend", "Óleo Classic Flat", 60, 1.0f, 0.9f, 0.04f, 0.0f, "grain_canvas_weave.png",
           120.0f, 0.5f, "oil_flat_pro.png", 0.6f, 0.1f, true, false, 0, 0, 0.35f);

  addBrush("Paint & Blend", "Óleo Round Bristle", 45, 0.95f, 0.7f, 0.05f, 0.0f,
           "grain_canvas_weave.png", 120.0f, 0.5f, "oil_filbert_pro.png", 0.75f, 0.2f, true, true, 0, 0,
           0.4f);

  addBrush("Paint & Blend", "Óleo Impasto Knife", 80, 1.0f, 1.0f, 0.02f, 0.0f,
           "grain_canvas_weave.png", 120.0f, 0.5f, "oil_knife_pro.png", 0.1f, 0.8f, false, false, 0, 0, 0.8f);

  addBrush("Paint & Blend", "Óleo Dry Scumble", 70, 0.8f, 0.5f, 0.08f, 0.0f, "grain_canvas_weave.png",
           150.0f, 0.8f, "oil_dry.png", 0, 0.1f, false, true, 0, 0, 0.15f);

  addBrush("Paint & Blend", "Óleo Wet Blender", 90, 0.0f, 0.2f, 0.04f, 0.0f, "grain_canvas_weave.png",
           120.0f, 0.4f, "oil_rake.png", 1.0f, 0.95f, true, false, 0, 0, 0.5f);
  {
    BrushPreset &p = m_groups.back().brushes.back();
    p.wetMix.blendOnly = true;
    p.defaultOpacity = 0.0f;
  }

  // --- BRAND NEW CUSTOM PAINT & BLEND BRUSHES FROM CLIP STUDIO PAINT ---
  addBrush("Paint & Blend", "Óleo Clip Studio", 40, 0.95f, 0.75f, 0.015f, 0.35f,
           "grain_canvas_weave.png", 150.0f, 0.7f, "oil.png", 0, 0.4f, true, false);

  addBrush("Paint & Blend", "Acuarela Seca Clip", 45, 0.35f, 0.1f, 0.06f, 0.4f,
           "acuarela_seca.sut.1.layer.png", 90.0f, 0.55f, "shape_textured.png", 0.6f, 0, true, true);
  {
    BrushPreset &wcPreset = m_groups.back().brushes.back();
    wcPreset.wetMix.dilution = 0.25f;
    wcPreset.wetMix.bleed = 0.55f;
    wcPreset.wetMix.absorptionRate = 0.35f;
    wcPreset.wetMix.dryingTime = 1.5f;
    wcPreset.pigment.granulation = 0.45f;
    wcPreset.bloom.enabled = true;
    wcPreset.edgeDarkening.enabled = true;
  }

  addBrush("Paint & Blend", "Rotulador Punta Pincel", 30, 0.65f, 0.85f, 0.02f, 0.3f,
           "rotulador_punta_pincel.sut.1.layer.png", 90.0f, 0.3f, "rotulador_punta_pincel.sut.2.layer.png", 0, 0, true, true);

  addBrush("Paint & Blend", "Tinta Aguada Artística", 35, 0.45f, 0.5f, 0.03f, 0.5f,
           "tinta_aguada.sut.1.layer.png", 100.0f, 0.5f, "tinta_aguada.sut.2.layer.png", 0.7f, 0, true, true);
  {
    BrushPreset &wcPreset = m_groups.back().brushes.back();
    wcPreset.wetMix.dilution = 0.4f;
    wcPreset.wetMix.bleed = 0.75f;
    wcPreset.pigment.granulation = 0.2f;
  }

  addBrush("Paint & Blend", "Tinta Papel Húmedo", 50, 0.35f, 0.3f, 0.05f, 0.4f,
           "tinta_sobre_papel_húmedo.sut.1.layer.png", 110.0f, 0.6f, "tinta_sobre_papel_húmedo.sut.2.layer.png", 0.85f, 0, true, true);
  {
    BrushPreset &wcPreset = m_groups.back().brushes.back();
    wcPreset.wetMix.dilution = 0.6f;
    wcPreset.wetMix.bleed = 0.9f;
    wcPreset.wetMix.absorptionRate = 0.1f;
    wcPreset.bloom.enabled = true;
  }

  addBrush("Paint & Blend", "Agua Clara Wash", 65, 0.2f, 0.1f, 0.08f, 0.6f,
           "agua_clara.sut.2.layer.png", 80.0f, 0.4f, "agua_clara.sut.1.layer.png", 0.95f, 0, true, false);
  {
    BrushPreset &wcPreset = m_groups.back().brushes.back();
    wcPreset.wetMix.dilution = 0.95f;
    wcPreset.wetMix.bleed = 0.95f;
  }

  addBrush("Paint & Blend", "Húmedo Suave Blend", 55, 0.0f, 0.2f, 0.04f, 0.0f,
           "húmedo_suave.sut.1.layer.png", 100.0f, 0.4f, "húmedo_suave.sut.2.layer.png", 1.0f, 0.95f, true, false);
  {
    BrushPreset &p = m_groups.back().brushes.back();
    p.wetMix.blendOnly = true;
    p.defaultOpacity = 0.0f;
  }

  addBrush("Paint & Blend", "Tinta Seca Sut", 25, 0.9f, 0.8f, 0.03f, 0.2f,
           "tinta_seca.sut.1.layer.png", 120.0f, 0.7f, "tinta_seca.sut.2.layer.png", 0, 0, true, true);

  addBrush("Paint & Blend", "Acuarela Salpicaduras Pro", 80, 0.5f, 0.1f, 0.3f, 0.0f,
           "salpicaduras.sut.1.layer.png", 100.0f, 0.4f, "salpicaduras.sut.2.layer.png", 0.5f, 0, true, false, 0, 0.5f);

  // ==================== AIRBRUSH ====================
  addBrush("Airbrush", "Soft", 100, 0.08f, 0.0f, 0.15f, 0.1f, "", 0, 0,
           "shape_airbrush_soft.png", 0, 0, false, true);
  addBrush("Airbrush", "Hard", 45, 0.2f, 0.8f, 0.08f, 0.1f, "", 0, 0,
           "hard_airbrush.png", 0, 0, false, true, 0, 0.15f);

  // ==================== ERASER ====================
  addBrush("Eraser", "Eraser Soft", 45, 0.85f, 0.15f, 0.08f, 0.0f, "", 0, 0, "tip_soft_round.png");
  addBrush("Eraser", "Eraser Hard", 22, 1.0f, 0.98f, 0.03f, 0.0f, "", 0, 0, "tip_hard_round.png");

  qDebug() << "BrushPresetManager: Loaded" << allPresets().size()
           << "default presets in" << m_groups.size() << "groups";
}

} // namespace artflow
