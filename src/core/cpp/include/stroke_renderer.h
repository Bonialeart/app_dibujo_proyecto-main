#ifndef STROKE_RENDERER_H
#define STROKE_RENDERER_H

#include <QColor>
#include <QOpenGLBuffer>
#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>
#include <QOpenGLVertexArrayObject>

namespace artflow {

class StrokeRenderer : protected QOpenGLFunctions {
public:
  StrokeRenderer();
  ~StrokeRenderer();

  void initialize();

  // Render a single stroke point with premium shaders
  void renderStroke(float x, float y, float size, float pressure,
                    float hardness, const QColor &color, int type, int width,
                    int height, uint32_t grainTexId, bool useTex,
                    float texScale, float texIntensity, float tilt,
                    float velocity, uint32_t canvasTexId, float wetness,
                    float dilution, float smudge);

private:
  QOpenGLShaderProgram *m_program;
  QOpenGLVertexArrayObject m_vao;
  QOpenGLBuffer m_vbo;
};

} // namespace artflow

#endif // STROKE_RENDERER_H
