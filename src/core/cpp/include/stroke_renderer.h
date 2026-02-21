#ifndef STROKE_RENDERER_H
#define STROKE_RENDERER_H

#include <QColor>
#include <QOpenGLBuffer>
#include <QOpenGLExtraFunctions>
#include <QOpenGLShaderProgram>
#include <QOpenGLVertexArrayObject>
#include <vector>

namespace artflow {

class StrokeRenderer : protected QOpenGLExtraFunctions {
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
  void renderStroke(
      float x, float y, float size, float pressure, float hardness,
      const QColor &color, int type, int width, int height,
      // Grain texture
      uint32_t grainTexId, bool hasGrain, float grainScale,
      float grainIntensity,
      // Tip texture
      uint32_t tipTexId, bool hasTip, float tipRotation,
      // Dynamics
      float tilt, float velocity, float flow,
      // Wet Mix Engine
      uint32_t canvasTexId, float wetness, float dilution, float smudge,
      // New Watercolor params
      float bleed = 0.0f, float absorptionRate = 0.0f, float dryingTime = 0.0f,
      float wetOnWetMultiplier = 1.0f, float granulation = 0.0f,
      float pigmentFlow = 1.0f, float staining = 0.0f, float separation = 0.0f,
      bool bloomEnabled = false, float bloomIntensity = 0.0f,
      float bloomRadius = 0.0f, float bloomThreshold = 0.0f,
      bool edgeDarkeningEnabled = false, float edgeDarkeningIntensity = 0.0f,
      float edgeDarkeningWidth = 0.0f, bool textureRevealEnabled = false,
      float textureRevealIntensity = 0.0f,
      float textureRevealPressureInfluence = 0.0f,
      // Oil Paint Parameters
      float mixing = 0.5f, float loading = 1.0f, float depletionRate = 0.0f,
      bool dirtyMixing = false, float colorPickup = 0.0f,
      bool blendOnly = false, bool scrapeThrough = false,
      // Impasto
      bool impastoEnabled = false, float impastoDepth = 0.0f,
      float impastoShine = 0.0f, float impastoTextureStrength = 0.0f,
      float impastoEdgeBuildup = 0.0f, bool impastoDirectionalRidges = false,
      float impastoSmoothing = 0.0f, bool impastoPreserveExisting = false,
      // Bristles
      bool bristlesEnabled = false, int bristleCount = 1,
      float bristleStiffness = 0.5f, float bristleClumping = 0.0f,
      float bristleFanSpread = 0.0f, float bristleIndividualVariation = 0.0f,
      bool bristleDryBrushEffect = false, float bristleSoftness = 0.0f,
      float bristlePointTaper = 0.0f,
      // Smudge (Advanced)
      float smudgeStrength = 0.0f, float smudgePressureInfluence = 0.0f,
      float smudgeLength = 0.0f, float smudgeGaussianBlur = 0.0f,
      bool smudgeSmear = false,
      // Canvas Interaction
      float canvasAbsorption = 0.0f, bool canvasSkipValleys = false,
      float canvasCatchPeaks = 0.0f,
      // Oil Color Dynamics
      float temperatureShift = 0.0f, float brokenColor = 0.0f,
      // Mode
      bool isEraser = false);

  struct DabInstance {
    float x, y;
    float size;
    float rotation;
    float colorR, colorG, colorB, colorA;
  };

  void renderStrokeInstanced(
      const std::vector<DabInstance> &dabs, float pressure, float hardness,
      int type, int width, int height,
      // Grain texture
      uint32_t grainTexId, bool hasGrain, float grainScale,
      float grainIntensity,
      // Tip texture
      uint32_t tipTexId, bool hasTip,
      // Dynamics
      float tilt, float velocity, float flow,
      // Wet Mix Engine
      uint32_t canvasTexId, float wetness, float dilution, float smudge,
      // New Watercolor params
      float bleed = 0.0f, float absorptionRate = 0.0f, float dryingTime = 0.0f,
      float wetOnWetMultiplier = 1.0f, float granulation = 0.0f,
      float pigmentFlow = 1.0f, float staining = 0.0f, float separation = 0.0f,
      bool bloomEnabled = false, float bloomIntensity = 0.0f,
      float bloomRadius = 0.0f, float bloomThreshold = 0.0f,
      bool edgeDarkeningEnabled = false, float edgeDarkeningIntensity = 0.0f,
      float edgeDarkeningWidth = 0.0f, bool textureRevealEnabled = false,
      float textureRevealIntensity = 0.0f,
      float textureRevealPressureInfluence = 0.0f,
      // Oil Paint Parameters
      float mixing = 0.5f, float loading = 1.0f, float depletionRate = 0.0f,
      bool dirtyMixing = false, float colorPickup = 0.0f,
      bool blendOnly = false, bool scrapeThrough = false,
      // Impasto
      bool impastoEnabled = false, float impastoDepth = 0.0f,
      float impastoShine = 0.0f, float impastoTextureStrength = 0.0f,
      float impastoEdgeBuildup = 0.0f, bool impastoDirectionalRidges = false,
      float impastoSmoothing = 0.0f, bool impastoPreserveExisting = false,
      // Bristles
      bool bristlesEnabled = false, int bristleCount = 1,
      float bristleStiffness = 0.5f, float bristleClumping = 0.0f,
      float bristleFanSpread = 0.0f, float bristleIndividualVariation = 0.0f,
      bool bristleDryBrushEffect = false, float bristleSoftness = 0.0f,
      float bristlePointTaper = 0.0f,
      // Smudge (Advanced)
      float smudgeStrength = 0.0f, float smudgePressureInfluence = 0.0f,
      float smudgeLength = 0.0f, float smudgeGaussianBlur = 0.0f,
      bool smudgeSmear = false,
      // Canvas Interaction
      float canvasAbsorption = 0.0f, bool canvasSkipValleys = false,
      float canvasCatchPeaks = 0.0f,
      // Oil Color Dynamics
      float temperatureShift = 0.0f, float brokenColor = 0.0f,
      // Mode
      bool isEraser = false);

  void setClippingEnabled(bool enabled) { m_clippingEnabled = enabled; }

private:
  QOpenGLShaderProgram *m_program;
  QOpenGLVertexArrayObject m_vao;
  QOpenGLBuffer m_vbo;
  QOpenGLBuffer m_instanceVbo;

  bool m_clippingEnabled = false;

  // Texture IDs manageable by this class
  unsigned int m_brushTextureId = 0;
  unsigned int m_paperTextureId = 0;

  QMatrix4x4 m_projection;
  int m_viewportWidth = 0;
  int m_viewportHeight = 0;
};

} // namespace artflow

#endif // STROKE_RENDERER_H
