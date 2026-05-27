#include "vector_layer_data.h"
#include "vector_math.h"
#include <algorithm>
#include <cmath>
#include <QDebug>
#include <QPainter>
#include <QImage>
#include <QFile>
#include <QCoreApplication>
#include <QFileInfo>
#include <QStringList>
#include <QMap>

namespace artflow {

static QImage loadBrushTipImage(const QString &name) {
    if (name.isEmpty()) return QImage();
    
    QString path;
    bool found = false;
    
    if (QFile::exists(name)) {
        path = name;
        found = true;
    } else {
        QStringList searchPaths;
        searchPaths << "assets/textures/" + name;
        searchPaths << "assets/brushes/tips/" + name;
        searchPaths << "assets/brushes/" + name;
        searchPaths << "../assets/textures/" + name;
        searchPaths << "../assets/brushes/tips/" + name;
        searchPaths << "../assets/brushes/" + name;
        searchPaths << "../../assets/textures/" + name;
        searchPaths << "../../assets/brushes/" + name;
        searchPaths << QCoreApplication::applicationDirPath() + "/assets/textures/" + name;
        searchPaths << QCoreApplication::applicationDirPath() + "/assets/brushes/" + name;
        searchPaths << QCoreApplication::applicationDirPath() + "/../assets/textures/" + name;
        searchPaths << QCoreApplication::applicationDirPath() + "/../assets/brushes/" + name;
        searchPaths << "src/assets/textures/" + name;
        searchPaths << ":/textures/" + name;
        
        for (const QString &p : searchPaths) {
            if (QFile::exists(p)) {
                path = p;
                found = true;
                break;
            }
        }
    }
    
    qDebug() << "loadBrushTipImage: Resolving texture '" << name << "' => Found:" << found << "Path:" << path;
    
    if (!found) {
        qWarning() << "loadBrushTipImage: Texture file not found for:" << name;
        return QImage();
    }
    
    QImage img(path);
    if (img.isNull()) {
        qWarning() << "loadBrushTipImage: Failed to read image from resolved path:" << path;
        return QImage();
    }
    
    img = img.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    
    // Check if the image has a transparent background (alpha channel)
    bool hasAlpha = false;
    for (int y = 0; y < img.height(); ++y) {
        const QRgb *scanline = reinterpret_cast<const QRgb *>(img.constScanLine(y));
        for (int x = 0; x < img.width(); ++x) {
            if (qAlpha(scanline[x]) < 255) {
                hasAlpha = true;
                break;
            }
        }
        if (hasAlpha) break;
    }
    
    if (!hasAlpha) {
        // No alpha channel (solid black-on-white image) -> convert black luma to transparent alpha mask
        qDebug() << "loadBrushTipImage: Solid brush tip detected. Converting dark luma to white-on-transparent alpha mask.";
        for (int y = 0; y < img.height(); ++y) {
            QRgb *scanline = reinterpret_cast<QRgb *>(img.scanLine(y));
            for (int x = 0; x < img.width(); ++x) {
                int luma = qGray(scanline[x]);
                int alpha = 255 - luma; // dark becomes opaque, white becomes transparent
                scanline[x] = qRgba(alpha, alpha, alpha, alpha);
            }
        }
    } else {
        // Has alpha channel -> check if it is a dark transparent shape, convert to white shape
        double totalLum = 0.0;
        int count = 0;
        for (int y = 0; y < img.height(); ++y) {
            const QRgb *scanline = reinterpret_cast<const QRgb *>(img.constScanLine(y));
            for (int x = 0; x < img.width(); ++x) {
                QRgb px = scanline[x];
                int a = qAlpha(px);
                if (a > 10) {
                    double lum = 0.299 * qRed(px) + 0.587 * qGreen(px) + 0.114 * qBlue(px);
                    totalLum += lum;
                    count++;
                }
            }
        }
        double avgLum = count > 0 ? (totalLum / count) : 255.0;
        if (avgLum < 128.0) {
            qDebug() << "loadBrushTipImage: Dark transparent tip detected. Converting color values to white.";
            for (int y = 0; y < img.height(); ++y) {
                QRgb *scanline = reinterpret_cast<QRgb *>(img.scanLine(y));
                for (int x = 0; x < img.width(); ++x) {
                    int a = qAlpha(scanline[x]);
                    scanline[x] = qRgba(255, 255, 255, a);
                }
            }
        }
        
        // Convert to standard white mask
        for (int y = 0; y < img.height(); ++y) {
            QRgb *scanline = reinterpret_cast<QRgb *>(img.scanLine(y));
            for (int x = 0; x < img.width(); ++x) {
                QRgb pixel = scanline[x];
                int luma = qGray(pixel);
                int a = qAlpha(pixel);
                int finalAlpha = (luma * a) / 255;
                scanline[x] = qRgba(finalAlpha, finalAlpha, finalAlpha, finalAlpha);
            }
        }
    }
    return img;
}

static void paintVectorTipRaster(QPainter *painter, const QPointF &point, float size,
                                 float opacity, const QColor &color, const QImage &tipImg) {
    if (tipImg.isNull()) return;

    QImage base = tipImg;
    if (base.width() != base.height()) {
        int s = std::min(base.width(), base.height());
        int cx = (base.width() - s) / 2;
        int cy = (base.height() - s) / 2;
        base = base.copy(cx, cy, s, s);
    }

    QImage tintedImg = base.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    QPainter p(&tintedImg);
    p.setCompositionMode(QPainter::CompositionMode_SourceIn);
    p.fillRect(tintedImg.rect(), color);
    p.end();

    painter->save();
    painter->setOpacity(opacity);
    painter->translate(point);
    QRectF rect(-size / 2.0, -size / 2.0, size, size);
    painter->drawImage(rect, tintedImg);
    painter->restore();
}

static void paintSoftStampVector(QPainter *painter, const QPointF &point, float size,
                                 float opacity, const QColor &color, float hardness) {
    painter->save();
    painter->setPen(Qt::NoPen);
    painter->setOpacity(opacity);

    QRadialGradient gradient(point, size / 2.0);
    QColor c = color;

    if (hardness >= 0.99f) {
        gradient.setColorAt(0.0, c);
        gradient.setColorAt(0.95, c);
        QColor transparentColor = c;
        transparentColor.setAlpha(0);
        gradient.setColorAt(1.0, transparentColor);
    } else {
        gradient.setColorAt(0.0, c);
        if (hardness > 0.0f) {
            gradient.setColorAt(hardness, c);
        }

        int steps = 10;
        for (int i = 1; i <= steps; ++i) {
            float t = static_cast<float>(i) / steps;
            float stop = std::min(1.0f, hardness + t * (1.0f - hardness));
            float alphaMult = 0.5f * (1.0f + std::cos(t * 3.14159265f));
            QColor stepColor = c;
            stepColor.setAlphaF(c.alphaF() * alphaMult);
            gradient.setColorAt(stop, stepColor);
        }
    }

    painter->setBrush(QBrush(gradient));
    painter->drawEllipse(point, size / 2.0, size / 2.0);
    painter->restore();
}

// Helper to split a stroke at multiple sorted split points
static std::vector<VectorStroke> splitStrokeAtMultiple(const VectorStroke& stroke, std::vector<std::pair<int, float>>& splits) {
    std::vector<VectorStroke> fragments;
    if (splits.empty()) {
        fragments.push_back(stroke);
        return fragments;
    }

    // Sort splits in descending order of position on the stroke
    std::sort(splits.begin(), splits.end(), [](const auto& a, const auto& b) {
        if (a.first != b.first) return a.first > b.first;
        return a.second > b.second;
    });

    VectorStroke current = stroke;
    std::vector<VectorStroke> tempFrags;
    for (const auto& split : splits) {
        // Validate split coordinates
        if (split.first < 0 || split.first >= static_cast<int>(current.segments.size())) {
            continue;
        }
        auto halves = splitStrokeAt(current, split.first, split.second);
        tempFrags.push_back(halves.second);
        current = halves.first;
    }
    tempFrags.push_back(current);
    
    // Reverse to match original start-to-end direction
    std::reverse(tempFrags.begin(), tempFrags.end());

    // Clean up empty or extremely small fragments
    std::vector<VectorStroke> validFrags;
    for (auto& frag : tempFrags) {
        frag.recalcBounds();
        if (!frag.segments.empty() && frag.cachedBounds.width() >= 0.01f && frag.cachedBounds.height() >= 0.01f) {
            validFrags.push_back(frag);
        }
    }
    return validFrags;
}

VectorLayerData::VectorLayerData(int canvasW, int canvasH)
    : m_canvasW(canvasW), m_canvasH(canvasH) {}

uint32_t VectorLayerData::addStroke(VectorStroke&& stroke) {
    stroke.id = m_nextId++;
    stroke.recalcBounds();
    m_strokes.push_back(std::move(stroke));
    return m_strokes.back().id;
}

void VectorLayerData::removeStroke(uint32_t id) {
    m_strokes.erase(
        std::remove_if(m_strokes.begin(), m_strokes.end(), [id](const auto& s) { return s.id == id; }),
        m_strokes.end()
    );
}

VectorStroke* VectorLayerData::getStroke(uint32_t id) {
    for (auto& stroke : m_strokes) {
        if (stroke.id == id) return &stroke;
    }
    return nullptr;
}

const std::vector<VectorStroke>& VectorLayerData::getStrokes() const {
    return m_strokes;
}

std::vector<VectorStroke>& VectorLayerData::getStrokes() {
    return m_strokes;
}

VectorLayerData::EraseResult VectorLayerData::vectorErase(const VectorStroke& eraserPath) {
    EraseResult result;
    std::vector<VectorStroke> updatedStrokes;
    
    // Eraser threshold: let's use the eraser's width plus a small buffer
    float eraserRadius = eraserPath.globalWidth * 4.0f; 
    if (eraserRadius < 6.0f) eraserRadius = 6.0f; // minimum eraser size

    for (const auto& stroke : m_strokes) {
        // Quick bounding box check
        QRectF expandedEraserBounds = eraserPath.cachedBounds.adjusted(-eraserRadius, -eraserRadius, eraserRadius, eraserRadius);
        if (!stroke.cachedBounds.intersects(expandedEraserBounds)) {
            updatedStrokes.push_back(stroke);
            continue;
        }

        // Find intersections
        auto intersections = findIntersections(stroke, eraserPath);

        if (intersections.empty()) {
            // No direct intersections, check if eraser is extremely close to the whole stroke
            float minDist = 1e9f;
            for (const auto& seg : stroke.segments) {
                for (float t = 0.0f; t <= 1.0f; t += 0.25f) {
                    VPoint2D pt = evalBezier(seg, t);
                    auto distRes = distanceToStroke(pt, eraserPath);
                    if (distRes.distance < minDist) {
                        minDist = distRes.distance;
                    }
                }
            }

            if (minDist < eraserRadius) {
                result.removedIds.push_back(stroke.id);
            } else {
                updatedStrokes.push_back(stroke);
            }
            continue;
        }

        // Direct intersections found! Split stroke at intersection points
        std::vector<std::pair<int, float>> splits;
        for (const auto& inter : intersections) {
            splits.push_back({inter.segIdxA, inter.tA});
        }

        auto fragments = splitStrokeAtMultiple(stroke, splits);
        bool strokeWasModified = false;

        for (auto& frag : fragments) {
            float minDist = 1e9f;
            
            // Check segment midpoints
            for (const auto& seg : frag.segments) {
                VPoint2D mid = evalBezier(seg, 0.5f);
                auto distRes = distanceToStroke(mid, eraserPath);
                if (distRes.distance < minDist) minDist = distRes.distance;
            }

            // Check endpoints
            if (!frag.segments.empty()) {
                auto dStart = distanceToStroke(frag.segments.front().p0, eraserPath);
                if (dStart.distance < minDist) minDist = dStart.distance;
                
                auto dEnd = distanceToStroke(frag.segments.back().p3, eraserPath);
                if (dEnd.distance < minDist) minDist = dEnd.distance;
            }

            if (minDist < eraserRadius) {
                strokeWasModified = true;
            } else {
                // Keep the fragment! Give it a new ID if the stroke was split
                if (strokeWasModified || fragments.size() > 1) {
                    frag.id = m_nextId++;
                    frag.recalcBounds();
                    result.newFragments.push_back(frag);
                    updatedStrokes.push_back(frag);
                } else {
                    updatedStrokes.push_back(frag);
                }
            }
        }

        // Since it was split/erased, we mark the original stroke ID as removed
        result.removedIds.push_back(stroke.id);
    }

    m_strokes = std::move(updatedStrokes);
    return result;
}

void VectorLayerData::rasterize(ImageBuffer& output, float scale) const {
    for (const auto& stroke : m_strokes) {
        rasterizeStroke(stroke, output, scale);
    }
}

void VectorLayerData::rasterizeStroke(const VectorStroke& stroke, ImageBuffer& output, float scale) const {
    if (stroke.segments.empty()) return;
    
    QImage tipImg;
    bool hasTexture = false;
    if (!stroke.tipTextureName.isEmpty()) {
        static QMap<QString, QImage> s_vectorTipCache;
        if (s_vectorTipCache.contains(stroke.tipTextureName)) {
            tipImg = s_vectorTipCache[stroke.tipTextureName];
        } else {
            tipImg = loadBrushTipImage(stroke.tipTextureName);
            s_vectorTipCache[stroke.tipTextureName] = tipImg;
        }
        hasTexture = !tipImg.isNull();
    }

    QImage canvasImg(output.data(), output.width(), output.height(), QImage::Format_RGBA8888_Premultiplied);
    QPainter painter(&canvasImg);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setRenderHint(QPainter::SmoothPixmapTransform);
    
    if (stroke.isEraser) {
        painter.setCompositionMode(QPainter::CompositionMode_DestinationOut);
    } else {
        painter.setCompositionMode(QPainter::CompositionMode_SourceOver);
    }

    for (const auto& seg : stroke.segments) {
        auto pts = flattenToPolyline(seg, 1.0f);
        if (pts.empty()) continue;

        float distSinceLastDab = 0.0f;
        VPoint2D prev = pts[0];
        float wPrev = prev.pressure * seg.widthStart * stroke.globalWidth * scale;
        
        // Draw first dab
        if (hasTexture) {
            paintVectorTipRaster(&painter, QPointF(prev.x * scale, prev.y * scale), wPrev, stroke.opacity, stroke.color, tipImg);
        } else {
            paintSoftStampVector(&painter, QPointF(prev.x * scale, prev.y * scale), wPrev, stroke.opacity, stroke.color, stroke.hardness);
        }

        for (size_t i = 1; i < pts.size(); ++i) {
            VPoint2D curr = pts[i];
            
            float tSegment = static_cast<float>(i) / (pts.size() - 1);
            float wStart = seg.widthStart * stroke.globalWidth * scale;
            float wEnd = seg.widthEnd * stroke.globalWidth * scale;
            float wCurr = (prev.pressure * (1.0f - tSegment) + curr.pressure * tSegment) * 
                          (wStart * (1.0f - tSegment) + wEnd * tSegment);

            float dx = curr.x - prev.x;
            float dy = curr.y - prev.y;
            float d = std::sqrt(dx * dx + dy * dy);
            
            if (d < 1e-6f) {
                prev = curr;
                wPrev = wCurr;
                continue;
            }

            distSinceLastDab += d;
            
            float radius = ((wPrev + wCurr) * 0.5f) * 0.5f;
            float step = std::max(0.5f, radius * stroke.spacing * 2.0f); 

            while (distSinceLastDab >= step) {
                float t = (step - (distSinceLastDab - d)) / d;
                t = std::clamp(t, 0.0f, 1.0f);
                
                float x = prev.x + t * dx;
                float y = prev.y + t * dy;
                float w = wPrev + t * (wCurr - wPrev);
                
                if (hasTexture) {
                    paintVectorTipRaster(&painter, QPointF(x * scale, y * scale), w, stroke.opacity, stroke.color, tipImg);
                } else {
                    paintSoftStampVector(&painter, QPointF(x * scale, y * scale), w, stroke.opacity, stroke.color, stroke.hardness);
                }
                
                distSinceLastDab -= step;
                
                // Recalculate step dynamically
                radius = w * 0.5f;
                step = std::max(0.5f, radius * stroke.spacing * 2.0f);
            }
            
            prev = curr;
            wPrev = wCurr;
        }
    }
    
    painter.end();
    output.loadRawData(output.data());
}

void VectorLayerData::transformAll(const QTransform& matrix) {
    for (auto& stroke : m_strokes) {
        for (auto& seg : stroke.segments) {
            QPointF p0 = matrix.map(QPointF(seg.p0.x, seg.p0.y));
            seg.p0.x = p0.x(); seg.p0.y = p0.y();
            
            QPointF cp1 = matrix.map(QPointF(seg.cp1.x, seg.cp1.y));
            seg.cp1.x = cp1.x(); seg.cp1.y = cp1.y();
            
            QPointF cp2 = matrix.map(QPointF(seg.cp2.x, seg.cp2.y));
            seg.cp2.x = cp2.x(); seg.cp2.y = cp2.y();
            
            QPointF p3 = matrix.map(QPointF(seg.p3.x, seg.p3.y));
            seg.p3.x = p3.x(); seg.p3.y = p3.y();
        }
        stroke.recalcBounds();
    }
}

void VectorLayerData::transformStroke(uint32_t id, const QTransform& matrix) {
    for (auto& stroke : m_strokes) {
        if (stroke.id == id) {
            for (auto& seg : stroke.segments) {
                QPointF p0 = matrix.map(QPointF(seg.p0.x, seg.p0.y));
                seg.p0.x = p0.x(); seg.p0.y = p0.y();
                
                QPointF cp1 = matrix.map(QPointF(seg.cp1.x, seg.cp1.y));
                seg.cp1.x = cp1.x(); seg.cp1.y = cp1.y();
                
                QPointF cp2 = matrix.map(QPointF(seg.cp2.x, seg.cp2.y));
                seg.cp2.x = cp2.x(); seg.cp2.y = cp2.y();
                
                QPointF p3 = matrix.map(QPointF(seg.p3.x, seg.p3.y));
                seg.p3.x = p3.x(); seg.p3.y = p3.y();
            }
            stroke.recalcBounds();
            break;
        }
    }
}

QRectF VectorLayerData::boundingBox() const {
    if (m_strokes.empty()) return QRectF();
    QRectF box = m_strokes[0].cachedBounds;
    for (size_t i = 1; i < m_strokes.size(); ++i) {
        box = box.united(m_strokes[i].cachedBounds);
    }
    return box;
}

} // namespace artflow
