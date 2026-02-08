#include "TestCanvas.h"
#include <QDebug>
#include <QPainter>
#include <algorithm>
#include <cmath>


TestCanvas::TestCanvas(QQuickItem *parent)
    : QQuickPaintedItem(parent), m_lastPos(QPointF()) {
  setAcceptTouchEvents(false);
  setAcceptedMouseButtons(Qt::LeftButton);
  // Inicializar puntos por defecto (lineal)
  m_rawPoints = {0.25, 0.25, 0.75, 0.75};
  updateLUT(0.25, 0.25, 0.75, 0.75);
}

void TestCanvas::paint(QPainter *painter) {
  if (m_buffer.isNull() || m_buffer.width() != width() ||
      m_buffer.height() != height()) {
    m_buffer = QImage(width(), height(), QImage::Format_RGBA8888);
    m_buffer.fill(Qt::transparent);
  }

  // Dibujamos el buffer acumulado
  painter->drawImage(0, 0, m_buffer);
}

void TestCanvas::drawStoke(const QPointF &pos, float pressure) {
  if (m_lastPos.isNull()) {
    m_lastPos = pos;
    return;
  }

  QPainter p(&m_buffer);
  p.setRenderHint(QPainter::Antialiasing);

  // Aplicar la curva de presión
  float adjustedPressure = applyPressureCurve(pressure);

  // Grosor varía con presión (Test visual)
  float size = 2.0f + (adjustedPressure * 10.0f);
  float opacity = 0.5f + (adjustedPressure * 0.5f);

  QPen pen;
  pen.setColor(QColor(255, 255, 255)); // Blanco
  pen.setWidthF(size);
  pen.setCapStyle(Qt::RoundCap);
  p.setOpacity(opacity);
  p.setPen(pen);
  p.drawLine(m_lastPos, pos);

  m_lastPos = pos;
  update(); // Redraw item
}

void TestCanvas::clear() {
  if (!m_buffer.isNull()) {
    m_buffer.fill(Qt::transparent);
    update();
  }
}

void TestCanvas::setCurvePoints(const QVariantList &points) {
  if (points != m_rawPoints && points.size() >= 4) {
    m_rawPoints = points;
    float x1 = points[0].toFloat();
    float y1 = points[1].toFloat();
    float x2 = points[2].toFloat();
    float y2 = points[3].toFloat();
    updateLUT(x1, y1, x2, y2);
    emit curvePointsChanged(); // Oops, signal naming in macro?
  }
}

// Generar Tabla de Búsqueda (LUT) basada en Bezier Cúbica
// P0=(0,0), P1=(x1,y1), P2=(x2,y2), P3=(1,1)
void TestCanvas::updateLUT(float x1, float y1, float x2, float y2) {
  m_lut.assign(1024, 0.0f);

  // Muestrear curva paramétrica t=[0..1]
  int lastIdx = 0;
  float lastY = 0.0f;

  for (int i = 0; i <= 1000; i++) {
    float t = i / 1000.0f;
    float u = 1.0f - t;

    // Coordenada X (Input Pressure)
    // B(t) = (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3*P3
    // P0=0, P3=1
    float bx = 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t;

    // Coordenada Y (Output Pressure)
    float by = 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t;

    // Mapear X a índice [0..1023]
    int idx = std::clamp((int)(bx * 1023), 0, 1023);

    // Rellenar huecos (interpolación lineal simple para la LUT)
    if (idx > lastIdx) {
      float step = (by - lastY) / (idx - lastIdx);
      for (int k = lastIdx; k <= idx; k++) {
        m_lut[k] = lastY + step * (k - lastIdx);
      }
    } else {
      m_lut[idx] = by; // Overwrite if t moves backwards (loops) - simplified
    }

    lastIdx = idx;
    lastY = by;
  }

  // Rellenar final si faltó
  for (int k = lastIdx; k < 1024; k++)
    m_lut[k] = 1.0f;
}

float TestCanvas::applyPressureCurve(float input) {
  if (input <= 0.0f)
    return 0.0f;
  if (input >= 1.0f)
    return 1.0f;
  int idx = (int)(input * 1023);
  return m_lut[idx];
}

void TestCanvas::mousePressEvent(QMouseEvent *event) {
  m_lastPos = event->position();
  float p = 1.0f;
  if (!event->points().isEmpty())
    p = event->points().first().pressure();
  if (p <= 0.0f)
    p = 1.0f; // Default mouse
  drawStoke(event->position(), p);
}

void TestCanvas::mouseMoveEvent(QMouseEvent *event) {
  float p = 1.0f;
  if (!event->points().isEmpty())
    p = event->points().first().pressure();
  if (p <= 0.0f)
    p = 1.0f;
  drawStoke(event->position(), p);
}

void TestCanvas::mouseReleaseEvent(QMouseEvent *event) {
  m_lastPos = QPointF();
}
