// =============================================================================
// watercolor_engine.cpp — Implementación del Motor de Acuarela
// ArtFlow Studio
// =============================================================================
#include "watercolor_engine.h"
#include <QCoreApplication>
#include <QFile>
#include <QOpenGLContext>
#include <QOpenGLFramebufferObject>
#include <QDebug>
#include <cmath>

#ifndef GL_RG16F
#define GL_RG16F 0x822F
#endif
#ifndef GL_RGBA16F
#define GL_RGBA16F 0x881A
#endif

// ========================== QUAD VERTICES ====================================
// Fullscreen triangle-strip quad en NDC (-1..1) con UV (0..1)
static const float QUAD_VERTS[] = {
    // x      y     u     v
    -1.0f, -1.0f,  0.0f, 0.0f,
     1.0f, -1.0f,  1.0f, 0.0f,
    -1.0f,  1.0f,  0.0f, 1.0f,
     1.0f,  1.0f,  1.0f, 1.0f,
};

// ========================== CONSTRUCTOR / DESTRUCTOR =========================

WatercolorEngine::WatercolorEngine(QObject *parent)
    : QObject(parent)
{
    // Timer de difusión — se activa con cada dab y se detiene al secar
    m_spreadTimer = new QTimer(this);
    m_spreadTimer->setInterval(80);  // ~12 pasadas/s
    connect(m_spreadTimer, &QTimer::timeout, this, &WatercolorEngine::performSpread);

    // Timer de secado — se ejecuta con menor frecuencia
    m_dryTimer = new QTimer(this);
    m_dryTimer->setInterval(2500); // cada 2.5 segundos
    connect(m_dryTimer, &QTimer::timeout, this, &WatercolorEngine::performDryStep);
}

WatercolorEngine::~WatercolorEngine() {
    invalidate();
}

// ========================== CICLO DE VIDA ====================================

void WatercolorEngine::beginSession(int w, int h, QOpenGLFunctions *gl,
                                    GLuint grainTextureId)
{
    m_gl          = gl;
    m_grainTexId  = grainTextureId;
    m_hasWetAreas = false;
    m_wetBounds   = QRect();

    ensureFBOs(w, h);
    ensureShader();
    ensureAuxShaders();

    // Limpiar WetMap al inicio de sesión
    if (m_wetMapFBO_A) {
        m_wetMapFBO_A->bind();
        m_gl->glClearColor(0, 0, 0, 1);
        m_gl->glClear(GL_COLOR_BUFFER_BIT);
        m_wetMapFBO_A->release();
    }
    if (m_wetMapFBO_B) {
        m_wetMapFBO_B->bind();
        m_gl->glClearColor(0, 0, 0, 1);
        m_gl->glClear(GL_COLOR_BUFFER_BIT);
        m_wetMapFBO_B->release();
    }

    m_initialized = true;
}

void WatercolorEngine::endSession() {
    m_spreadTimer->stop();
    m_dryTimer->stop();
    m_hasWetAreas = false;
    // NO llamamos invalidate() aqui — los FBOs se reusan en la proxima sesion
}

void WatercolorEngine::startStroke() {
    // NOTA: m_wetBounds NO se resetea aquí — es la unión persistente de zonas
    // húmedas de la sesión y mantiene consistente el ping-pong del WetMap.
    if (!m_initialized || !m_wetMapFBO_A || !m_wetMapFBO_B || !m_gl) return;

    ensureAuxShaders();
    if (!m_ageShader) return;

    m_gl->glActiveTexture(GL_TEXTURE0);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_wetMapFBO_A->texture());

    m_ageShader->bind();
    m_ageShader->setUniformValue("uWetMapIn", 0);

    // Pase a pantalla completa: reescribe TODO el FBO B desde A, por lo que
    // no introduce divergencia entre los dos buffers del ping-pong.
    m_wetMapFBO_B->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND);
    renderFullscreenQuad();
    m_wetMapFBO_B->release();
    m_ageShader->release();

    std::swap(m_wetMapFBO_A, m_wetMapFBO_B);
}

// Crea los shaders auxiliares (envejecimiento y depósito de agua) como
// miembros del motor. Antes eran estáticos locales emparentados a `this`:
// al destruir un motor y crear otro, el puntero estático apuntaba a un
// programa ya destruido (use-after-free).
void WatercolorEngine::ensureAuxShaders() {
    static const char *kQuadVert =
        "#version 330 core\n"
        "layout(location=0)in vec2 p;\n"
        "layout(location=1)in vec2 t;\n"
        "out vec2 v;\n"
        "void main(){gl_Position=vec4(p,0,1);v=t;}\n";

    if (!m_ageShader) {
        m_ageShader = new QOpenGLShaderProgram(this);
        m_ageShader->addShaderFromSourceCode(QOpenGLShader::Vertex, kQuadVert);
        m_ageShader->addShaderFromSourceCode(QOpenGLShader::Fragment,
            "#version 330 core\n"
            "in vec2 v;\n"
            "out vec4 fragOut;\n"
            "uniform sampler2D uWetMapIn;\n"
            "void main(){\n"
            "  vec4 wet = texture(uWetMapIn, v);\n"
            "  // Si tiene humedad (>0.01), forzar la edad (G) a 1.0 (viejo)\n"
            "  float agedG = wet.r > 0.01 ? 1.0 : 0.0;\n"
            "  fragOut = vec4(wet.r, agedG, 0.0, 1.0);\n"
            "}\n");
        if (!m_ageShader->link()) {
            qWarning() << "WatercolorEngine: age shader link failed:" << m_ageShader->log();
            delete m_ageShader;
            m_ageShader = nullptr;
        }
    }

    if (!m_depositShader) {
        m_depositShader = new QOpenGLShaderProgram(this);
        m_depositShader->addShaderFromSourceCode(QOpenGLShader::Vertex, kQuadVert);
        m_depositShader->addShaderFromSourceCode(QOpenGLShader::Fragment,
            "#version 330 core\n"
            "in vec2 v;\n"
            "out vec4 fragOut;\n"
            "uniform sampler2D uWetMapIn;\n"
            "uniform sampler2D uDab;\n"
            "uniform sampler2D uDualDab;\n"
            "uniform sampler2D uGrain;\n"
            "uniform int   uHasDualDab;\n"
            "uniform int   uHasGrain;\n"
            "uniform float uWaterAmount;\n"
            "uniform float uWaterSpread;\n"
            "uniform float uHaloRadius;\n"
            "uniform float uGrainScale;\n"
            "uniform vec2  uCanvasSize;\n"
            "uniform vec2  uTexel;\n"
            "void main(){\n"
            "  vec4 wet = texture(uWetMapIn, v);\n"
            "  float dabA = texture(uDab, v).a;\n"
            "  // Huella de agua: punta secundaria difusa si existe (dual brush)\n"
            "  float waterA = dabA;\n"
            "  if (uHasDualDab == 1) {\n"
            "    waterA = max(waterA, texture(uDualDab, v).a);\n"
            "  }\n"
            "  // Fuga capilar: el agua se extiende en las fibras del papel más\n"
            "  // allá del borde del pigmento. Kernel de 8 taps (cardinales +\n"
            "  // diagonales) con radio dependiente de la humedad → halo suave\n"
            "  if (uWaterSpread > 0.001) {\n"
            "    vec2 o = uTexel * uHaloRadius;\n"
            "    float halo = texture(uDab, v + vec2(o.x, 0.0)).a\n"
            "               + texture(uDab, v - vec2(o.x, 0.0)).a\n"
            "               + texture(uDab, v + vec2(0.0, o.y)).a\n"
            "               + texture(uDab, v - vec2(0.0, o.y)).a;\n"
            "    halo += 0.707 * (texture(uDab, v + o * 0.707).a\n"
            "                   + texture(uDab, v - o * 0.707).a\n"
            "                   + texture(uDab, v + vec2( o.x, -o.y) * 0.707).a\n"
            "                   + texture(uDab, v + vec2(-o.x,  o.y) * 0.707).a);\n"
            "    waterA = max(waterA, halo * 0.1464 * uWaterSpread);\n"
            "  }\n"
            "  // CONTORNO ORGÁNICO: el grano del papel perturba el límite del\n"
            "  // agua en la zona de transición (ni núcleo ni exterior), para\n"
            "  // que el borde final del lavado sea irregular, no circular.\n"
            "  if (uHasGrain == 1 && waterA > 0.001) {\n"
            "    float edgeZone = smoothstep(0.0, 0.45, waterA)\n"
            "                   * (1.0 - smoothstep(0.45, 1.0, waterA));\n"
            "    if (edgeZone > 0.01) {\n"
            "      vec2 gc = (v * uCanvasSize) / (5.0 * uGrainScale);\n"
            "      vec4 gs = texture(uGrain, gc);\n"
            "      float gv = (gs.a < 0.99) ? gs.a\n"
            "                               : dot(gs.rgb, vec3(0.299, 0.587, 0.114));\n"
            "      waterA *= mix(1.0, 0.55 + 0.9 * gv, edgeZone * 0.8);\n"
            "    }\n"
            "  }\n"
            "  float water = waterA * uWaterAmount;\n"
            "  float newWet = clamp(wet.r + water * (1.0 - wet.r * 0.5), 0.0, 1.0);\n"
            "  // El agua fresca rejuvenece el píxel (edad hacia 0)\n"
            "  float newAge = (wet.r > 0.01) ? max(0.0, wet.g - water * 0.6) : 0.0;\n"
            "  fragOut = vec4(newWet, newAge, 0.0, 1.0);\n"
            "}\n");
        if (!m_depositShader->link()) {
            qWarning() << "WatercolorEngine: deposit shader link failed:"
                       << m_depositShader->log();
            delete m_depositShader;
            m_depositShader = nullptr;
        }
    }
}

void WatercolorEngine::invalidate() {
    m_spreadTimer->stop();
    m_dryTimer->stop();

    delete m_wetMapFBO_A;   m_wetMapFBO_A   = nullptr;
    delete m_wetMapFBO_B;   m_wetMapFBO_B   = nullptr;
    delete m_spreadFBO;     m_spreadFBO     = nullptr;
    delete m_shader;        m_shader        = nullptr;
    delete m_ageShader;     m_ageShader     = nullptr;
    delete m_depositShader; m_depositShader = nullptr;

    if (m_quadVBO) {
        if (m_gl) m_gl->glDeleteBuffers(1, &m_quadVBO);
        m_quadVBO   = 0;
        m_quadReady = false;
    }

    m_initialized = false;
    m_hasWetAreas = false;
}

// ========================== PINTAR DAB ======================================
// Esta función se llama CADA VEZ que el pincel deposita un dab en el canvas.
// Integra la textura del dab (ya renderizado por BrushEngine) con el canvas
// actual y actualiza el WetMap.
// ============================================================================

void WatercolorEngine::paintDab(GLuint dabTexId,
                                GLuint canvasTexIn,
                                QOpenGLFramebufferObject *canvasFBOout,
                                const QColor &brushColor,
                                const WatercolorParams &params,
                                float pressure,
                                float flow,
                                const QRect &dabRect,
                                GLuint dualDabTexId)
{
    if (!m_initialized || !m_shader || !canvasFBOout) return;

    m_lastCanvasTexId  = canvasTexIn;
    m_lastCanvasFBOOut = canvasFBOout;
    m_lastParams       = params;

    // Unión persistente de zonas húmedas (margen de 8px por el halo de agua)
    if (!dabRect.isEmpty()) {
        QRect wetRect = dabRect.adjusted(-8, -8, 8, 8)
                            .intersected(QRect(0, 0, m_width, m_height));
        if (m_wetBounds.isEmpty()) {
            m_wetBounds = wetRect;
        } else {
            m_wetBounds = m_wetBounds.united(wetRect);
        }
    } else {
        m_wetBounds = QRect(0, 0, m_width, m_height);
    }

    // Reset the spread simulation life timer based on the dryingRate (dryingTime = 1.0f / dryingRate)
    // dryingRate is in [0.1, 1.0]. A frame is 80ms (0.08s).
    // Add 10 frames safety margin
    float dryingTime = 1.0f / std::max(0.01f, params.dryingRate);
    m_spreadFramesRemaining = std::max(10, static_cast<int>(std::ceil(dryingTime / 0.08f)) + 10);

    // Paso 1: Aplicar el dab sobre el canvas con lógica de acuarela (Mode 0)
    //         El resultado va al canvasFBOout
    m_gl->glActiveTexture(GL_TEXTURE0);
    m_gl->glBindTexture(GL_TEXTURE_2D, canvasTexIn);         // Canvas actual

    m_gl->glActiveTexture(GL_TEXTURE1);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_wetMapFBO_A->texture()); // WetMap actual

    m_gl->glActiveTexture(GL_TEXTURE2);
    m_gl->glBindTexture(GL_TEXTURE_2D, dabTexId);            // El dab a pintar

    m_gl->glActiveTexture(GL_TEXTURE3);
    if (m_grainTexId)
        m_gl->glBindTexture(GL_TEXTURE_2D, m_grainTexId);   // Grano de papel

    m_shader->bind();
    m_shader->setUniformValue("uCanvas",       0);
    m_shader->setUniformValue("uWetMap",       1);
    m_shader->setUniformValue("uBrushDab",     2);
    m_shader->setUniformValue("uGrainTexture", 3);

    m_shader->setUniformValue("uBrushColor",  QVector4D(brushColor.redF(),
                                                         brushColor.greenF(),
                                                         brushColor.blueF(),
                                                         brushColor.alphaF()));
    m_shader->setUniformValue("uWetness",      params.wetness);
    m_shader->setUniformValue("uPigment",      params.pigment);
    m_shader->setUniformValue("uBleed",        params.bleed);
    m_shader->setUniformValue("uDilution",     params.dilution);
    m_shader->setUniformValue("uGranulation",  params.granulation);
    m_shader->setUniformValue("uAbsorption",   params.absorption);
    m_shader->setUniformValue("uDryingRate",   params.dryingRate);
    m_shader->setUniformValue("uEdgeDarkening",params.edgeDarkening);
    m_shader->setUniformValue("uGrainIntensity", params.grainIntensity);
    m_shader->setUniformValue("uGrainScale",     params.grainScale);
    m_shader->setUniformValue("uGrainBrightness",params.grainBrightness);
    m_shader->setUniformValue("uGrainContrast",  params.grainContrast);
    m_shader->setUniformValue("uInvertGrain",    params.invertGrain ? 1 : 0);
    m_shader->setUniformValue("uGrainEmphasizeDensity", params.grainEmphasizeDensity ? 1 : 0);
    m_shader->setUniformValue("uFlow",         flow);
    m_shader->setUniformValue("uPressure",     pressure);
    m_shader->setUniformValue("uCanvasSize",   QVector2D(m_width, m_height));
    m_shader->setUniformValue("uMode",         0);  // Paint Dab
    m_shader->setUniformValue("uBlendOnly",    params.blendOnly ? 1 : 0);
    m_shader->setUniformValue("uColorMixing",   params.colorMixing ? 1 : 0);
    m_shader->setUniformValue("uPaintAmount",   params.paintAmount);
    m_shader->setUniformValue("uColorStretch",  params.colorStretch);
    m_shader->setUniformValue("uBrushBlendMode", params.blendMode);

    bool useScissor = !dabRect.isEmpty();
    if (useScissor) {
        m_gl->glEnable(GL_SCISSOR_TEST);
        float gl_y = m_height - dabRect.y() - dabRect.height();
        m_gl->glScissor(dabRect.x(), gl_y, dabRect.width(), dabRect.height());
    }

    canvasFBOout->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND); // El shader maneja el compositing internamente
    renderFullscreenQuad();
    canvasFBOout->release();

    if (useScissor) {
        m_gl->glDisable(GL_SCISSOR_TEST);
    }

    m_shader->release();

    // Paso 2: Actualizar el WetMap — depositar agua del pincel
    updateWetMapDeposit(dabTexId, params, pressure, flow, dabRect, dualDabTexId);

    // Activar el timer de difusión (el secado está integrado en performSpread,
    // por lo que el dryTimer ya no se arranca — su slot era un no-op)
    m_hasWetAreas = true;
    if (!m_spreadTimer->isActive()) {
        m_spreadTimer->start();
    }
}

// ========================== DEPÓSITO DE AGUA EN WETMAP ======================
// Actualiza el WetMap añadiendo la huella de humedad del dab actual.
// La forma del dab determina dónde se desposita el agua.
// ============================================================================

void WatercolorEngine::updateWetMapDeposit(GLuint dabTexId,
                                           const WatercolorParams &params,
                                           float pressure,
                                           float flow,
                                           const QRect &dabRect,
                                           GLuint dualDabTexId)
{
    ensureAuxShaders();
    if (!m_depositShader) return;

    float waterAmount = params.wetness * flow * pressure;
    if (waterAmount < 0.01f) return;

    // ── SINCRONIZACIÓN PING-PONG ──
    // El render con scissor solo reescribe el rect del dab en B; el resto de
    // la zona húmeda quedaría con datos de dos pasadas atrás (la evaporación
    // se revertiría fuera del dab). Blit GPU→GPU de A→B sobre la unión húmeda
    // para que B sea idéntico a A antes del depósito parcial.
    if (!m_wetBounds.isEmpty()) {
        int glY = m_height - m_wetBounds.y() - m_wetBounds.height();
        QRect glWet(m_wetBounds.x(), glY, m_wetBounds.width(), m_wetBounds.height());
        QOpenGLFramebufferObject::blitFramebuffer(m_wetMapFBO_B, glWet,
                                                  m_wetMapFBO_A, glWet);
    }

    m_gl->glActiveTexture(GL_TEXTURE0);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_wetMapFBO_A->texture());
    m_gl->glActiveTexture(GL_TEXTURE1);
    m_gl->glBindTexture(GL_TEXTURE_2D, dabTexId);
    m_gl->glActiveTexture(GL_TEXTURE2);
    m_gl->glBindTexture(GL_TEXTURE_2D, dualDabTexId ? dualDabTexId : 0);
    m_gl->glActiveTexture(GL_TEXTURE3);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_grainTexId ? m_grainTexId : 0);

    bool useGrainEdge = (m_grainTexId != 0 && params.grainIntensity > 0.001f);

    m_depositShader->bind();
    m_depositShader->setUniformValue("uWetMapIn",    0);
    m_depositShader->setUniformValue("uDab",         1);
    m_depositShader->setUniformValue("uDualDab",     2);
    m_depositShader->setUniformValue("uGrain",       3);
    m_depositShader->setUniformValue("uHasDualDab",  dualDabTexId ? 1 : 0);
    m_depositShader->setUniformValue("uHasGrain",    useGrainEdge ? 1 : 0);
    m_depositShader->setUniformValue("uGrainScale",  std::max(0.1f, params.grainScale));
    m_depositShader->setUniformValue("uCanvasSize",  QVector2D(m_width, m_height));
    m_depositShader->setUniformValue("uWaterAmount", waterAmount);
    // El halo capilar crece con la humedad del pincel
    m_depositShader->setUniformValue("uWaterSpread",
        params.waterSpread * (0.5f + 0.5f * params.wetness));
    // Radio del halo en texels: pincel más cargado de agua → fuga más amplia
    m_depositShader->setUniformValue("uHaloRadius",
        2.0f + 4.0f * params.wetness);
    m_depositShader->setUniformValue("uTexel",
        QVector2D(1.0f / std::max(1, m_width), 1.0f / std::max(1, m_height)));

    bool useScissor = !dabRect.isEmpty();
    if (useScissor) {
        // Margen de 8px: el halo de agua muestrea hasta ±6 texels del pigmento
        QRect sc = dabRect.adjusted(-8, -8, 8, 8)
                       .intersected(QRect(0, 0, m_width, m_height));
        m_gl->glEnable(GL_SCISSOR_TEST);
        int gl_y = m_height - sc.y() - sc.height();
        m_gl->glScissor(sc.x(), gl_y, sc.width(), sc.height());
    }

    m_wetMapFBO_B->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND);
    renderFullscreenQuad();
    m_wetMapFBO_B->release();

    if (useScissor) {
        m_gl->glDisable(GL_SCISSOR_TEST);
    }

    m_depositShader->release();

    // Swap: B ahora es el WetMap actual
    std::swap(m_wetMapFBO_A, m_wetMapFBO_B);
}

// ========================== SPREAD (DIFUSIÓN) ================================
// Se llama cada ~80ms mientras hay zonas húmedas.
// Difunde el pigmento según el gradiente de humedad.
// ============================================================================

void WatercolorEngine::performSpread() {
    if (!m_initialized || !m_shader || !m_lastCanvasFBOOut) return;
    if (!m_hasWetAreas) {
        m_spreadTimer->stop();
        return;
    }

    m_spreadFramesRemaining--;
    if (m_spreadFramesRemaining <= 0) {
        m_spreadTimer->stop();
        m_dryTimer->stop();
        m_hasWetAreas = false;
        return;
    }

    // Expand the wet bounds slightly to account for the bleed spreading outward
    m_wetBounds = m_wetBounds.adjusted(-4, -4, 4, 4).intersected(QRect(0, 0, m_width, m_height));
    if (m_wetBounds.isEmpty()) return;

    int scissorX = m_wetBounds.x();
    int scissorY = m_height - m_wetBounds.y() - m_wetBounds.height();
    int scissorW = m_wetBounds.width();
    int scissorH = m_wetBounds.height();

    // ── PASADA A: Difusión de Pigmento en el Lienzo (Mode 1) ──
    m_gl->glActiveTexture(GL_TEXTURE0);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_lastCanvasFBOOut->texture()); // Canvas lectura
    m_gl->glActiveTexture(GL_TEXTURE1);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_wetMapFBO_A->texture());       // WetMap lectura
    m_gl->glActiveTexture(GL_TEXTURE2);
    m_gl->glBindTexture(GL_TEXTURE_2D, 0);                             // Sin Dab
    m_gl->glActiveTexture(GL_TEXTURE3);
    if (m_grainTexId) {
        m_gl->glBindTexture(GL_TEXTURE_2D, m_grainTexId);              // Textura de grano de papel
    } else {
        m_gl->glBindTexture(GL_TEXTURE_2D, 0);
    }

    m_shader->bind();
    m_shader->setUniformValue("uCanvas",         0);
    m_shader->setUniformValue("uWetMap",         1);
    m_shader->setUniformValue("uBrushDab",       2);
    m_shader->setUniformValue("uGrainTexture",   3);
    m_shader->setUniformValue("uBleed",          m_lastParams.bleed);
    m_shader->setUniformValue("uEdgeDarkening",  m_lastParams.edgeDarkening);
    m_shader->setUniformValue("uGrainIntensity", m_lastParams.grainIntensity);
    m_shader->setUniformValue("uGrainScale",     m_lastParams.grainScale);
    m_shader->setUniformValue("uGrainBrightness",m_lastParams.grainBrightness);
    m_shader->setUniformValue("uGrainContrast",  m_lastParams.grainContrast);
    m_shader->setUniformValue("uInvertGrain",    m_lastParams.invertGrain ? 1 : 0);
    m_shader->setUniformValue("uGrainEmphasizeDensity", m_lastParams.grainEmphasizeDensity ? 1 : 0);
    m_shader->setUniformValue("uCanvasSize",     QVector2D(m_width, m_height));
    m_shader->setUniformValue("uMode",           1);  // Spread Wet
    m_shader->setUniformValue("uBlendOnly",      m_lastParams.blendOnly ? 1 : 0);
    m_shader->setUniformValue("uColorMixing",   m_lastParams.colorMixing ? 1 : 0);
    m_shader->setUniformValue("uPaintAmount",   m_lastParams.paintAmount);
    m_shader->setUniformValue("uColorStretch",  m_lastParams.colorStretch);
    m_shader->setUniformValue("uBrushBlendMode", m_lastParams.blendMode);

    m_gl->glEnable(GL_SCISSOR_TEST);
    m_gl->glScissor(scissorX, scissorY, scissorW, scissorH);

    m_spreadFBO->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND);
    renderFullscreenQuad();
    m_spreadFBO->release();
    m_shader->release();
    m_gl->glDisable(GL_SCISSOR_TEST);

    // Guardar solo el área modificada de vuelta a m_lastCanvasFBOOut
    QRect glWetBounds(scissorX, scissorY, scissorW, scissorH);
    QOpenGLFramebufferObject::blitFramebuffer(m_lastCanvasFBOOut, glWetBounds, m_spreadFBO, glWetBounds);

    // ── PASADA B: Difusión y Evaporación de Agua en WetMap (Mode 2) ──
    m_gl->glActiveTexture(GL_TEXTURE0);
    m_gl->glBindTexture(GL_TEXTURE_2D, 0);
    m_gl->glActiveTexture(GL_TEXTURE1);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_wetMapFBO_A->texture());       // WetMap lectura
    m_gl->glActiveTexture(GL_TEXTURE2);
    m_gl->glBindTexture(GL_TEXTURE_2D, 0);
    m_gl->glActiveTexture(GL_TEXTURE3);
    if (m_grainTexId) {
        m_gl->glBindTexture(GL_TEXTURE_2D, m_grainTexId);              // Grano para fricción/absorción
    } else {
        m_gl->glBindTexture(GL_TEXTURE_2D, 0);
    }

    m_shader->bind();
    m_shader->setUniformValue("uWetMap",         1);
    m_shader->setUniformValue("uGrainTexture",   3);
    m_shader->setUniformValue("uBleed",          m_lastParams.bleed);
    m_shader->setUniformValue("uDryingRate",     m_lastParams.dryingRate);
    m_shader->setUniformValue("uAbsorption",     m_lastParams.absorption);
    m_shader->setUniformValue("uGrainIntensity", m_lastParams.grainIntensity);
    m_shader->setUniformValue("uGrainScale",     m_lastParams.grainScale);
    m_shader->setUniformValue("uGrainBrightness",m_lastParams.grainBrightness);
    m_shader->setUniformValue("uGrainContrast",  m_lastParams.grainContrast);
    m_shader->setUniformValue("uInvertGrain",    m_lastParams.invertGrain ? 1 : 0);
    m_shader->setUniformValue("uGrainEmphasizeDensity", m_lastParams.grainEmphasizeDensity ? 1 : 0);
    m_shader->setUniformValue("uCanvasSize",     QVector2D(m_width, m_height));
    m_shader->setUniformValue("uMode",           2);  // Dry Step (Difusión + Evaporación de Agua)
    m_shader->setUniformValue("uBlendOnly",      m_lastParams.blendOnly ? 1 : 0);
    m_shader->setUniformValue("uColorMixing",   m_lastParams.colorMixing ? 1 : 0);
    m_shader->setUniformValue("uPaintAmount",   m_lastParams.paintAmount);
    m_shader->setUniformValue("uColorStretch",  m_lastParams.colorStretch);
    m_shader->setUniformValue("uBrushBlendMode", m_lastParams.blendMode);

    m_gl->glEnable(GL_SCISSOR_TEST);
    m_gl->glScissor(scissorX, scissorY, scissorW, scissorH);

    m_wetMapFBO_B->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND);
    renderFullscreenQuad();
    m_wetMapFBO_B->release();
    m_shader->release();
    m_gl->glDisable(GL_SCISSOR_TEST);

    // Intercambiar el WetMap (A = nuevo estado simulado)
    std::swap(m_wetMapFBO_A, m_wetMapFBO_B);

    emit wetMapUpdated();
}

// ========================== DRY STEP (SECADO) ================================
// Se ejecutaba a intervalos de 2.5s, pero ahora el secado y flujo continuo
// de agua ocurren en performSpread() cada 80ms de manera mucho más fluida.
// ============================================================================

void WatercolorEngine::performDryStep() {
    // No-op: el secado progresivo realista ya está integrado en la simulación de 80ms
}

// ========================== UTILIDADES PRIVADAS ==============================

void WatercolorEngine::ensureFBOs(int w, int h) {
    if (m_width == w && m_height == h && m_wetMapFBO_A && m_wetMapFBO_B)
        return;

    m_width  = w;
    m_height = h;

    delete m_wetMapFBO_A; m_wetMapFBO_A = nullptr;
    delete m_wetMapFBO_B; m_wetMapFBO_B = nullptr;
    delete m_spreadFBO;   m_spreadFBO   = nullptr;

    // WetMap: RG16F — R=humedad, G=edad del pigmento
    QOpenGLFramebufferObjectFormat wetFmt;
    wetFmt.setInternalTextureFormat(GL_RG16F);
    wetFmt.setSamples(0);
    wetFmt.setAttachment(QOpenGLFramebufferObject::NoAttachment);

    m_wetMapFBO_A = new QOpenGLFramebufferObject(w, h, wetFmt);
    m_wetMapFBO_B = new QOpenGLFramebufferObject(w, h, wetFmt);

    // Canvas intermedio para spread (RGBA mismo formato que el canvas)
    QOpenGLFramebufferObjectFormat canvasFmt;
    canvasFmt.setInternalTextureFormat(GL_RGBA16F);
    canvasFmt.setSamples(0);
    canvasFmt.setAttachment(QOpenGLFramebufferObject::NoAttachment);

    m_spreadFBO = new QOpenGLFramebufferObject(w, h, canvasFmt);

    // Configurar filtrado bilineal en los wetmap textures
    auto setupTex = [this](GLuint texId) {
        m_gl->glBindTexture(GL_TEXTURE_2D, texId);
        m_gl->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        m_gl->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
#ifdef GL_CLAMP_TO_BORDER
        m_gl->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        m_gl->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        float zero[] = {0,0,0,0};
        m_gl->glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, zero);
#else
        m_gl->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        m_gl->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
#endif
    };
    setupTex(m_wetMapFBO_A->texture());
    setupTex(m_wetMapFBO_B->texture());
    setupTex(m_spreadFBO->texture());
}

void WatercolorEngine::ensureShader() {
    if (m_shader) return;

    m_shader = new QOpenGLShaderProgram(this);

    // Buscar shaders en rutas del proyecto
    QStringList paths;
    paths << ":/src/core/shaders/"
          << QCoreApplication::applicationDirPath() + "/shaders/"
          << QCoreApplication::applicationDirPath() + "/../src/core/shaders/"
          << "src/core/shaders/";

    QString vertPath, fragPath;
    for (const QString &p : paths) {
        qWarning() << "WatercolorEngine: checking path:" << p;
        if (QFile::exists(p + "watercolor.vert") &&
            QFile::exists(p + "watercolor.frag")) {
            vertPath = p + "watercolor.vert";
            fragPath = p + "watercolor.frag";
            qWarning() << "WatercolorEngine: Found shaders at:" << p;
            break;
        }
    }

    if (!vertPath.isEmpty()) {
        qWarning() << "WatercolorEngine: Compiling vertex shader:" << vertPath << "and fragment shader:" << fragPath;
        m_shader->addShaderFromSourceFile(QOpenGLShader::Vertex,   vertPath);
        m_shader->addShaderFromSourceFile(QOpenGLShader::Fragment, fragPath);
        m_shader->bindAttributeLocation("aPosition", 0);
        m_shader->bindAttributeLocation("aTexCoord", 1);
        if (!m_shader->link()) {
            qWarning() << "WatercolorEngine: shader link failed:" << m_shader->log();
            delete m_shader;
            m_shader = nullptr;
        } else {
            qWarning() << "WatercolorEngine: shader link succeeded!";
        }
    } else {
        qWarning() << "WatercolorEngine: watercolor shaders not found in search paths";
    }
}

void WatercolorEngine::initQuadGeometry() {
    if (m_quadReady) return;
    m_gl->glGenBuffers(1, &m_quadVBO);
    m_gl->glBindBuffer(GL_ARRAY_BUFFER, m_quadVBO);
    m_gl->glBufferData(GL_ARRAY_BUFFER, sizeof(QUAD_VERTS), QUAD_VERTS, GL_STATIC_DRAW);
    m_gl->glBindBuffer(GL_ARRAY_BUFFER, 0);
    m_quadReady = true;
}

void WatercolorEngine::renderFullscreenQuad() {
    initQuadGeometry();
    m_gl->glBindBuffer(GL_ARRAY_BUFFER, m_quadVBO);
    m_gl->glEnableVertexAttribArray(0);
    m_gl->glEnableVertexAttribArray(1);
    m_gl->glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE,
                                4 * sizeof(float), (void*)(0));
    m_gl->glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,
                                4 * sizeof(float), (void*)(2 * sizeof(float)));
    m_gl->glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    m_gl->glDisableVertexAttribArray(0);
    m_gl->glDisableVertexAttribArray(1);
    m_gl->glBindBuffer(GL_ARRAY_BUFFER, 0);
}

GLuint WatercolorEngine::wetMapTextureId() const {
    return m_wetMapFBO_A ? m_wetMapFBO_A->texture() : 0;
}
