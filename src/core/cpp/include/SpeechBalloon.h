#pragma once

#include <QPointF>
#include <QPainterPath>

namespace artflow {

class SpeechBalloon {
public:
    SpeechBalloon() = default;
    SpeechBalloon(float cx, float cy, float rx, float ry,
                  const QPointF &tailStart1, const QPointF &tailStart2,
                  const QPointF &tailControl1, const QPointF &tailControl2,
                  const QPointF &tailEnd)
        : cx(cx), cy(cy), rx(rx), ry(ry),
          tailStart1(tailStart1), tailStart2(tailStart2),
          tailControl1(tailControl1), tailControl2(tailControl2),
          tailEnd(tailEnd) {}

    ~SpeechBalloon() = default;

    float cx = 100.0f;
    float cy = 100.0f;
    float rx = 80.0f;
    float ry = 50.0f;

    QPointF tailStart1;
    QPointF tailStart2;
    QPointF tailControl1;
    QPointF tailControl2;
    QPointF tailEnd;

    QPainterPath generateVectorPath() const {
        QPainterPath ellipsePath;
        ellipsePath.addEllipse(cx - rx, cy - ry, rx * 2.0f, ry * 2.0f);

        QPainterPath tailPath;
        tailPath.moveTo(tailStart1);
        tailPath.cubicTo(tailControl1, tailControl2, tailEnd);
        tailPath.lineTo(tailStart2);
        tailPath.closeSubpath();

        // High-performance vector Boolean addition via Qt's native united()
        return ellipsePath.united(tailPath);
    }
};

} // namespace artflow
