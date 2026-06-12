#pragma once

#include "vector_types.h"
#include <vector>
#include <QPointF>

namespace artflow {

// Evaluate a cubic bezier segment at t in [0, 1]
VPoint2D evalBezier(const BezierSegment& segment, float t);

// Evaluate the derivative (tangent vector) of a bezier segment at t
VPoint2D evalBezierDerivative(const BezierSegment& segment, float t);

// Subdivide a bezier segment at t into two segments
std::pair<BezierSegment, BezierSegment> subdivide(const BezierSegment& segment, float t);

// Flatten a bezier segment to a list of points based on a flatness tolerance
std::vector<VPoint2D> flattenToPolyline(const BezierSegment& segment, float tolerance = 0.5f);

struct Intersection {
    int segIdxA;
    float tA;
    int segIdxB;
    float tB;
    QPointF pt;
};

// Find all intersections between strokeA and strokeB
std::vector<Intersection> findIntersections(const VectorStroke& strokeA, const VectorStroke& strokeB);

// Split a stroke at segment index and parameter t, returning two strokes.
// The new strokes will copy properties of the original (color, globalWidth, etc.)
std::pair<VectorStroke, VectorStroke> splitStrokeAt(const VectorStroke& stroke, int segIdx, float t);

struct StrokeDistanceResult {
    int segIdx = -1;
    float t = 0.0f;
    float distance = 1e9f;
    VPoint2D closestPoint;
};

// Calculate the minimum distance from a point to a stroke
StrokeDistanceResult distanceToStroke(const VPoint2D& point, const VectorStroke& stroke);

// Fit a series of input points into a chain of Bezier segments using Philip Schneider's algorithm
std::vector<BezierSegment> fitBezierChain(const std::vector<VPoint2D>& points, float tolerance = 4.0f, float epsilon = 2.0f);

// In-place low-pass smoothing of raw input points (position and pressure).
// Endpoints stay fixed. Removes stylus/touch sensor jitter so curve fitting
// sees the intended shape instead of the noise.
void smoothStrokePoints(std::vector<VPoint2D>& points, int iterations = 2);

// Ramer-Douglas-Peucker simplification (iterative, pressure-aware).
// `pressureWeight` converts pressure deviation into spatial distance so points
// that carry width dynamics are preserved even when geometrically collinear.
std::vector<VPoint2D> rdpSimplify(const std::vector<VPoint2D>& points, float epsilon,
                                  float pressureWeight = 0.0f);

// Real-time input decimation while the user is drawing freehand.
// Appends `pt` to `buffer` only when it adds information:
//  - drops points closer than `minDistance` (merging their pressure),
//  - slides the last point forward when the path keeps going straight,
//  - keeps points on direction or pressure changes.
// Returns true if the buffer was modified.
bool appendStrokePointFiltered(std::vector<VPoint2D>& buffer, const VPoint2D& pt,
                               float minDistance,
                               float maxAngleDeviationDeg = 4.0f,
                               float pressureTolerance = 0.06f);

// Flatten a whole stroke to a polyline with per-point pressure.
// Width interpolation data (widthStart/widthEnd) is folded into pressure.
std::vector<VPoint2D> flattenStrokePolyline(const VectorStroke& stroke, float tolerance = 1.0f);

} // namespace artflow
