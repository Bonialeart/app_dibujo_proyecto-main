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

  // Frame Management
  void beginFrame(int width, int height);
  void endFrame();

  int viewportWidth() const { return m_viewportWidth; }
  int viewportHeight() const { return m_viewportHeight; }

  // Basic Rendering
  void drawDab(float x, float y, float size, float rotation, float r, float g,
               float b, float a, float hardness, float pressure, int mode,
               int brushType = 0, float wetness = 0.0f);

  // Advanced Rendering (Ping-Pong)
  void drawDabPingPong(float x, float y, float size, float rotation, float r,
                       float g, float b, float a, float hardness,
                       float pressure, int mode, int brushType, float wetness,
                       unsigned int canvasTex, unsigned int wetMap);

  // Texture Management
  void setBrushTip(const unsigned char *data, int width, int height);
  void setPaperTexture(const unsigned char *data, int width, int height);

  // Premium rendering with dual texture support
  void renderStroke(float x, float y, float size, float pressure,
                    float hardness, const QColor &color, int type, int width,
                    int height,
                    // Grain texture
                    uint32_t grainTexId, bool hasGrain, float grainScale,
                    float grainIntensity,
                    // Tip texture
                    uint32_t tipTexId, bool hasTip, float tipRotation,
                    // Dynamics
                    float tilt, float velocity, float flow,
                    // Wet Mix Engine
                    uint32_t canvasTexId, float wetness, float dilution,
                    float smudge,
                    // Mode
                    bool isEraser = false);

private:
  QOpenGLShaderProgram *m_program;
  QOpenGLVertexArrayObject m_vao;
  QOpenGLBuffer m_vbo;

  // Texture IDs manageable by this class
  unsigned int m_brushTextureId = 0;
  unsigned int m_paperTextureId = 0;

  QMatrix4x4 m_projection;
  int m_viewportWidth = 0;
  int m_viewportHeight = 0;
};

} // namespace artflow

#endif // STROKE_RENDERER_H
