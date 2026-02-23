/**
 * ArtFlow Studio - Layer Manager
 * Layer stack management for compositing
 */

#pragma once

#include "common_types.h"
#include "image_buffer.h"
#include <QRect>
#include <memory>
#include <string>
#include <vector>

namespace artflow {

struct Layer {
  enum class Type { Drawing, Group, Background };

  static uint32_t nextId() { static uint32_t s_id = 0; return ++s_id; }
  uint32_t stableId;
  std::string name;
  std::unique_ptr<ImageBuffer> buffer;     // Main RGBA display buffer
  std::unique_ptr<ImageBuffer> wetnessMap; // 0-255 map of surface wetness
  std::unique_ptr<ImageBuffer> pigmentMap; // Detailed pigment density map

  float opacity = 1.0f;
  BlendMode blendMode = BlendMode::Normal;
  bool visible = true;
  bool locked = false;
  bool alphaLock = false;
  bool clipped = false;
  bool dirty = true;
  QRect dirtyRect; // Region that needs texture re-upload
  bool isPrivate = false;
  Type type = Type::Drawing;
  int parentId = -1; // -1 means no parent (root level)
  bool expanded = true; // For group layers: is it expanded in UI?

  Layer(const std::string &name, int width, int height,
        Type type = Type::Drawing)
      : stableId(nextId()), name(name), buffer(std::make_unique<ImageBuffer>(width, height)),
        wetnessMap(std::make_unique<ImageBuffer>(width, height)),
        pigmentMap(std::make_unique<ImageBuffer>(width, height)),
        dirtyRect(0, 0, width, height), type(type), parentId(-1), expanded(true) {}

  void markDirty(const QRect &rect = QRect()) {
    dirty = true;
    if (rect.isEmpty()) {
      dirtyRect = QRect(0, 0, buffer->width(), buffer->height());
    } else {
      dirtyRect = dirtyRect.united(rect);
    }
  }
};

/**
 * LayerManager - Manages layer stack and compositing
 */
class LayerManager {
public:
  LayerManager(int width, int height);
  ~LayerManager();

  // Layer operations
  int addLayer(const std::string &name,
               Layer::Type type = Layer::Type::Drawing);
  void removeLayer(int index);
  void moveLayer(int fromIndex, int toIndex);
  void duplicateLayer(int index);
  void mergeDown(int index);

  // Color Sampling
  void sampleColor(int x, int y, uint8_t *r, uint8_t *g, uint8_t *b, uint8_t *a,
                   int mode = 0) const;

  // Access layers
  Layer *getLayer(int index);
  const Layer *getLayer(int index) const;
  int getLayerCount() const { return static_cast<int>(m_layers.size()); }

  // Active layer
  void setActiveLayer(int index);
  int getActiveLayerIndex() const { return m_activeIndex; }
  Layer *getActiveLayer();

  // Composite all visible layers
  void compositeAll(ImageBuffer &output, bool skipPrivate = false) const;

  // Canvas dimensions
  int width() const { return m_width; }
  int height() const { return m_height; }

private:
  int m_width;
  int m_height;
  std::vector<std::unique_ptr<Layer>> m_layers;
  int m_activeIndex = 0;

  // Apply blend mode between two colors
  static void blendColors(uint8_t *dst, const uint8_t *src, BlendMode mode,
                          float opacity);
};

} // namespace artflow
