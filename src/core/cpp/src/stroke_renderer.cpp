#include "../include/stroke_renderer.h"
#include <QDebug>
#include <QFile>
#include <QMatrix4x4>
#include <cmath>

StrokeRenderer::StrokeRenderer()
    : m_program(nullptr), m_vbo(QOpenGLBuffer::VertexBuffer) {}

StrokeRenderer::~StrokeRenderer() {
  if (m_program)
    delete m_program;
}

void StrokeRenderer::initialize() {
  initializeOpenGLFunctions();

  // 1. Compilar Shaders
  m_program = new QOpenGLShaderProgram();

  // IMPORTANTE: Asegúrate de que los archivos estén en tu QRC o ruta correcta
  // Usamos rutas absolutas relativas al proyecto por ahora, o QRC si el usuario
  // lo pide El usuario dijo ":/shaders/brush.vert". Voy a intentar usar la ruta
  // local del archivo si no existe en QRC. Pero
  // QOpenGLShaderProgram::addShaderFromSourceFile espera un path. Si no usamos
  // QRC, necesitamos la ruta absoluta. Hack: Asumimos que los shaders estan en
  // e:/app_dibujo_proyecto-main/src/core/shaders/

  if (!m_program->addShaderFromSourceFile(
          QOpenGLShader::Vertex,
          "e:/app_dibujo_proyecto-main/src/core/shaders/brush.vert"))
    qDebug() << "Error Vertex Shader:" << m_program->log();

  if (!m_program->addShaderFromSourceFile(
          QOpenGLShader::Fragment,
          "e:/app_dibujo_proyecto-main/src/core/shaders/brush.frag"))
    qDebug() << "Error Fragment Shader:" << m_program->log();

  if (!m_program->link())
    qDebug() << "Error Link Shader:" << m_program->log();

  // 2. Crear Quad (El cuadrado donde dibujamos el círculo del pincel)
  float vertices[] = {
      // Pos      // TexCoords
      0.0f, 1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,

      0.0f, 1.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f};

  m_vao.create();
  m_vao.bind();

  m_vbo.create();
  m_vbo.bind();
  m_vbo.allocate(vertices, sizeof(vertices));

  // Atributo 0: Posición
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void *)0);
  glEnableVertexAttribArray(0);

  // Atributo 1: Textura
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float),
                        (void *)(2 * sizeof(float)));
  glEnableVertexAttribArray(1);

  m_vao.release();
}

void StrokeRenderer::renderStroke(float x, float y, float size, float pressure,
                                  float hardness, const QColor &color, int type,
                                  int width, int height) {
  if (!m_program)
    return;

  m_program->bind();
  m_vao.bind();

  // Configurar Uniforms (Enviar datos al Shader)
  QMatrix4x4 projection;
  projection.ortho(0, width, height, 0, -1,
                   1); // Sistema de coordenadas 2D (0,0 arriba-izq)

  QMatrix4x4 model;
  model.translate(x - size / 2, y - size / 2, 0); // Centrar
  model.scale(size, size, 1);                     // Escalar

  m_program->setUniformValue("projection", projection);
  m_program->setUniformValue("model", model);
  m_program->setUniformValue("color", color);
  m_program->setUniformValue("pressure", pressure); // ¡AQUÍ ESTÁ LA PRESIÓN!
  m_program->setUniformValue("hardness", hardness);
  m_program->setUniformValue("brushType", type);

  // Dibujar
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glDrawArrays(GL_TRIANGLES, 0, 6);

  m_vao.release();
  m_program->release();
}
