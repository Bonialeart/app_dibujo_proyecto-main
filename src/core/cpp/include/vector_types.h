#pragma once

#include <algorithm>
#include <memory>
#include <vector>
#include <QColor>
#include <QRectF>
#include <QString>

namespace artflow {

struct BrushSettings;

struct VPoint2D {
    float x = 0.0f;
    float y = 0.0f;
    float pressure = 1.0f;
};

struct BezierSegment {
    VPoint2D p0;
    VPoint2D cp1;
    VPoint2D cp2;
    VPoint2D p3;
    float widthStart = 1.0f;
    float widthEnd = 1.0f;
};

struct VectorStroke {
    uint32_t id = 0;
    std::vector<BezierSegment> segments;
    QColor color = Qt::black;
    float opacity = 1.0f;
    float globalWidth = 1.0f;
    QRectF cachedBounds;

    // Brush Tip/Texture fields to preserve brush quality
    QString tipTextureName;
    float spacing = 0.1f;
    float hardness = 0.8f;
    bool useTexture = false;
    QString textureName;
    bool isEraser = false;

    // Full brush preset captured at stroke creation so the vector path can be
    // re-rendered with the exact raster brush look (grain, taper, jitter...).
    // Shared (immutable) between fragments produced by the vector eraser and
    // undo snapshots, so copies stay cheap.
    std::shared_ptr<const BrushSettings> brush;

    void recalcBounds() {
        if (segments.empty()) {
            cachedBounds = QRectF();
            return;
        }
        float minX = 1e9f, minY = 1e9f, maxX = -1e9f, maxY = -1e9f;
        auto update = [&](float x, float y, float w) {
            float r = w * 0.5f;
            if (x - r < minX) minX = x - r;
            if (x + r > maxX) maxX = x + r;
            if (y - r < minY) minY = y - r;
            if (y + r > maxY) maxY = y + r;
        };

        for (const auto& seg : segments) {
            // Check endpoints and control points to get a conservative bounding box quickly
            float maxW = std::max(seg.widthStart, seg.widthEnd) * globalWidth;
            update(seg.p0.x, seg.p0.y, seg.widthStart * globalWidth);
            update(seg.cp1.x, seg.cp1.y, maxW);
            update(seg.cp2.x, seg.cp2.y, maxW);
            update(seg.p3.x, seg.p3.y, seg.widthEnd * globalWidth);
        }
        cachedBounds = QRectF(minX, minY, maxX - minX, maxY - minY);
    }
};

} // namespace artflow
