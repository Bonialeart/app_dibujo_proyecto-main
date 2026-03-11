// =============================================================================
// watercolor_engine.h — Motor de Acuarela Profesional
// ArtFlow Studio
// =============================================================================
// Gestiona el pipeline completo de acuarela:
//   1. WetMap (FBO R16F): rastrea la humedad pixel a pixel en la capa activa
//   2. Cada vez que el pincel pinta: aplica Paint Dab (Mode 0) y deposita agua
//   3. Timer de difusión: cada ~100ms ejecuta Spread Wet (Mode 1) para
//      expandir pigmento y crear tide-marks
//   4. Timer de secado: cada ~3 segundos ejecuta Dry Step (Mode 2) para
//      reducir humedad progresivamente
//
// COMPORTAMIENTO OBSERVABLE (como Clip Studio / Procreate):
//   ✓ Pintar sobre zona pintada → se OSCURECE (acumulación de pigmento)
//   ✓ Zona húmeda → el nuevo pigmento se EXPANDE (spreading by wetness)
//   ✓ Borde de mancha → TIDE-MARK oscuro al irse secando
//   ✓ Dos colores húmedos se FUSIONAN (wet-on-wet mixing)
//   ✓ Con el tiempo la pintura SE SECA y ya no fluye
// =============================================================================
#pragma once

#include <QObject>
#include <QOpenGLFramebufferObject>
#include <QOpenGLShaderProgram>
#include <QOpenGLFunctions>
#include <QTimer>
#include <QImage>
#include <QColor>
#include <QPointF>
#include <memory>

class WatercolorEngine : public QObject {
    Q_OBJECT

public:
    // ── Parámetros del pincel de acuarela ──────────────────────────────────
    struct WatercolorParams {
        float wetness        = 0.65f; // Cuánta agua tiene el pincel
        float pigment        = 0.80f; // Concentración de pigmento
        float bleed          = 0.45f; // Expansión en zonas húmedas
        float dilution       = 0.50f; // Dilución (agua limpia)
        float granulation    = 0.35f; // Granulación del pigmento en el papel
        float absorption     = 0.30f; // Velocidad de absorción del papel
        float dryingRate     = 0.40f; // Velocidad de secado
        float edgeDarkening  = 0.60f; // Intensidad del tide-mark
        float grainIntensity = 0.50f; // Grano de papel
    };

    explicit WatercolorEngine(QObject *parent = nullptr);
    ~WatercolorEngine();

    // ── Ciclo de vida ─────────────────────────────────────────────────────
    // Llamar al inicio de una sesión de acuarela en la capa activa
    void beginSession(int canvasWidth, int canvasHeight,
                      QOpenGLFunctions *gl,
                      GLuint grainTextureId = 0);

    // Llamar al final del trazo para finalizar y transferir al buffer de capa
    void endSession();

    // ─────────────────────────────────────────────────────────────────────
    // Pintar un dab en la posición dada
    // dabFBO: FBO que contiene el dab renderizado por el motor de pinceles normal
    // canvasFBO: FBO ping-pong del canvas actual (resultado de pasadas anteriores)
    // ─────────────────────────────────────────────────────────────────────
    void paintDab(GLuint dabFBO,
                  GLuint canvasFBOin,
                  QOpenGLFramebufferObject *canvasFBOout,
                  const QColor &brushColor,
                  const WatercolorParams &params,
                  float pressure,
                  float flow);

    // ─────────────────────────────────────────────────────────────────────
    // Métodos de control del timer
    // Llamados internamente pero expuestos para control externo si se desea
    // ─────────────────────────────────────────────────────────────────────
    void setSpreadInterval(int ms)  { m_spreadTimer->setInterval(ms); }
    void setDryInterval(int ms)     { m_dryTimer->setInterval(ms);    }
    void setDryingRate(float rate)  { m_globalDryingRate = rate;       }

    // Retornar el FBO del WetMap para uso externo (composición visual opcional)
    GLuint wetMapTextureId() const;

    // ¿Hay zonas húmedas activas?
    bool hasActiveWetAreas() const { return m_hasWetAreas; }

    // Destruir los FBOs (llamar antes de cambiar de capa / canvas resize)
    void invalidate();

signals:
    // Se emite cuando el spread o dry ha sido ejecutado y el canvas debe redibujarse
    void wetMapUpdated();

private slots:
    void performSpread();
    void performDryStep();

private:
    // ── Internos ──────────────────────────────────────────────────────────
    void ensureFBOs(int w, int h);
    void ensureShader();
    void runPass(int mode,
                 GLuint sourceCanvasTex,
                 QOpenGLFramebufferObject *targetFBO,
                 const QColor &brushColor,
                 const WatercolorParams &params,
                 float pressure,
                 float flow);
    void renderFullscreenQuad();
    void initQuadGeometry();
    void updateWetMapDeposit(GLuint dabTexId,
                             const WatercolorParams &params,
                             float pressure,
                             float flow);


    // ── Estado ────────────────────────────────────────────────────────────
    int m_width  = 0;
    int m_height = 0;
    bool m_initialized = false;
    bool m_hasWetAreas = false;
    float m_globalDryingRate = 0.4f;

    // ── OpenGL ────────────────────────────────────────────────────────────
    QOpenGLFunctions *m_gl = nullptr;
    GLuint            m_grainTexId = 0;

    // WetMap: R16F — solo necesitamos R (humedad) y G (edad)
    // Dos FBOs para ping-pong del WetMap
    QOpenGLFramebufferObject *m_wetMapFBO_A = nullptr;
    QOpenGLFramebufferObject *m_wetMapFBO_B = nullptr;

    // Canvas intermedio para el pass de spread (no contaminar el ping-pong principal)
    QOpenGLFramebufferObject *m_spreadFBO = nullptr;

    // Shader único con uniform uMode para los 3 modos
    QOpenGLShaderProgram *m_shader = nullptr;

    // Quad geometry (VBO)
    GLuint m_quadVBO = 0;
    bool   m_quadReady = false;

    // ── Timers ────────────────────────────────────────────────────────────
    QTimer *m_spreadTimer = nullptr;  // Difusión: cada ~80ms mientras está húmedo
    QTimer *m_dryTimer    = nullptr;  // Secado: cada ~2.5s

    // Referencia al canvas FBO activo (actualizado en paintDab)
    GLuint m_lastCanvasTexId = 0;
    QOpenGLFramebufferObject *m_lastCanvasFBOOut = nullptr;
    WatercolorParams m_lastParams;
};
