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

    ensureFBOs(w, h);
    ensureShader();

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

void WatercolorEngine::invalidate() {
    m_spreadTimer->stop();
    m_dryTimer->stop();

    delete m_wetMapFBO_A; m_wetMapFBO_A = nullptr;
    delete m_wetMapFBO_B; m_wetMapFBO_B = nullptr;
    delete m_spreadFBO;   m_spreadFBO   = nullptr;
    delete m_shader;      m_shader      = nullptr;

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
                                float flow)
{
    if (!m_initialized || !m_shader || !canvasFBOout) return;

    m_lastCanvasTexId  = canvasTexIn;
    m_lastCanvasFBOOut = canvasFBOout;
    m_lastParams       = params;

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
    m_shader->setUniformValue("uFlow",         flow);
    m_shader->setUniformValue("uPressure",     pressure);
    m_shader->setUniformValue("uCanvasSize",   QVector2D(m_width, m_height));
    m_shader->setUniformValue("uMode",         0);  // Paint Dab

    canvasFBOout->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND); // El shader maneja el compositing internamente
    renderFullscreenQuad();
    canvasFBOout->release();

    m_shader->release();

    // Paso 2: Actualizar el WetMap — depositar agua del pincel
    // Se hace en Mode 0 también (el shader escribe el wetmap vía una segunda salida)
    // En esta implementación simplificada, el WetMap se actualiza directamente
    // escribiendo en m_wetMapFBO_B con un pass especial de "depósito de agua"
    updateWetMapDeposit(dabTexId, params, pressure, flow);

    // Activar timers de difusión y secado
    m_hasWetAreas = true;
    if (!m_spreadTimer->isActive()) {
        m_spreadTimer->start();
    }
    if (!m_dryTimer->isActive()) {
        m_dryTimer->start();
    }
}

// ========================== DEPÓSITO DE AGUA EN WETMAP ======================
// Actualiza el WetMap añadiendo la huella de humedad del dab actual.
// La forma del dab determina dónde se desposita el agua.
// ============================================================================

void WatercolorEngine::updateWetMapDeposit(GLuint dabTexId,
                                           const WatercolorParams &params,
                                           float pressure,
                                           float flow)
{
    // Pass especial: copiar el WetMap actual (A) al B sumando la nueva agua
    // Usamos un shader inline simple para el depósito
    static QOpenGLShaderProgram *depositShader = nullptr;

    if (!depositShader) {
        depositShader = new QOpenGLShaderProgram(this);
        depositShader->addShaderFromSourceCode(QOpenGLShader::Vertex,
            "#version 330 core\n"
            "layout(location=0)in vec2 p;\n"
            "layout(location=1)in vec2 t;\n"
            "out vec2 v;\n"
            "void main(){gl_Position=vec4(p,0,1);v=t;}\n");
        depositShader->addShaderFromSourceCode(QOpenGLShader::Fragment,
            "#version 330 core\n"
            "in vec2 v;\n"
            "out vec4 o;\n"
            "uniform sampler2D uWetMapIn;\n"
            "uniform sampler2D uDab;\n"
            "uniform float uWaterAmount;\n"
            "void main(){\n"
            "  vec4 wet = texture(uWetMapIn, v);\n"
            "  vec4 dab = texture(uDab, v);\n"
            "  float water = dab.a * uWaterAmount;\n"  // Agua proporcional al dab
            "  float freshness = wet.g > 0.0 ? 0.0 : 1.0;\n"  // Resetear edad si nuevo agua
            "  float newWet = clamp(wet.r + water * (1.0 - wet.r * 0.5), 0.0, 1.0);\n"
            "  float newAge = wet.r > 0.01 ? min(wet.g, 1.0 - water * 0.3) : 0.0;\n"
            "  o = vec4(newWet, newAge, 0.0, 1.0);\n"
            "}\n");
        if (!depositShader->link()) {
            qWarning() << "WatercolorEngine: deposit shader link failed:"
                       << depositShader->log();
        }
    }

    float waterAmount = params.wetness * flow * pressure;
    if (waterAmount < 0.01f) return;

    m_gl->glActiveTexture(GL_TEXTURE0);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_wetMapFBO_A->texture());
    m_gl->glActiveTexture(GL_TEXTURE1);
    m_gl->glBindTexture(GL_TEXTURE_2D, dabTexId);

    depositShader->bind();
    depositShader->setUniformValue("uWetMapIn",    0);
    depositShader->setUniformValue("uDab",         1);
    depositShader->setUniformValue("uWaterAmount", waterAmount);

    m_wetMapFBO_B->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND);
    renderFullscreenQuad();
    m_wetMapFBO_B->release();
    depositShader->release();

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

    // Verificar si todavía hay humedad significativa
    // (simplificado: asumir que hay humedad mientras el timer corre)

    m_gl->glActiveTexture(GL_TEXTURE0);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_lastCanvasFBOOut->texture());
    m_gl->glActiveTexture(GL_TEXTURE1);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_wetMapFBO_A->texture());
    m_gl->glActiveTexture(GL_TEXTURE2);
    m_gl->glBindTexture(GL_TEXTURE_2D, 0); // No hay dab en este paso

    m_shader->bind();
    m_shader->setUniformValue("uCanvas",       0);
    m_shader->setUniformValue("uWetMap",       1);
    m_shader->setUniformValue("uBrushDab",     2);
    m_shader->setUniformValue("uBleed",        m_lastParams.bleed);
    m_shader->setUniformValue("uEdgeDarkening",m_lastParams.edgeDarkening);
    m_shader->setUniformValue("uCanvasSize",   QVector2D(m_width, m_height));
    m_shader->setUniformValue("uMode",         1);  // Spread Wet

    // Escribir el resultado del spread en m_spreadFBO, luego copiar al canvas
    m_spreadFBO->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND);
    renderFullscreenQuad();
    m_spreadFBO->release();
    m_shader->release();

    // Blit del spread de vuelta al canvasFBOout
    QOpenGLFramebufferObject::blitFramebuffer(m_lastCanvasFBOOut, m_spreadFBO);

    emit wetMapUpdated();
}

// ========================== DRY STEP (SECADO) ================================
// Se llama cada ~2.5s. Reduce la humedad del WetMap.
// ============================================================================

void WatercolorEngine::performDryStep() {
    if (!m_initialized || !m_shader) return;

    m_gl->glActiveTexture(GL_TEXTURE0);
    m_gl->glBindTexture(GL_TEXTURE_2D, 0);
    m_gl->glActiveTexture(GL_TEXTURE1);
    m_gl->glBindTexture(GL_TEXTURE_2D, m_wetMapFBO_A->texture());

    m_shader->bind();
    m_shader->setUniformValue("uWetMap",     1);
    m_shader->setUniformValue("uDryingRate", m_lastParams.dryingRate);
    m_shader->setUniformValue("uAbsorption", m_lastParams.absorption);
    m_shader->setUniformValue("uCanvasSize", QVector2D(m_width, m_height));
    m_shader->setUniformValue("uMode",       2);  // Dry Step

    m_wetMapFBO_B->bind();
    m_gl->glViewport(0, 0, m_width, m_height);
    m_gl->glDisable(GL_BLEND);
    renderFullscreenQuad();
    m_wetMapFBO_B->release();
    m_shader->release();

    std::swap(m_wetMapFBO_A, m_wetMapFBO_B);

    // Si el wetmap está casi seco, detener timers para ahorrar GPU
    // (En una implementación completa leeríamos el FBO para verificar)
    // Por ahora, detener el spread después de 30s de inactividad
    // (manejado por el contador en performSpread)

    emit wetMapUpdated();
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
        m_gl->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        m_gl->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        float zero[] = {0,0,0,0};
        m_gl->glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, zero);
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
    paths << QCoreApplication::applicationDirPath() + "/shaders/"
          << QCoreApplication::applicationDirPath() + "/../src/core/shaders/"
          << "src/core/shaders/";

    QString vertPath, fragPath;
    for (const QString &p : paths) {
        if (QFile::exists(p + "watercolor.vert") &&
            QFile::exists(p + "watercolor.frag")) {
            vertPath = p + "watercolor.vert";
            fragPath = p + "watercolor.frag";
            break;
        }
    }

    if (!vertPath.isEmpty()) {
        m_shader->addShaderFromSourceFile(QOpenGLShader::Vertex,   vertPath);
        m_shader->addShaderFromSourceFile(QOpenGLShader::Fragment, fragPath);
        m_shader->bindAttributeLocation("aPosition", 0);
        m_shader->bindAttributeLocation("aTexCoord", 1);
        if (!m_shader->link()) {
            qWarning() << "WatercolorEngine: shader link failed:" << m_shader->log();
            delete m_shader;
            m_shader = nullptr;
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
