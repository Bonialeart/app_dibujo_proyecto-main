#include "edge_detector.h"
#include <cmath>
#include <queue>
#include <algorithm>
#include <QColor>
#include <QDebug>

namespace artflow {

EdgeDetector::EdgeDetector()
    : m_edgeSensitivity(0.85f),
      m_searchRadius(12),
      m_pathResolution(1),
      m_width(0),
      m_height(0) {}

EdgeDetector::~EdgeDetector() {}

void EdgeDetector::computeGradientMap(const QImage &image) {
    m_width = image.width();
    m_height = image.height();
    m_gradientMap.assign(m_width * m_height, 0.0f);

    if (m_width <= 2 || m_height <= 2) {
        return;
    }

    std::vector<float> luminance(m_width * m_height, 0.0f);

    // Compute luminance map
    if (image.format() == QImage::Format_RGBA8888 || image.format() == QImage::Format_RGBA8888_Premultiplied) {
        for (int y = 0; y < m_height; ++y) {
            const uint8_t *line = image.constScanLine(y);
            int idx = y * m_width;
            for (int x = 0; x < m_width; ++x) {
                float r = line[4 * x + 0] / 255.0f;
                float g = line[4 * x + 1] / 255.0f;
                float b = line[4 * x + 2] / 255.0f;
                luminance[idx + x] = 0.299f * r + 0.587f * g + 0.114f * b;
            }
        }
    } else {
        for (int y = 0; y < m_height; ++y) {
            int idx = y * m_width;
            for (int x = 0; x < m_width; ++x) {
                QRgb rgb = image.pixel(x, y);
                float r = qRed(rgb) / 255.0f;
                float g = qGreen(rgb) / 255.0f;
                float b = qBlue(rgb) / 255.0f;
                luminance[idx + x] = 0.299f * r + 0.587f * g + 0.114f * b;
            }
        }
    }

    float maxGrad = 0.0f;
    std::vector<float> rawG(m_width * m_height, 0.0f);

    // Apply Sobel kernels
    for (int y = 1; y < m_height - 1; ++y) {
        int idx = y * m_width;
        int idxPrev = (y - 1) * m_width;
        int idxNext = (y + 1) * m_width;

        for (int x = 1; x < m_width - 1; ++x) {
            // Sobel X Kernel:
            // -1  0  1
            // -2  0  2
            // -1  0  1
            float gx = 
                -1.0f * luminance[idxPrev + (x - 1)] + 1.0f * luminance[idxPrev + (x + 1)] +
                -2.0f * luminance[idx + (x - 1)]     + 2.0f * luminance[idx + (x + 1)] +
                -1.0f * luminance[idxNext + (x - 1)] + 1.0f * luminance[idxNext + (x + 1)];

            // Sobel Y Kernel:
            // -1 -2 -1
            //  0  0  0
            //  1  2  1
            float gy =
                -1.0f * luminance[idxPrev + (x - 1)] - 2.0f * luminance[idxPrev + x] - 1.0f * luminance[idxPrev + (x + 1)] +
                 1.0f * luminance[idxNext + (x - 1)] + 2.0f * luminance[idxNext + x] + 1.0f * luminance[idxNext + (x + 1)];

            float val = std::sqrt(gx * gx + gy * gy);
            rawG[idx + x] = val;
            if (val > maxGrad) {
                maxGrad = val;
            }
        }
    }

    // Normalize magnitude map to [0.0, 1.0]
    if (maxGrad > 0.001f) {
        for (int i = 0; i < m_width * m_height; ++i) {
            m_gradientMap[i] = rawG[i] / maxGrad;
        }
    }
}

float EdgeDetector::getGradientAt(int x, int y) const {
    if (x < 0 || x >= m_width || y < 0 || y >= m_height) return 0.0f;
    return m_gradientMap[y * m_width + x];
}

QPointF EdgeDetector::findEdgePoint(const QPointF &point, int searchRadius) const {
    if (m_gradientMap.empty() || m_width <= 0 || m_height <= 0) return point;

    int px = std::clamp(static_cast<int>(std::round(point.x())), 0, m_width - 1);
    int py = std::clamp(static_cast<int>(std::round(point.y())), 0, m_height - 1);

    int bestX = px;
    int bestY = py;
    float maxGrad = -1.0f;

    for (int dy = -searchRadius; dy <= searchRadius; ++dy) {
        int ny = py + dy;
        if (ny < 0 || ny >= m_height) continue;
        int idx = ny * m_width;
        for (int dx = -searchRadius; dx <= searchRadius; ++dx) {
            int nx = px + dx;
            if (nx < 0 || nx >= m_width) continue;

            float grad = m_gradientMap[idx + nx];
            if (grad > maxGrad) {
                maxGrad = grad;
                bestX = nx;
                bestY = ny;
            }
        }
    }

    return QPointF(bestX, bestY);
}

std::vector<QPointF> EdgeDetector::traceEdgePath(const QPointF &pA, const QPointF &pB) const {
    std::vector<QPointF> path;
    if (m_gradientMap.empty() || m_width <= 2 || m_height <= 2) {
        path.push_back(pA);
        path.push_back(pB);
        return path;
    }

    int ax = std::clamp(static_cast<int>(std::round(pA.x())), 0, m_width - 1);
    int ay = std::clamp(static_cast<int>(std::round(pA.y())), 0, m_height - 1);
    int bx = std::clamp(static_cast<int>(std::round(pB.x())), 0, m_width - 1);
    int by = std::clamp(static_cast<int>(std::round(pB.y())), 0, m_height - 1);

    // Bounding window with padding to allow the path to swing around, but stay fast
    const int padding = 64;
    int minX = std::max(0, std::min(ax, bx) - padding);
    int maxX = std::min(m_width - 1, std::max(ax, bx) + padding);
    int minY = std::max(0, std::min(ay, by) - padding);
    int maxY = std::min(m_height - 1, std::max(ay, by) + padding);

    int W = maxX - minX + 1;
    int H = maxY - minY + 1;

    if (W <= 0 || H <= 0) {
        path.push_back(pA);
        path.push_back(pB);
        return path;
    }

    std::vector<float> dists(W * H, 1e9f);
    std::vector<int> parents(W * H, -1);
    std::vector<bool> visited(W * H, false);

    int startIdx = (ay - minY) * W + (ax - minX);
    int targetIdx = (by - minY) * W + (bx - minX);

    dists[startIdx] = 0.0f;

    // Dijkstra's queue: {cost, local_index}
    typedef std::pair<float, int> Element;
    std::priority_queue<Element, std::vector<Element>, std::greater<Element>> pq;
    pq.push({0.0f, startIdx});

    while (!pq.empty()) {
        auto top = pq.top();
        pq.pop();
        float d = top.first;
        int u = top.second;

        if (u == targetIdx) break;
        if (visited[u]) continue;
        visited[u] = true;

        int ux = u % W + minX;
        int uy = u / W + minY;

        // Traverse 8 neighbors
        for (int dy = -1; dy <= 1; ++dy) {
            for (int dx = -1; dx <= 1; ++dx) {
                if (dx == 0 && dy == 0) continue;
                int nx = ux + dx;
                int ny = uy + dy;
                if (nx < minX || nx > maxX || ny < minY || ny > maxY) continue;

                int v = (ny - minY) * W + (nx - minX);
                if (visited[v]) continue;

                float grad = m_gradientMap[ny * m_width + nx];
                float moveDist = (dx != 0 && dy != 0) ? 1.4142f : 1.0f;
                
                // Strong edges (higher gradient) decrease the cost
                float edgeFactor = 1.0f - grad * m_edgeSensitivity;
                float cost = (edgeFactor * 1.5f + 0.08f) * moveDist;

                if (dists[u] + cost < dists[v]) {
                    dists[v] = dists[u] + cost;
                    parents[v] = u;
                    pq.push({dists[v], v});
                }
            }
        }
    }

    // Reconstruct the path
    int curr = targetIdx;
    while (curr != -1) {
        int cx = curr % W + minX;
        int cy = curr / W + minY;
        path.push_back(QPointF(cx, cy));
        curr = parents[curr];
    }
    std::reverse(path.begin(), path.end());

    // Respect pathResolution
    if (m_pathResolution > 1 && path.size() > 2) {
        std::vector<QPointF> downsampled;
        downsampled.push_back(path.front());
        for (size_t i = 1; i < path.size() - 1; ++i) {
            if (i % m_pathResolution == 0) {
                downsampled.push_back(path[i]);
            }
        }
        downsampled.push_back(path.back());
        return downsampled;
    }

    return path;
}

} // namespace artflow
