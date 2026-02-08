#include "brush_engine.h"
#include <algorithm>
#include <cmath>

namespace artflow {

BrushEngine::BrushEngine() {}

void BrushEngine::paintStroke(QPainter *painter, const QPointF &lastPoint,
                              const QPointF &currentPoint, float pressure,
                              const BrushSettings &settings) {
  if (!painter)
    return;

  // 1. Calcular Dinámicas (La lógica que tenías en Python)
  // Si la presión es 0 (ej. mouse), usamos 0.5 o 1.0 por defecto
  float effectivePressure = (pressure > 0.0f) ? pressure : 0.5f;

  if (!settings.dynamicsEnabled) {
    effectivePressure = 1.0f;
  }

  if (settings.type == BrushSettings::Type::Eraser) {
    painter->setCompositionMode(QPainter::CompositionMode_Clear);
  } else {
    painter->setCompositionMode(QPainter::CompositionMode_SourceOver);
  }

  // Adaptación: La presión afecta el tamaño (logarítmico o lineal)
  float currentSize =
      settings.size * (settings.sizeByPressure ? effectivePressure : 1.0f);
  // Evitar tamaños invisibles
  if (currentSize < 1.0f)
    currentSize = 1.0f;

  // Adaptación: La presión afecta la opacidad
  float currentOpacity =
      settings.opacity *
      (settings.opacityByPressure ? effectivePressure : 1.0f);
  // Limitar opacidad máxima
  if (currentOpacity > 1.0f)
    currentOpacity = 1.0f;

  // 2. Renderizado (Rendering)
  // Caso A: Pincel Duro (Hard Brush) CONSTANTE - Usamos QPen para rendimiento.
  // SOLO si el tamaño NO varía por presión. Si varía, usamos interpolación
  // (abajo).
  if (settings.hardness > 0.9f && !settings.sizeByPressure) {
    QPen pen;
    pen.setColor(settings.color);
    pen.setWidthF(currentSize);
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::RoundJoin);

    painter->setOpacity(currentOpacity);
    painter->setPen(pen);
    painter->drawLine(lastPoint, currentPoint);
  }
  // Caso B: Pincel Suave/Aerógrafo (Soft Brush) - Usamos QRadialGradient
  // interpolado
  else {
    // Necesitamos interpolar pasos entre los dos puntos para que no se vean
    // "bolas" separadas
    float distance = std::hypot(currentPoint.x() - lastPoint.x(),
                                currentPoint.y() - lastPoint.y());
    // El paso (step) debe ser una fracción del tamaño del pincel (ej. 10% del
    // tamaño)
    float stepSize = std::max(1.0f, currentSize * settings.spacing);

    int steps = static_cast<int>(distance / stepSize);

    for (int i = 0; i <= steps; ++i) {
      float t = (steps > 0) ? (float)i / steps : 0.0f;
      QPointF interpolatedPoint = lastPoint + (currentPoint - lastPoint) * t;

      // Renderizamos un "sello" suave en cada paso
      paintSoftStamp(painter, interpolatedPoint, currentSize, currentOpacity,
                     settings.color, settings.hardness);
    }
  }
}

void BrushEngine::paintSoftStamp(QPainter *painter, const QPointF &point,
                                 float size, float opacity, const QColor &color,
                                 float hardness) {
  painter->setPen(Qt::NoPen);
  painter->setOpacity(opacity);

  QRadialGradient gradient(point, size / 2.0);

  // Color central (sólido)
  QColor centerColor = color;
  gradient.setColorAt(0.0, centerColor);

  // Inicio del desvanecimiento (basado en dureza)
  gradient.setColorAt(hardness, centerColor);

  // Borde exterior (transparente)
  QColor outerColor = color;
  outerColor.setAlpha(0);
  gradient.setColorAt(1.0, outerColor);

  QBrush brush(gradient);
  painter->setBrush(brush);

  // Dibujar el círculo del gradiente
  painter->drawEllipse(point, size / 2.0, size / 2.0);
}

} // namespace artflow
