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
std::vector<BezierSegment> fitBezierChain(const std::vector<VPoint2D>& points, float tolerance = 2.0f);

} // namespace artflow
