#ifndef TESTCANVAS_H
#define TESTCANVAS_H

#include <QImage>
#include <QMouseEvent>
#include <QPainter>
#include <QPointF>
#include <QQuickPaintedItem>
#include <QVariant>
#include <vector>

class TestCanvas : public QQuickPaintedItem {
  Q_OBJECT
  Q_PROPERTY(QVariantList curvePoints READ curvePoints WRITE setCurvePoints
                 NOTIFY curvePointsChanged)

public:
  explicit TestCanvas(QQuickItem *parent = nullptr);
  void paint(QPainter *painter) override;

  QVariantList curvePoints() const { return m_rawPoints; }
  Q_INVOKABLE void setCurvePoints(const QVariantList &points);

  // Limpia el área de prueba
  Q_INVOKABLE void clear();

signals:
  void curvePointsChanged();

protected:
  void mousePressEvent(QMouseEvent *event) override;
  void mouseMoveEvent(QMouseEvent *event) override;
  void mouseReleaseEvent(QMouseEvent *event) override;

private:
  QImage m_buffer;
  QPointF m_lastPos;
  std::vector<float> m_lut; // Look-Up Table para presión
  QVariantList m_rawPoints;

  void drawStoke(const QPointF &pos, float pressure);
  void updateLUT(float p1x, float p1y, float p2x, float p2y);
  float applyPressureCurve(float input);
};

#endif // TESTCANVAS_H
