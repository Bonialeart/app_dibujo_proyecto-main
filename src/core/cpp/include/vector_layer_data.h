#pragma once

#include "vector_types.h"
#include "image_buffer.h"
#include <vector>
#include <memory>
#include <QTransform>

class QPainter;

namespace artflow {

class VectorLayerData {
public:
    // Draft = fast approximate preview (flat polyline pen, coarse flattening),
    // used while a node is being dragged. Final = full brush-engine rendering.
    enum class RasterQuality { Draft, Final };

    VectorLayerData(int canvasW, int canvasH);
    ~VectorLayerData() = default;

    // Stroke management
    uint32_t addStroke(VectorStroke&& stroke);
    void removeStroke(uint32_t id);
    VectorStroke* getStroke(uint32_t id);
    const std::vector<VectorStroke>& getStrokes() const;
    std::vector<VectorStroke>& getStrokes();

    // Vector Eraser result
    struct EraseResult {
        std::vector<uint32_t> removedIds;
        std::vector<VectorStroke> newFragments;
    };
    
    // Erase strokes intersecting or close to the eraserPath
    EraseResult vectorErase(const VectorStroke& eraserPath);

    // Rasterization
    void rasterize(ImageBuffer& output, float scale = 1.0f,
                   RasterQuality quality = RasterQuality::Final) const;
    void rasterizeStroke(const VectorStroke& stroke, ImageBuffer& output, float scale = 1.0f) const;

    // Re-rasterize only `region` (canvas coordinates): clears the region and
    // redraws the strokes that intersect it, clipped. Much cheaper than a full
    // rasterize() when editing a single stroke on a crowded layer.
    void rasterizeRegion(ImageBuffer& output, const QRectF& region, float scale = 1.0f,
                         RasterQuality quality = RasterQuality::Final) const;

    // Transformations
    void transformAll(const QTransform& matrix);
    void transformStroke(uint32_t id, const QTransform& matrix);

    // Bounding box global
    QRectF boundingBox() const;

    // Canvas dimensions
    int canvasWidth() const { return m_canvasW; }
    int canvasHeight() const { return m_canvasH; }

private:
    void paintStrokeInternal(QPainter& painter, const VectorStroke& stroke,
                             float scale, RasterQuality quality) const;

    int m_canvasW;
    int m_canvasH;
    std::vector<VectorStroke> m_strokes;
    uint32_t m_nextId = 1;
};

} // namespace artflow
