#include "color_range_selector.h"
#include <QRegion>
#include <QRect>
#include <cmath>
#include <algorithm>

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
    QPainterPath path;
    QRegion region;
    int W = mask.width();
    int H = mask.height();

    // Optimize: merge contiguous spans of pixels horizontally
    for (int y = 0; y < H; ++y) {
        const uint8_t *line = mask.constScanLine(y);
        int startX = -1;
        for (int x = 0; x < W; ++x) {
            if (line[x] > 127) { // 50% threshold
                if (startX == -1) {
                    startX = x;
                }
            } else {
                if (startX != -1) {
                    region = region.united(QRect(startX, y, x - startX, 1));
                    startX = -1;
                }
            }
        }
        if (startX != -1) {
            region = region.united(QRect(startX, y, W - startX, 1));
        }
    }

    path.addRegion(region);
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
