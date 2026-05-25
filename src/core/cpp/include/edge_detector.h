#pragma once

#include <QImage>
#include <QPointF>
#include <vector>

namespace artflow {

class EdgeDetector {
public:
    EdgeDetector();
    ~EdgeDetector();

    // Precomputes gradient map from an image using 3x3 Sobel kernels
    void computeGradientMap(const QImage &image);

    // Snaps the given coordinates to the nearby pixel with the strongest gradient
    QPointF findEdgePoint(const QPointF &point, int searchRadius) const;

    // Generates a path adhering to high gradient edges between points A and B
    std::vector<QPointF> traceEdgePath(const QPointF &pA, const QPointF &pB) const;

    // Setters / Getters
    float edgeSensitivity() const { return m_edgeSensitivity; }
    void setEdgeSensitivity(float value) { m_edgeSensitivity = value; }

    int searchRadius() const { return m_searchRadius; }
    void setSearchRadius(int value) { m_searchRadius = value; }

    int pathResolution() const { return m_pathResolution; }
    void setPathResolution(int value) { m_pathResolution = value; }

private:
    float m_edgeSensitivity;
    int m_searchRadius;
    int m_pathResolution;

    int m_width;
    int m_height;
    std::vector<float> m_gradientMap; // Magnitude map [0.0 - 1.0]

    // Helper to get gradient value safely
    float getGradientAt(int x, int y) const;
};

} // namespace artflow
