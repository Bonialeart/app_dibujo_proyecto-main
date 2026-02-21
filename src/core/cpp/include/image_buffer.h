/**
 * ArtFlow Studio - Image Buffer
 * High-performance pixel buffer for rendering
 */

#pragma once

#include "common_types.h"
#include <cstdint>
#include <cstring>
#include <memory>
#include <vector>

namespace artflow {

/**
 * ImageBuffer - RGBA pixel buffer for layer/canvas data
 */
class ImageBuffer {
public:
  ImageBuffer(int width, int height);
  ImageBuffer(const ImageBuffer &other); // Deep copy for tiles
  ~ImageBuffer();

  // Dimensions
  int width() const { return m_width; }
  int height() const { return m_height; }

  // Tile bounds calculation
  int tilesX() const { return (m_width + TILE_SIZE - 1) / TILE_SIZE; }
  int tilesY() const { return (m_height + TILE_SIZE - 1) / TILE_SIZE; }

  // Get pixel at position (returns nullptr if out of bounds)
  uint8_t *pixelAt(int x, int y);
  const uint8_t *pixelAt(int x, int y) const;

  // Set pixel color
  void setPixel(int x, int y, uint8_t r, uint8_t g, uint8_t b, uint8_t a = 255);

  void fill(uint8_t r, uint8_t g, uint8_t b, uint8_t a = 255);
  void clear();

  // Get the content bounding box (returns false if empty)
  bool getContentBounds(int &x, int &y, int &w, int &h) const;

  // Flood fill at point (x, y) with target color.
  void floodFill(int x, int y, uint8_t r, uint8_t g, uint8_t b, uint8_t a,
                 float threshold = 0.1f, const ImageBuffer *mask = nullptr);

  // Blend a color onto pixel with alpha blending. Optional alphaLock restricts
  // painting to areas that already have some alpha.
  void blendPixel(int x, int y, uint8_t r, uint8_t g, uint8_t b, uint8_t a,
                  bool alphaLock = false, bool isEraser = false);

  // Draw a filled circle (for brush dabs)
  void drawCircle(int cx, int cy, float radius, uint8_t r, uint8_t g, uint8_t b,
                  uint8_t a, float hardness = 1.0f, float grain = 0.0f,
                  bool alphaLock = false, bool isEraser = false,
                  const ImageBuffer *mask = nullptr);

  // Copy from another buffer
  void copyFrom(const ImageBuffer &other);

  // Composite another buffer on top
  void composite(const ImageBuffer &other, int offsetX = 0, int offsetY = 0,
                 float opacity = 1.0f, BlendMode mode = BlendMode::Normal,
                 const ImageBuffer *mask = nullptr);

  // Get raw bytes for Python/QML interop
  std::vector<uint8_t> getBytes() const;

  // Draw a textured stroke (High Performance C++ Splatting)
  // Moves the heavy loop from Python to C++ for lag-free painting
  void drawStrokeTextured(float x1, float y1, float x2, float y2,
                          const ImageBuffer &stamp, float spacing,
                          float opacity, bool rotate, float angle_jitter,
                          bool is_watercolor,
                          const ImageBuffer *paper_texture = nullptr);

  // Create from raw bytes
  static std::unique_ptr<ImageBuffer>
  fromBytes(const std::vector<uint8_t> &bytes, int width, int height);

  // DEPRECATED: Standard contiguous data access (compatibility layer)
  // WARNING: This reconstructs the entire buffer into a cache. Use with
  // caution.
  uint8_t *data();
  const uint8_t *data() const;

  // Efficiently load from a contiguous buffer
  void loadRawData(const uint8_t *rawData);

  // Tile dimensions
  static constexpr int TILE_SIZE = 256;
  static constexpr int TILE_PIXELS = TILE_SIZE * TILE_SIZE;
  static constexpr int TILE_BYTES = TILE_PIXELS * 4;

  struct Tile {
    int startX, startY;
    std::unique_ptr<uint8_t[]> data;
    bool dirty = false; // Flag to easily sync to GPU/Compositor

    Tile(int sx, int sy)
        : startX(sx), startY(sy), data(new uint8_t[TILE_BYTES]()) {
      // Memory is zero-initialized by `new uint8_t[]()`
    }
  };

  // Obtain a tile (allocate if necessary)
  Tile *getTile(int x, int y, bool allocate = true);
  const Tile *getTile(int x, int y) const;

  // Retrieve underlying tiles (Useful for fast GPU texture uploads)
  const std::vector<std::unique_ptr<Tile>> &getTiles() const { return m_tiles; }

  bool hasDirtyTiles() const {
    for (const auto &tile : m_tiles) {
      if (tile && tile->dirty)
        return true;
    }
    return false;
  }

  void clearDirtyFlags() {
    for (auto &tile : m_tiles) {
      if (tile)
        tile->dirty = false;
    }
  }

private:
  int m_width;
  int m_height;
  int m_gridW;
  int m_gridH;

  // Sparse storage: grid of unique_ptrs. Null means tile not allocated.
  std::vector<std::unique_ptr<Tile>> m_tiles;

  // Compatibility cache for data()
  mutable std::vector<uint8_t> m_cachedData;
  mutable bool m_cacheDirty = true;

  void ensureCacheUpToDate() const;

  // Converts global (x,y) into tile local memory index
  size_t pixelIndexLocal(int lx, int ly) const {
    return static_cast<size_t>((ly * TILE_SIZE + lx) * 4);
  }

  bool isValidCoord(int x, int y) const {
    return x >= 0 && x < m_width && y >= 0 && y < m_height;
  }
};

} // namespace artflow
