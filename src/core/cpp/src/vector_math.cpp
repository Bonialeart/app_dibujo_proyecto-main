#include "vector_math.h"
#include <cmath>
#include <algorithm>
#include <QDebug>

namespace artflow {

// Helper: Vector dot product and length
static float dot(const VPoint2D& a, const VPoint2D& b) {
    return a.x * b.x + a.y * b.y;
}

static float len(const VPoint2D& v) {
    return std::sqrt(v.x * v.x + v.y * v.y);
}

static VPoint2D normalize(const VPoint2D& v) {
    float l = len(v);
    if (l < 1e-6f) return {0, 0, 0};
    return {v.x / l, v.y / l, 0};
}

VPoint2D evalBezier(const BezierSegment& segment, float t) {
    float u = 1.0f - t;
    float tt = t * t;
    float uu = u * u;
    float uuu = uu * u;
    float ttt = tt * t;

    VPoint2D p;
    p.x = uuu * segment.p0.x + 3.0f * uu * t * segment.cp1.x + 3.0f * u * tt * segment.cp2.x + ttt * segment.p3.x;
    p.y = uuu * segment.p0.y + 3.0f * uu * t * segment.cp1.y + 3.0f * u * tt * segment.cp2.y + ttt * segment.p3.y;
    // Interpolate pressure linearly based on curve parameter
    p.pressure = u * segment.p0.pressure + t * segment.p3.pressure;
    return p;
}

VPoint2D evalBezierDerivative(const BezierSegment& segment, float t) {
    float u = 1.0f - t;
    VPoint2D d;
    d.x = 3.0f * u * u * (segment.cp1.x - segment.p0.x) +
          6.0f * u * t * (segment.cp2.x - segment.cp1.x) +
          3.0f * t * t * (segment.p3.x - segment.cp2.x);
    d.y = 3.0f * u * u * (segment.cp1.y - segment.p0.y) +
          6.0f * u * t * (segment.cp2.y - segment.cp1.y) +
          3.0f * t * t * (segment.p3.y - segment.cp2.y);
    d.pressure = 0.0f;
    return d;
}

std::pair<BezierSegment, BezierSegment> subdivide(const BezierSegment& segment, float t) {
    float u = 1.0f - t;

    // De Casteljau step 1
    VPoint2D p01;
    p01.x = u * segment.p0.x + t * segment.cp1.x;
    p01.y = u * segment.p0.y + t * segment.cp1.y;

    VPoint2D p12;
    p12.x = u * segment.cp1.x + t * segment.cp2.x;
    p12.y = u * segment.cp1.y + t * segment.cp2.y;

    VPoint2D p23;
    p23.x = u * segment.cp2.x + t * segment.p3.x;
    p23.y = u * segment.cp2.y + t * segment.p3.y;

    // De Casteljau step 2
    VPoint2D p012;
    p012.x = u * p01.x + t * p12.x;
    p012.y = u * p01.y + t * p12.y;

    VPoint2D p123;
    p123.x = u * p12.x + t * p23.x;
    p123.y = u * p12.y + t * p23.y;

    // De Casteljau step 3 (point on curve)
    VPoint2D p0123;
    p0123.x = u * p012.x + t * p123.x;
    p0123.y = u * p012.y + t * p123.y;

    // Pressure & width interpolation
    float midPressure = u * segment.p0.pressure + t * segment.p3.pressure;
    float midWidth = u * segment.widthStart + t * segment.widthEnd;

    // Assign temporary pressures
    p01.pressure = u * segment.p0.pressure + t * segment.cp1.pressure;
    p23.pressure = u * segment.cp2.pressure + t * segment.p3.pressure;
    p012.pressure = u * p01.pressure + t * p12.pressure;
    p123.pressure = u * p12.pressure + t * p23.pressure;
    p0123.pressure = midPressure;

    BezierSegment left;
    left.p0 = segment.p0;
    left.cp1 = p01;
    left.cp2 = p012;
    left.p3 = p0123;
    left.widthStart = segment.widthStart;
    left.widthEnd = midWidth;

    BezierSegment right;
    right.p0 = p0123;
    right.cp1 = p123;
    right.cp2 = p23;
    right.p3 = segment.p3;
    right.widthStart = midWidth;
    right.widthEnd = segment.widthEnd;

    return {left, right};
}

// Maximum subdivision depth: bounds both stack usage and point count on
// degenerate curves (critical on Android where stack sizes are smaller).
static constexpr int kMaxFlattenDepth = 16;

static void flattenRecursive(const BezierSegment& segment, float tolerance, std::vector<VPoint2D>& points, int depth = 0) {
    float dx = segment.p3.x - segment.p0.x;
    float dy = segment.p3.y - segment.p0.y;
    float lenSq = dx * dx + dy * dy;
    float len = std::sqrt(lenSq);

    float d1 = 0.0f;
    float d2 = 0.0f;
    if (len > 1e-4f) {
        d1 = std::abs((segment.cp1.y - segment.p0.y) * dx - (segment.cp1.x - segment.p0.x) * dy) / len;
        d2 = std::abs((segment.cp2.y - segment.p0.y) * dx - (segment.cp2.x - segment.p0.x) * dy) / len;
    } else {
        d1 = std::sqrt((segment.cp1.x - segment.p0.x)*(segment.cp1.x - segment.p0.x) + (segment.cp1.y - segment.p0.y)*(segment.cp1.y - segment.p0.y));
        d2 = std::sqrt((segment.cp2.x - segment.p0.x)*(segment.cp2.x - segment.p0.x) + (segment.cp2.y - segment.p0.y)*(segment.cp2.y - segment.p0.y));
    }

    if (d1 + d2 < tolerance || depth >= kMaxFlattenDepth) {
        points.push_back(segment.p3);
    } else {
        auto halves = subdivide(segment, 0.5f);
        flattenRecursive(halves.first, tolerance, points, depth + 1);
        flattenRecursive(halves.second, tolerance, points, depth + 1);
    }
}

std::vector<VPoint2D> flattenToPolyline(const BezierSegment& segment, float tolerance) {
    std::vector<VPoint2D> points;
    points.push_back(segment.p0);
    flattenRecursive(segment, tolerance, points);
    return points;
}

// FlatPoint contains a 2D point and the bezier coordinates from which it originated
struct FlatPoint {
    VPoint2D pt;
    int segIdx;
    float t;
};

static void flattenRecursiveWithT(const BezierSegment& segment, float tStart, float tEnd, int segIdx, float tolerance, std::vector<FlatPoint>& points, int depth = 0) {
    float dx = segment.p3.x - segment.p0.x;
    float dy = segment.p3.y - segment.p0.y;
    float lenSq = dx * dx + dy * dy;
    float len = std::sqrt(lenSq);
    
    float d1 = 0.0f;
    float d2 = 0.0f;
    if (len > 1e-4f) {
        d1 = std::abs((segment.cp1.y - segment.p0.y) * dx - (segment.cp1.x - segment.p0.x) * dy) / len;
        d2 = std::abs((segment.cp2.y - segment.p0.y) * dx - (segment.cp2.x - segment.p0.x) * dy) / len;
    } else {
        d1 = std::sqrt((segment.cp1.x - segment.p0.x)*(segment.cp1.x - segment.p0.x) + (segment.cp1.y - segment.p0.y)*(segment.cp1.y - segment.p0.y));
        d2 = std::sqrt((segment.cp2.x - segment.p0.x)*(segment.cp2.x - segment.p0.x) + (segment.cp2.y - segment.p0.y)*(segment.cp2.y - segment.p0.y));
    }

    if (d1 + d2 < tolerance || depth >= kMaxFlattenDepth) {
        FlatPoint fp;
        fp.pt = segment.p3;
        fp.segIdx = segIdx;
        fp.t = tEnd;
        points.push_back(fp);
    } else {
        float tMid = (tStart + tEnd) * 0.5f;
        auto halves = subdivide(segment, 0.5f);
        flattenRecursiveWithT(halves.first, tStart, tMid, segIdx, tolerance, points, depth + 1);
        flattenRecursiveWithT(halves.second, tMid, tEnd, segIdx, tolerance, points, depth + 1);
    }
}

static std::vector<FlatPoint> flattenStroke(const VectorStroke& stroke, float tolerance = 1.0f) {
    std::vector<FlatPoint> points;
    if (stroke.segments.empty()) return points;
    
    FlatPoint first;
    first.pt = stroke.segments[0].p0;
    first.segIdx = 0;
    first.t = 0.0f;
    points.push_back(first);
    
    for (size_t i = 0; i < stroke.segments.size(); ++i) {
        flattenRecursiveWithT(stroke.segments[i], 0.0f, 1.0f, static_cast<int>(i), tolerance, points);
    }
    return points;
}

static bool intersectSegments(const QPointF& a1, const QPointF& a2, const QPointF& b1, const QPointF& b2, float& tA_out, float& tB_out, QPointF& pt_out) {
    float det = (a2.x() - a1.x()) * (b1.y() - b2.y()) - (b1.x() - b2.x()) * (a2.y() - a1.y());
    if (std::abs(det) < 1e-6f) return false;

    float t = ((b1.x() - a1.x()) * (b1.y() - b2.y()) - (b1.x() - b2.x()) * (b1.y() - a1.y())) / det;
    float u = ((a2.x() - a1.x()) * (b1.y() - a1.y()) - (b1.x() - a1.x()) * (a2.y() - a1.y())) / det;

    if (t >= 0.0f && t <= 1.0f && u >= 0.0f && u <= 1.0f) {
        tA_out = t;
        tB_out = u;
        pt_out = a1 + t * (a2 - a1);
        return true;
    }
    return false;
}

std::vector<Intersection> findIntersections(const VectorStroke& strokeA, const VectorStroke& strokeB) {
    std::vector<Intersection> results;
    
    if (!strokeA.cachedBounds.intersects(strokeB.cachedBounds)) {
        return results;
    }

    auto ptsA = flattenStroke(strokeA, 1.5f);
    auto ptsB = flattenStroke(strokeB, 1.5f);

    if (ptsA.size() < 2 || ptsB.size() < 2) return results;

    for (size_t i = 0; i < ptsA.size() - 1; ++i) {
        QPointF a1(ptsA[i].pt.x, ptsA[i].pt.y);
        QPointF a2(ptsA[i+1].pt.x, ptsA[i+1].pt.y);
        
        QRectF rectA = QRectF(a1, a2).normalized();
        rectA.adjust(-1, -1, 1, 1);

        for (size_t j = 0; j < ptsB.size() - 1; ++j) {
            QPointF b1(ptsB[j].pt.x, ptsB[j].pt.y);
            QPointF b2(ptsB[j+1].pt.x, ptsB[j+1].pt.y);
            
            QRectF rectB = QRectF(b1, b2).normalized();
            if (!rectA.intersects(rectB)) continue;

            float tSegA, tSegB;
            QPointF pt;
            if (intersectSegments(a1, a2, b1, b2, tSegA, tSegB, pt)) {
                Intersection inter;
                inter.pt = pt;
                
                if (ptsA[i].segIdx == ptsA[i+1].segIdx) {
                    inter.segIdxA = ptsA[i].segIdx;
                    inter.tA = ptsA[i].t + tSegA * (ptsA[i+1].t - ptsA[i].t);
                } else {
                    if (tSegA < 0.5f) {
                        inter.segIdxA = ptsA[i].segIdx;
                        inter.tA = ptsA[i].t;
                    } else {
                        inter.segIdxA = ptsA[i+1].segIdx;
                        inter.tA = ptsA[i+1].t;
                    }
                }

                if (ptsB[j].segIdx == ptsB[j+1].segIdx) {
                    inter.segIdxB = ptsB[j].segIdx;
                    inter.tB = ptsB[j].t + tSegB * (ptsB[j+1].t - ptsB[j].t);
                } else {
                    if (tSegB < 0.5f) {
                        inter.segIdxB = ptsB[j].segIdx;
                        inter.tB = ptsB[j].t;
                    } else {
                        inter.segIdxB = ptsB[j+1].segIdx;
                        inter.tB = ptsB[j+1].t;
                    }
                }
                
                bool duplicate = false;
                for (const auto& existing : results) {
                    if (existing.segIdxA == inter.segIdxA && std::abs(existing.tA - inter.tA) < 0.05f &&
                        existing.segIdxB == inter.segIdxB && std::abs(existing.tB - inter.tB) < 0.05f) {
                        duplicate = true;
                        break;
                    }
                }
                if (!duplicate) {
                    results.push_back(inter);
                }
            }
        }
    }
    return results;
}

std::pair<VectorStroke, VectorStroke> splitStrokeAt(const VectorStroke& stroke, int segIdx, float t) {
    if (segIdx < 0 || segIdx >= static_cast<int>(stroke.segments.size())) {
        return {stroke, VectorStroke()};
    }

    auto halves = subdivide(stroke.segments[segIdx], t);

    // Copy every style property (including the captured brush preset) so the
    // fragments keep rendering exactly like the original stroke.
    auto copyStyle = [&stroke](VectorStroke& dst) {
        dst.color = stroke.color;
        dst.opacity = stroke.opacity;
        dst.globalWidth = stroke.globalWidth;
        dst.tipTextureName = stroke.tipTextureName;
        dst.spacing = stroke.spacing;
        dst.hardness = stroke.hardness;
        dst.useTexture = stroke.useTexture;
        dst.textureName = stroke.textureName;
        dst.isEraser = stroke.isEraser;
        dst.brush = stroke.brush;
    };

    VectorStroke firstPart;
    copyStyle(firstPart);

    for (int i = 0; i < segIdx; ++i) {
        firstPart.segments.push_back(stroke.segments[i]);
    }
    firstPart.segments.push_back(halves.first);
    firstPart.recalcBounds();

    VectorStroke secondPart;
    copyStyle(secondPart);

    secondPart.segments.push_back(halves.second);
    for (size_t i = segIdx + 1; i < stroke.segments.size(); ++i) {
        secondPart.segments.push_back(stroke.segments[i]);
    }
    secondPart.recalcBounds();

    return {firstPart, secondPart};
}

StrokeDistanceResult distanceToStroke(const VPoint2D& point, const VectorStroke& stroke) {
    StrokeDistanceResult bestResult;
    bestResult.distance = 1e9f;

    auto pts = flattenStroke(stroke, 1.5f);
    if (pts.size() < 2) return bestResult;

    for (size_t i = 0; i < pts.size() - 1; ++i) {
        VPoint2D p1 = pts[i].pt;
        VPoint2D p2 = pts[i+1].pt;

        float dx = p2.x - p1.x;
        float dy = p2.y - p1.y;
        float lenSq = dx * dx + dy * dy;
        
        float tSeg = 0.0f;
        if (lenSq > 1e-6f) {
            tSeg = ((point.x - p1.x) * dx + (point.y - p1.y) * dy) / lenSq;
            if (tSeg < 0.0f) tSeg = 0.0f;
            else if (tSeg > 1.0f) tSeg = 1.0f;
        }
        
        VPoint2D closest;
        closest.x = p1.x + tSeg * dx;
        closest.y = p1.y + tSeg * dy;
        closest.pressure = p1.pressure + tSeg * (p2.pressure - p1.pressure);

        float distSq = (point.x - closest.x) * (point.x - closest.x) + (point.y - closest.y) * (point.y - closest.y);
        float dist = std::sqrt(distSq);

        if (dist < bestResult.distance) {
            bestResult.distance = dist;
            bestResult.closestPoint = closest;
            if (pts[i].segIdx == pts[i+1].segIdx) {
                bestResult.segIdx = pts[i].segIdx;
                bestResult.t = pts[i].t + tSeg * (pts[i+1].t - pts[i].t);
            } else {
                if (tSeg < 0.5f) {
                    bestResult.segIdx = pts[i].segIdx;
                    bestResult.t = pts[i].t;
                } else {
                    bestResult.segIdx = pts[i+1].segIdx;
                    bestResult.t = pts[i+1].t;
                }
            }
        }
    }
    return bestResult;
}

// ---------------------------------------------------------
// Philip Schneider's Curve Fitting Algorithm Implementation
// ---------------------------------------------------------

// End tangents averaged over up to 3 neighbors (1/k falloff): a single
// adjacent-point difference is dominated by sensor noise on dense input.
static VPoint2D computeLeftTangent(const std::vector<VPoint2D>& points, int end) {
    int last = static_cast<int>(points.size()) - 1;
    VPoint2D acc = {0, 0, 0};
    for (int k = 1; k <= 3 && end + k <= last; ++k) {
        float w = 1.0f / k;
        acc.x += (points[end + k].x - points[end].x) * w;
        acc.y += (points[end + k].y - points[end].y) * w;
    }
    return normalize(acc);
}

static VPoint2D computeRightTangent(const std::vector<VPoint2D>& points, int end) {
    VPoint2D acc = {0, 0, 0};
    for (int k = 1; k <= 3 && end - k >= 0; ++k) {
        float w = 1.0f / k;
        acc.x += (points[end - k].x - points[end].x) * w;
        acc.y += (points[end - k].y - points[end].y) * w;
    }
    return normalize(acc);
}

static std::vector<float> chordLengthParameterize(const std::vector<VPoint2D>& points, int first, int last) {
    std::vector<float> u(last - first + 1);
    u[0] = 0.0f;
    for (int i = first + 1; i <= last; ++i) {
        float dx = points[i].x - points[i-1].x;
        float dy = points[i].y - points[i-1].y;
        u[i - first] = u[i - 1 - first] + std::sqrt(dx * dx + dy * dy);
    }
    float total = u[last - first];
    if (total > 1e-6f) {
        for (size_t i = 0; i < u.size(); ++i) {
            u[i] /= total;
        }
    } else {
        for (size_t i = 0; i < u.size(); ++i) {
            u[i] = static_cast<float>(i) / (u.size() - 1);
        }
    }
    return u;
}

// Evaluate bezier basis functions
static float B0(float u) { return (1.0f - u) * (1.0f - u) * (1.0f - u); }
static float B1(float u) { return 3.0f * u * (1.0f - u) * (1.0f - u); }
static float B2(float u) { return 3.0f * u * u * (1.0f - u); }
static float B3(float u) { return u * u * u; }

// Newton-Raphson parameter refinement helper
static float findRoot(const BezierSegment& seg, const VPoint2D& p, float u) {
    VPoint2D q_u = evalBezier(seg, u);
    VPoint2D qp_u = evalBezierDerivative(seg, u);
    
    // Second derivative
    VPoint2D qpp_u;
    qpp_u.x = 6.0f * (1.0f - u) * (seg.cp2.x - 2.0f * seg.cp1.x + seg.p0.x) + 6.0f * u * (seg.p3.x - 2.0f * seg.cp2.x + seg.cp1.x);
    qpp_u.y = 6.0f * (1.0f - u) * (seg.cp2.y - 2.0f * seg.cp1.y + seg.p0.y) + 6.0f * u * (seg.p3.y - 2.0f * seg.cp2.y + seg.cp1.y);

    float numerator = (q_u.x - p.x) * qp_u.x + (q_u.y - p.y) * qp_u.y;
    float denominator = qp_u.x * qp_u.x + qp_u.y * qp_u.y + (q_u.x - p.x) * qpp_u.x + (q_u.y - p.y) * qpp_u.y;
    
    if (std::abs(denominator) < 1e-6f) return u;
    return u - (numerator / denominator);
}

static std::vector<float> reparameterize(const BezierSegment& seg, const std::vector<VPoint2D>& points, int first, int last, const std::vector<float>& u) {
    std::vector<float> uPrime(last - first + 1);
    for (int i = first; i <= last; ++i) {
        uPrime[i - first] = findRoot(seg, points[i], u[i - first]);
        if (uPrime[i - first] < 0.0f) uPrime[i - first] = 0.0f;
        if (uPrime[i - first] > 1.0f) uPrime[i - first] = 1.0f;
    }
    return uPrime;
}

// Generate Bezier segment with tangent constraints
static BezierSegment generateBezier(const std::vector<VPoint2D>& points, int first, int last, const std::vector<float>& uPrime, const VPoint2D& tHat1, const VPoint2D& tHat2) {
    int nPts = last - first + 1;
    BezierSegment seg;
    seg.p0 = points[first];
    seg.p3 = points[last];

    // Setup matrices
    float c11 = 0.0f, c12 = 0.0f, c22 = 0.0f;
    float X1 = 0.0f, X2 = 0.0f;

    for (int i = 0; i < nPts; ++i) {
        float u = uPrime[i];
        float b0 = B0(u), b1 = B1(u), b2 = B2(u), b3 = B3(u);
        
        VPoint2D a1 = {tHat1.x * b1, tHat1.y * b1, 0};
        VPoint2D a2 = {tHat2.x * b2, tHat2.y * b2, 0};

        c11 += dot(a1, a1);
        c12 += dot(a1, a2);
        c22 += dot(a2, a2);

        VPoint2D tmp = {
            points[first + i].x - (points[first].x * b0 + points[first].x * b1 + points[last].x * b2 + points[last].x * b3),
            points[first + i].y - (points[first].y * b0 + points[first].y * b1 + points[last].y * b2 + points[last].y * b3),
            0
        };

        X1 += dot(a1, tmp);
        X2 += dot(a2, tmp);
    }

    float det = c11 * c22 - c12 * c12;
    float alpha_l = 0.0f;
    float alpha_r = 0.0f;

    if (std::abs(det) > 1e-6f) {
        alpha_l = (X1 * c22 - X2 * c12) / det;
        alpha_r = (c11 * X2 - c12 * X1) / det;
    }

    // Heuristics for alpha
    float dist = std::sqrt((points[last].x - points[first].x)*(points[last].x - points[first].x) + (points[last].y - points[first].y)*(points[last].y - points[first].y));
    if (alpha_l < 1e-4f || alpha_r < 1e-4f || alpha_l > dist * 2.0f || alpha_r > dist * 2.0f) {
        alpha_l = dist / 3.0f;
        alpha_r = dist / 3.0f;
    }

    seg.cp1 = {points[first].x + tHat1.x * alpha_l, points[first].y + tHat1.y * alpha_l, points[first].pressure + 0.33f * (points[last].pressure - points[first].pressure)};
    seg.cp2 = {points[last].x + tHat2.x * alpha_r, points[last].y + tHat2.y * alpha_r, points[first].pressure + 0.66f * (points[last].pressure - points[first].pressure)};
    
    // Average adjacent pressures/widths
    seg.widthStart = points[first].pressure;
    seg.widthEnd = points[last].pressure;

    return seg;
}

// Recursive fit helper
static void fitRecursive(const std::vector<VPoint2D>& points, int first, int last, const VPoint2D& tHat1, const VPoint2D& tHat2, float tolerance, std::vector<BezierSegment>& result) {
    int nPts = last - first + 1;

    if (nPts == 2) {
        float dx = points[last].x - points[first].x;
        float dy = points[last].y - points[first].y;
        float dist = std::sqrt(dx * dx + dy * dy);
        BezierSegment seg;
        seg.p0 = points[first];
        seg.p3 = points[last];
        seg.cp1 = {points[first].x + tHat1.x * (dist / 3.0f), points[first].y + tHat1.y * (dist / 3.0f), points[first].pressure};
        seg.cp2 = {points[last].x + tHat2.x * (dist / 3.0f), points[last].y + tHat2.y * (dist / 3.0f), points[last].pressure};
        seg.widthStart = points[first].pressure;
        seg.widthEnd = points[last].pressure;
        result.push_back(seg);
        return;
    }

    // Parameterize
    auto u = chordLengthParameterize(points, first, last);
    
    // Fit curve
    auto seg = generateBezier(points, first, last, u, tHat1, tHat2);

    // Find max error
    float maxError = 0.0f;
    int splitPoint = first + 1;
    for (int i = first + 1; i < last; ++i) {
        VPoint2D p = evalBezier(seg, u[i - first]);
        float dx = p.x - points[i].x;
        float dy = p.y - points[i].y;
        float err = dx * dx + dy * dy;
        if (err > maxError) {
            maxError = err;
            splitPoint = i;
        }
    }

    maxError = std::sqrt(maxError);
    if (maxError < tolerance) {
        result.push_back(seg);
        return;
    }

    // Iterative Newton-Raphson reparameterization: refine the parameter
    // values and refit several times before giving up and splitting. This is
    // what keeps an 'S' at 3-5 segments instead of splitting into dozens.
    if (maxError < tolerance * 4.0f) {
        std::vector<float> uPrime = u;
        for (int iter = 0; iter < 4; ++iter) {
            uPrime = reparameterize(seg, points, first, last, uPrime);
            seg = generateBezier(points, first, last, uPrime, tHat1, tHat2);
            maxError = 0.0f;
            for (int i = first + 1; i < last; ++i) {
                VPoint2D p = evalBezier(seg, uPrime[i - first]);
                float dx = p.x - points[i].x;
                float dy = p.y - points[i].y;
                float err = dx * dx + dy * dy;
                if (err > maxError) {
                    maxError = err;
                    splitPoint = i;
                }
            }
            maxError = std::sqrt(maxError);
            if (maxError < tolerance) {
                result.push_back(seg);
                return;
            }
        }
    }

    // If still fails, split recursively at the worst point.
    // Center tangent convention (Schneider / Graphics Gems): right-end
    // tangents point BACKWARD along the curve (cp2 = p_last + tHat2 * alpha),
    // so the left half receives the backward direction and the right half its
    // negation (forward). Getting this sign wrong inverts the handles at
    // every split, the error never converges, and the fitter shatters the
    // stroke into hundreds of kinked micro-segments.
    // The tangent is averaged over a small window to resist sensor noise.
    int lo = std::max(first, splitPoint - 3);
    int hi = std::min(last, splitPoint + 3);
    VPoint2D tHatMid = {
        points[lo].x - points[hi].x,
        points[lo].y - points[hi].y,
        0
    };
    tHatMid = normalize(tHatMid);
    VPoint2D tHatMidNeg = {-tHatMid.x, -tHatMid.y, 0};

    fitRecursive(points, first, splitPoint, tHat1, tHatMid, tolerance, result);
    fitRecursive(points, splitPoint, last, tHatMidNeg, tHat2, tolerance, result);
}

static float perpendicularDistance(const VPoint2D& p, const VPoint2D& lineStart, const VPoint2D& lineEnd) {
    float dx = lineEnd.x - lineStart.x;
    float dy = lineEnd.y - lineStart.y;
    float lenSq = dx * dx + dy * dy;
    if (lenSq < 1e-6f) {
        float kx = p.x - lineStart.x;
        float ky = p.y - lineStart.y;
        return std::sqrt(kx * kx + ky * ky);
    }
    return std::abs(dy * p.x - dx * p.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x) / std::sqrt(lenSq);
}

void smoothStrokePoints(std::vector<VPoint2D>& points, int iterations) {
    if (points.size() < 3) return;
    std::vector<VPoint2D> prev;
    for (int it = 0; it < iterations; ++it) {
        prev = points;
        for (size_t i = 1; i + 1 < points.size(); ++i) {
            points[i].x = 0.25f * prev[i - 1].x + 0.5f * prev[i].x + 0.25f * prev[i + 1].x;
            points[i].y = 0.25f * prev[i - 1].y + 0.5f * prev[i].y + 0.25f * prev[i + 1].y;
            points[i].pressure = 0.25f * prev[i - 1].pressure + 0.5f * prev[i].pressure +
                                 0.25f * prev[i + 1].pressure;
        }
    }
}

std::vector<VPoint2D> rdpSimplify(const std::vector<VPoint2D>& points, float epsilon,
                                  float pressureWeight) {
    if (points.size() < 3) return points;

    std::vector<bool> keep(points.size(), false);
    keep[0] = true;
    keep[points.size() - 1] = true;

    // Iterative RDP (explicit stack): long freehand strokes on Android would
    // otherwise risk deep recursion.
    std::vector<std::pair<int, int>> stack;
    stack.reserve(64);
    stack.push_back({0, static_cast<int>(points.size() - 1)});

    while (!stack.empty()) {
        auto [first, last] = stack.back();
        stack.pop_back();
        if (last <= first + 1) continue;

        const VPoint2D& lineStart = points[first];
        const VPoint2D& lineEnd = points[last];

        float chordX = lineEnd.x - lineStart.x;
        float chordY = lineEnd.y - lineStart.y;
        float chordLenSq = chordX * chordX + chordY * chordY;

        float maxDist = 0.0f;
        int splitIdx = first;

        for (int i = first + 1; i < last; ++i) {
            float dist = perpendicularDistance(points[i], lineStart, lineEnd);

            if (pressureWeight > 0.0f) {
                // Deviation of pressure vs. linear interpolation along the chord:
                // a point that encodes a width change is information, not noise.
                float t = 0.5f;
                if (chordLenSq > 1e-6f) {
                    t = ((points[i].x - lineStart.x) * chordX +
                         (points[i].y - lineStart.y) * chordY) / chordLenSq;
                    t = std::clamp(t, 0.0f, 1.0f);
                }
                float expectedP = lineStart.pressure + t * (lineEnd.pressure - lineStart.pressure);
                dist += std::abs(points[i].pressure - expectedP) * pressureWeight;
            }

            if (dist > maxDist) {
                maxDist = dist;
                splitIdx = i;
            }
        }

        if (maxDist > epsilon) {
            keep[splitIdx] = true;
            stack.push_back({first, splitIdx});
            stack.push_back({splitIdx, last});
        }
    }

    std::vector<VPoint2D> result;
    result.reserve(points.size() / 4 + 2);
    for (size_t i = 0; i < points.size(); ++i) {
        if (keep[i]) {
            result.push_back(points[i]);
        }
    }
    return result;
}

bool appendStrokePointFiltered(std::vector<VPoint2D>& buffer, const VPoint2D& pt,
                               float minDistance,
                               float maxAngleDeviationDeg,
                               float pressureTolerance) {
    if (buffer.empty()) {
        buffer.push_back(pt);
        return true;
    }

    VPoint2D& last = buffer.back();
    float dx = pt.x - last.x;
    float dy = pt.y - last.y;
    float distSq = dx * dx + dy * dy;

    if (distSq < minDistance * minDistance) {
        // Too close: merge instead of appending, keeping the strongest pressure
        // so quick pressure peaks are not lost.
        if (pt.pressure > last.pressure) {
            last.pressure = pt.pressure;
        }
        return false;
    }

    if (buffer.size() >= 2) {
        const VPoint2D& prev = buffer[buffer.size() - 2];
        float d1x = last.x - prev.x;
        float d1y = last.y - prev.y;
        float d2x = pt.x - prev.x;
        float d2y = pt.y - prev.y;
        float l1 = std::sqrt(d1x * d1x + d1y * d1y);
        float l2 = std::sqrt(d2x * d2x + d2y * d2y);

        if (l1 > 1e-5f && l2 > 1e-5f) {
            float cosA = (d1x * d2x + d1y * d2y) / (l1 * l2);
            float cosThreshold = std::cos(maxAngleDeviationDeg * 3.14159265f / 180.0f);
            // Bounded-error slide: besides a small angle, the point being
            // absorbed must sit within a sub-pixel band of the new chord.
            // An angle-only test eats gentle arcs step by step and turns them
            // into straight lines; this keeps the drawn shape faithful.
            float perpDist = std::abs(d2x * (last.y - prev.y) - d2y * (last.x - prev.x)) / l2;
            float slideEps = minDistance * 0.3f;
            if (cosA > cosThreshold && perpDist < slideEps &&
                std::abs(pt.pressure - last.pressure) < pressureTolerance) {
                // Truly straight with stable pressure: slide the last point
                // forward instead of growing the buffer.
                last = pt;
                return true;
            }
        }
    }

    buffer.push_back(pt);
    return true;
}

std::vector<VPoint2D> flattenStrokePolyline(const VectorStroke& stroke, float tolerance) {
    std::vector<VPoint2D> out;
    if (stroke.segments.empty()) return out;

    auto flat = flattenStroke(stroke, tolerance);
    out.reserve(flat.size());
    int lastSegIdx = static_cast<int>(stroke.segments.size()) - 1;
    for (const auto& fp : flat) {
        const BezierSegment& seg = stroke.segments[std::clamp(fp.segIdx, 0, lastSegIdx)];
        float widthFactor = seg.widthStart + fp.t * (seg.widthEnd - seg.widthStart);
        VPoint2D p = fp.pt;
        p.pressure = std::clamp(p.pressure * widthFactor, 0.0f, 4.0f);
        out.push_back(p);
    }
    return out;
}

std::vector<BezierSegment> fitBezierChain(const std::vector<VPoint2D>& points, float tolerance, float epsilon) {
    std::vector<BezierSegment> result;
    if (points.size() < 2) return result;

    // 1. Low-pass smooth the raw input: stylus/touch sensors jitter both in
    //    position and (especially) pressure. Without this, the jitter exceeds
    //    the fit tolerance and the fitter splits a simple 'S' into dozens of
    //    kinked micro-segments ("faceted" strokes, 100+ nodes).
    std::vector<VPoint2D> smoothed = points;
    smoothStrokePoints(smoothed, 2);

    // 2. RDP decimation. Pressure deviation is weighted only moderately —
    //    it was just smoothed, so what survives is a real width change.
    std::vector<VPoint2D> simplified = rdpSimplify(smoothed, epsilon, epsilon * 1.5f);
    if (simplified.size() < 2) {
        simplified = smoothed;
    }

    // 3. Schneider curve fit: polyline -> few cubic Bezier segments with
    //    G1-continuous tangents at the joints.
    VPoint2D tHat1 = computeLeftTangent(simplified, 0);
    VPoint2D tHat2 = computeRightTangent(simplified, static_cast<int>(simplified.size() - 1));

    fitRecursive(simplified, 0, static_cast<int>(simplified.size() - 1), tHat1, tHat2, tolerance, result);
    return result;
}

} // namespace artflow
