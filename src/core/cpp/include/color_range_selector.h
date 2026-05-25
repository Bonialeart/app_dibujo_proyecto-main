#pragma once

#include <QImage>
#include <QColor>
#include <QPainterPath>

namespace artflow {

class ColorRangeSelector {
public:
    ColorRangeSelector();
    ~ColorRangeSelector();

    // Generates a grayscale mask (8-bit) representing the selected region
    QImage selectByColor(const QImage &image, const QColor &targetColor,
                         float tolerance, int channelMode, float fuzziness,
                         bool invert) const;

    // Converts the grayscale mask into a QPainterPath using a robust span-based approach
    QPainterPath maskToPath(const QImage &mask) const;

    // Generates an RGBA preview of the mask overlay
    QImage previewMask(const QImage &image, const QImage &mask) const;
};

} // namespace artflow
