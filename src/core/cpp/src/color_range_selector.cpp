#include "color_range_selector.h"
#include <cmath>
#include <algorithm>
#include <vector>
#include <functional>
#include <unordered_map>
#include <utility>

namespace artflow {

ColorRangeSelector::ColorRangeSelector() {}

ColorRangeSelector::~ColorRangeSelector() {}

QImage ColorRangeSelector::selectByColor(const QImage &image, const QColor &targetColor,
                                         float tolerance, int channelMode, float fuzziness,
                                         bool invert) const {
    int W = image.width();
    int H = image.height();

    QImage mask(W, H, QImage::Format_Grayscale8);
    if (W <= 0 || H <= 0) return mask;

    int tr = targetColor.red();
    int tg = targetColor.green();
    int tb = targetColor.blue();

    int tH, tS, tV;
    targetColor.getHsv(&tH, &tS, &tV);
    if (tH < 0) tH = 0;

    float tL = 0.299f * tr + 0.587f * tg + 0.114f * tb;
    float fuzzRange = fuzziness * 2.55f;

    for (int y = 0; y < H; ++y) {
        uint8_t *maskLine = mask.scanLine(y);
        for (int x = 0; x < W; ++x) {
            QRgb pixel = image.pixel(x, y);
            int pr = qRed(pixel);
            int pg = qGreen(pixel);
            int pb = qBlue(pixel);
            int pa = qAlpha(pixel);

            float alphaFactor = pa / 255.0f;
            float diff = 0.0f;

            switch (channelMode) {
                case 0: { // All Channels (RGB Euclidean)
                    float dist = std::sqrt((pr - tr) * (pr - tr) + (pg - tg) * (pg - tg) + (pb - tb) * (pb - tb));
                    diff = (dist / 441.673f) * 255.0f; // Normalized to 0-255
                    break;
                }
                case 1: // Red Channel
                    diff = std::abs(pr - tr);
                    break;
                case 2: // Green Channel
                    diff = std::abs(pg - tg);
                    break;
                case 3: // Blue Channel
                    diff = std::abs(pb - tb);
                    break;
                case 4: { // Hue Channel
                    QColor col(pr, pg, pb);
                    int h, s, v;
                    col.getHsv(&h, &s, &v);
                    if (h < 0) h = 0;
                    int deltaH = std::abs(h - tH);
                    if (deltaH > 180) deltaH = 360 - deltaH;
                    diff = (deltaH / 180.0f) * 255.0f;
                    break;
                }
                case 5: { // Saturation Channel
                    QColor col(pr, pg, pb);
                    int h, s, v;
                    col.getHsv(&h, &s, &v);
                    diff = std::abs(s - tS);
                    break;
                }
                case 6: { // Luminosity Channel
                    float pl = 0.299f * pr + 0.587f * pg + 0.114f * pb;
                    diff = std::abs(pl - tL);
                    break;
                }
                default:
                    diff = 0.0f;
                    break;
            }

            float s = 0.0f;
            if (diff <= tolerance) {
                s = 255.0f;
            } else if (fuzzRange > 0.0f && diff <= tolerance + fuzzRange) {
                s = 255.0f * (1.0f - (diff - tolerance) / fuzzRange);
            } else {
                s = 0.0f;
            }

            int val = std::clamp(static_cast<int>(std::round(s * alphaFactor)), 0, 255);
            if (invert) {
                val = 255 - val;
            }

            maskLine[x] = static_cast<uint8_t>(val);
        }
    }

    return mask;
}

QPainterPath ColorRangeSelector::maskToPath(const QImage &mask) const {
    int W = mask.width();
    int H = mask.height();
    QPainterPath path;
    if (W <= 0 || H <= 0) return path;

    // 1. Build a binary grid from the mask (threshold at 50%)
    std::vector<uint8_t> grid(W * H, 0);
    for (int y = 0; y < H; ++y) {
        const uint8_t *line = mask.constScanLine(y);
        for (int x = 0; x < W; ++x) {
            if (line[x] > 127) grid[y * W + x] = 1;
        }
    }

    // Helper: is pixel inside the selection?
    auto inside = [&](int x, int y) -> bool {
        if (x < 0 || x >= W || y < 0 || y >= H) return false;
        return grid[y * W + x] != 0;
    };

    // 2. Quick check: is there any selected pixel?
    bool anySelected = false;
    for (int i = 0; i < W * H && !anySelected; ++i) {
        if (grid[i]) anySelected = true;
    }
    if (!anySelected) return path;

    // 3. Marching Squares contour tracing
    //    Pad the grid by 1 pixel on each side to handle border contours cleanly.
    int PW = W + 2;
    int PH = H + 2;
    auto paddedInside = [&](int px, int py) -> bool {
        int x = px - 1;
        int y = py - 1;
        return inside(x, y);
    };

    // Direction tables for marching squares
    // Cell corners:  TL(x,y)  TR(x+1,y)
    //                BL(x,y+1) BR(x+1,y+1)
    // Case index = TL*8 + TR*4 + BR*2 + BL*1

    struct Edge { float x1, y1, x2, y2; };

    // Collect all boundary edges
    std::vector<Edge> edges;
    edges.reserve(W * 4); // rough estimate

    for (int cy = 0; cy < PH - 1; ++cy) {
        for (int cx = 0; cx < PW - 1; ++cx) {
            bool tl = paddedInside(cx, cy);
            bool tr = paddedInside(cx + 1, cy);
            bool br = paddedInside(cx + 1, cy + 1);
            bool bl = paddedInside(cx, cy + 1);

            int caseIdx = (tl ? 8 : 0) | (tr ? 4 : 0) | (br ? 2 : 0) | (bl ? 1 : 0);
            if (caseIdx == 0 || caseIdx == 15) continue; // No boundary

            // Map back to original coordinates (subtract 1 for padding offset)
            float ox = cx - 1.0f;
            float oy = cy - 1.0f;


            // Edge midpoints in (x,y):
            float tmx = ox + 0.5f, tmy = oy;        // top edge midpoint
            float bmx = ox + 0.5f, bmy = oy + 1.0f;  // bottom edge midpoint
            float lmx = ox,        lmy = oy + 0.5f;  // left edge midpoint
            float rmx = ox + 1.0f, rmy = oy + 0.5f;  // right edge midpoint

            switch (caseIdx) {
                case 1:  edges.push_back({lmx, lmy, bmx, bmy}); break;
                case 2:  edges.push_back({bmx, bmy, rmx, rmy}); break;
                case 3:  edges.push_back({lmx, lmy, rmx, rmy}); break;
                case 4:  edges.push_back({tmx, tmy, rmx, rmy}); break;
                case 5:  edges.push_back({lmx, lmy, tmx, tmy}); edges.push_back({bmx, bmy, rmx, rmy}); break;
                case 6:  edges.push_back({tmx, tmy, bmx, bmy}); break;
                case 7:  edges.push_back({lmx, lmy, tmx, tmy}); break;
                case 8:  edges.push_back({tmx, tmy, lmx, lmy}); break;
                case 9:  edges.push_back({tmx, tmy, bmx, bmy}); break;
                case 10: edges.push_back({tmx, tmy, rmx, rmy}); edges.push_back({lmx, lmy, bmx, bmy}); break;
                case 11: edges.push_back({tmx, tmy, rmx, rmy}); break;
                case 12: edges.push_back({lmx, lmy, rmx, rmy}); break;
                case 13: edges.push_back({bmx, bmy, rmx, rmy}); break;
                case 14: edges.push_back({lmx, lmy, bmx, bmy}); break;
                default: break;
            }
        }
    }

    if (edges.empty()) return path;

    // 4. Chain edges into contours by matching endpoints
    //    Use a spatial hash to quickly find matching endpoints
    struct PtHash {
        size_t operator()(const std::pair<int,int> &p) const {
            return std::hash<long long>()(((long long)p.first << 32) | (unsigned int)p.second);
        }
    };

    // Quantize float coords to int keys (multiply by 2 to handle 0.5 increments)
    auto toKey = [](float x, float y) -> std::pair<int,int> {
        return {(int)std::round(x * 2.0f), (int)std::round(y * 2.0f)};
    };

    // Build adjacency: for each endpoint, list of (edge_index, which_end: 0=start, 1=end)
    std::unordered_multimap<std::pair<int,int>, std::pair<int,int>, PtHash> endpointMap;
    for (int i = 0; i < (int)edges.size(); ++i) {
        auto k1 = toKey(edges[i].x1, edges[i].y1);
        auto k2 = toKey(edges[i].x2, edges[i].y2);
        endpointMap.insert({k1, {i, 0}});
        endpointMap.insert({k2, {i, 1}});
    }

    std::vector<bool> usedEdge(edges.size(), false);

    // Trace contours
    std::vector<std::vector<QPointF>> contours;
    for (int startIdx = 0; startIdx < (int)edges.size(); ++startIdx) {
        if (usedEdge[startIdx]) continue;

        std::vector<QPointF> contour;
        int curIdx = startIdx;
        usedEdge[curIdx] = true;
        contour.push_back(QPointF(edges[curIdx].x1, edges[curIdx].y1));
        contour.push_back(QPointF(edges[curIdx].x2, edges[curIdx].y2));

        // Follow the chain from the end
        bool progress = true;
        while (progress) {
            progress = false;
            QPointF lastPt = contour.back();
            auto key = toKey(lastPt.x(), lastPt.y());
            auto range = endpointMap.equal_range(key);
            for (auto it = range.first; it != range.second; ++it) {
                int eIdx = it->second.first;
                int eEnd = it->second.second;
                if (usedEdge[eIdx]) continue;

                usedEdge[eIdx] = true;
                // Add the other endpoint
                if (eEnd == 0) {
                    contour.push_back(QPointF(edges[eIdx].x2, edges[eIdx].y2));
                } else {
                    contour.push_back(QPointF(edges[eIdx].x1, edges[eIdx].y1));
                }
                progress = true;
                break;
            }
        }

        if (contour.size() >= 3) {
            contours.push_back(std::move(contour));
        }
    }

    // 5. Simplify contours using Ramer-Douglas-Peucker and build the QPainterPath
    std::function<void(const std::vector<QPointF>&, int, int, float, std::vector<bool>&)> rdp;
    rdp = [&rdp](const std::vector<QPointF>& pts, int start, int end, float epsilon, std::vector<bool>& keep) {
        if (end - start < 2) return;
        float maxDist = 0;
        int maxIdx = start;
        QPointF a = pts[start], b = pts[end];
        float dx = b.x() - a.x(), dy = b.y() - a.y();
        float lenSq = dx * dx + dy * dy;

        for (int i = start + 1; i < end; ++i) {
            float dist;
            if (lenSq < 1e-10f) {
                float ex = pts[i].x() - a.x(), ey = pts[i].y() - a.y();
                dist = std::sqrt(ex * ex + ey * ey);
            } else {
                float t = ((pts[i].x() - a.x()) * dx + (pts[i].y() - a.y()) * dy) / lenSq;
                t = std::max(0.0f, std::min(1.0f, t));
                float px = a.x() + t * dx - pts[i].x();
                float py = a.y() + t * dy - pts[i].y();
                dist = std::sqrt(px * px + py * py);
            }
            if (dist > maxDist) { maxDist = dist; maxIdx = i; }
        }
        if (maxDist > epsilon) {
            keep[maxIdx] = true;
            rdp(pts, start, maxIdx, epsilon, keep);
            rdp(pts, maxIdx, end, epsilon, keep);
        }
    };

    float epsilon = 1.0f; // Simplification tolerance in pixels

    for (auto &contour : contours) {
        if (contour.size() < 3) continue;

        // Simplify
        std::vector<bool> keep(contour.size(), false);
        keep[0] = true;
        keep[contour.size() - 1] = true;
        rdp(contour, 0, (int)contour.size() - 1, epsilon, keep);

        std::vector<QPointF> simplified;
        for (int i = 0; i < (int)contour.size(); ++i) {
            if (keep[i]) simplified.push_back(contour[i]);
        }

        if (simplified.size() < 3) simplified = contour; // Keep original if too few points

        // Add to path
        path.moveTo(simplified[0]);
        for (size_t i = 1; i < simplified.size(); ++i) {
            path.lineTo(simplified[i]);
        }
        path.closeSubpath();
    }

    return path;
}

QImage ColorRangeSelector::previewMask(const QImage &image, const QImage &mask) const {
    int W = image.width();
    int H = image.height();

    QImage preview(W, H, QImage::Format_RGBA8888);
    if (W <= 0 || H <= 0) return preview;

    for (int y = 0; y < H; ++y) {
        const QRgb *srcLine = reinterpret_cast<const QRgb*>(image.constScanLine(y));
        const uint8_t *maskLine = mask.constScanLine(y);
        QRgb *destLine = reinterpret_cast<QRgb*>(preview.scanLine(y));

        for (int x = 0; x < W; ++x) {
            QRgb pix = srcLine[x];
            int pr = qRed(pix);
            int pg = qGreen(pix);
            int pb = qBlue(pix);
            int pa = qAlpha(pix);

            float maskFactor = maskLine[x] / 255.0f;
            
            // Selected pixels remain normal, unselected are darkened at 50% opacity/light
            float factor = 0.5f + 0.5f * maskFactor;
            
            int nr = static_cast<int>(pr * factor);
            int ng = static_cast<int>(pg * factor);
            int nb = static_cast<int>(pb * factor);

            destLine[x] = qRgba(nr, ng, nb, pa);
        }
    }

    return preview;
}

} // namespace artflow
