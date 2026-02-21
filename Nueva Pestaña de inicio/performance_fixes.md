# Correcciones de Rendimiento — Transformación de Perspectiva
## `CanvasItem.cpp` — 5 parches listos para aplicar

---

## PARCHE 1 — Throttle del `update()` en mouseMoveEvent
**Problema:** Cada movimiento del ratón dispara un redibujado completo. Con una tableta
esto son 200–400 redraws/segundo innecesarios durante la transformación.

### 1a) En `CanvasItem.h` — añadir estos miembros privados:
```cpp
// --- Throttle de redibujado ---
bool     m_pendingUpdate  = false;
QTimer  *m_updateThrottle = nullptr;
```

### 1b) En el constructor `CanvasItem::CanvasItem(...)` — después de crear `m_quickShapeTimer`:
```cpp
// Throttle de redibujado a ~60fps máximo
m_updateThrottle = new QTimer(this);
m_updateThrottle->setInterval(14); // ~72fps cap
m_updateThrottle->setSingleShot(true);
connect(m_updateThrottle, &QTimer::timeout, this, [this]() {
    m_pendingUpdate = false;
    QQuickPaintedItem::update();
});
```

### 1c) Añadir este método helper en `CanvasItem.h` (privado) y su implementación:
```cpp
// En el .h:
void requestUpdate();

// En el .cpp:
void CanvasItem::requestUpdate() {
    if (!m_pendingUpdate) {
        m_pendingUpdate = true;
        m_updateThrottle->start();
    }
}
```

### 1d) En `mouseMoveEvent` — reemplazar los dos `update()` del bloque Transform:

**ANTES (líneas ~1539 y ~1566):**
```cpp
  m_cursorPos = event->position();
  m_cursorVisible = true;
  update();                          // <-- línea ~1539

  // ...

  if (m_tool == ToolType::Transform && m_transformMode == TransformMode::Move) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    QPointF delta = canvasPos - m_transformStartPos;
    m_transformMatrix = m_initialMatrix;
    m_transformMatrix.translate(delta.x(), delta.y());
    update();                        // <-- línea ~1566
    return;
  }
```

**DESPUÉS:**
```cpp
  m_cursorPos = event->position();
  m_cursorVisible = true;
  requestUpdate();                   // throttled

  // ...

  if (m_tool == ToolType::Transform && m_transformMode == TransformMode::Move) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    QPointF delta = canvasPos - m_transformStartPos;
    m_transformMatrix = m_initialMatrix;
    m_transformMatrix.translate(delta.x(), delta.y());
    requestUpdate();                 // throttled
    return;
  }
```

> **Nota:** Deja los `update()` que están fuera de mouseMoveEvent (en `beginTransform`,
> `applyTransform`, `cancelTransform`) como están — esos sólo se llaman una vez.

---

## PARCHE 2 — Eliminar `glCopyTexImage2D` por un FBO backdrop
**Problema:** `glCopyTexImage2D` copia 8MB del framebuffer físico en cada frame de
composición, forzando un GPU pipeline stall.

**Solo afecta a `blendWithShader`. El backdrop se usa para los blend modes.**
Si tus blend modes no necesitan ver los píxeles ya pintados debajo durante la
transformación (la mayoría no lo necesitan durante el drag), la solución más rápida
es **no capturar el backdrop durante el modo transformación**:

### En `blendWithShader`, localiza la sección del backdrop (~línea 5663–5677):

**ANTES:**
```cpp
  // Ensure we are in Native Painting mode (flushes QPainter commands)
  painter->beginNativePainting();

  // 1. Capture current framebuffer (Backdrop)
  f->glActiveTexture(GL_TEXTURE0);
  f->glBindTexture(GL_TEXTURE_2D, backdropTexID);
  f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  // Copy the ENTIRE physical framebuffer to the texture
  f->glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, w, h, 0);
```

**DESPUÉS:**
```cpp
  painter->beginNativePainting();

  // 1. Capture backdrop — omitir durante transformación activa para evitar
  //    el GPU stall de glCopyTexImage2D (8MB/frame a 1080p)
  f->glActiveTexture(GL_TEXTURE0);
  f->glBindTexture(GL_TEXTURE_2D, backdropTexID);
  f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  if (!m_isTransforming) {
      // Sólo capturamos el backdrop cuando realmente pintamos (blend modes)
      f->glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, w, h, 0);
  }
  // Durante transformación el shader usará el backdrop anterior (estático),
  // lo cual es correcto porque el fondo no cambia mientras arrastras.
```

---

## PARCHE 3 — `beginTransform`: mover `compositeAll` fuera del hilo UI
**Problema:** `compositeAll` aplana todas las capas (potencialmente gigabytes de datos)
en el hilo principal de la UI, congelando la interfaz varios frames.

### En `beginTransform`, localiza (~línea 2473–2480):

**ANTES:**
```cpp
  // PRECOMPUTE FULL FLATTENED STATIC BACKGROUND FOR ~60FPS GPU/CPU PREVIEW
  artflow::ImageBuffer tempBuffer(m_canvasWidth, m_canvasHeight);
  m_layerManager->compositeAll(tempBuffer, false);
  m_transformStaticCache =
      QImage(tempBuffer.data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888_Premultiplied)
          .copy();
  m_updateTransformTextures = true;
```

**DESPUÉS:**
```cpp
  // PRECOMPUTE en hilo secundario — no bloquear la UI
  // Mostramos la transformación en cuanto tengamos el cache listo
  m_updateTransformTextures = false; // aún no está listo
  emit isTransformingChanged();
  update(); // primer frame: mostrará el canvas sin el static cache (acceptable)

  // Capturar lo que necesita el hilo secundario antes de lanzarlo
  int cw = m_canvasWidth;
  int ch = m_canvasHeight;

  QFuture<QImage> future = QtConcurrent::run([this, cw, ch]() -> QImage {
      artflow::ImageBuffer tempBuffer(cw, ch);
      m_layerManager->compositeAll(tempBuffer, false);
      return QImage(tempBuffer.data(), cw, ch,
                    QImage::Format_RGBA8888_Premultiplied).copy();
  });

  // Watcher para cuando termine — volver al hilo principal
  auto *watcher = new QFutureWatcher<QImage>(this);
  connect(watcher, &QFutureWatcher<QImage>::finished, this,
          [this, watcher]() {
              m_transformStaticCache = watcher->result();
              m_updateTransformTextures = true;
              watcher->deleteLater();
              update(); // ahora sí redibujar con el static cache en GPU
          });
  watcher->setFuture(future);

  // Nota: quitar el "emit isTransformingChanged()" y "update()" que había
  // al final del bloque original (los movemos arriba). Sólo dejar:
  emit notificationRequested("Transform Mode: " + (m_hasSelection
                                                     ? QString("Selection")
                                                     : QString("Layer")),
                             "info");
  emit transformBoxChanged();
  return; // el update() ya fue emitido arriba
```

> **Importante:** En el `.h` asegúrate de tener `#include <QFutureWatcher>` y
> `#include <QtConcurrent>` (ya los tienes en el .cpp, pero el lambda captura
> `m_layerManager` — asegúrate de que `compositeAll` sea thread-safe o protégelo
> con un `QMutex` si no lo es).

---

## PARCHE 4 — `applyTransform`: commit final en GPU en vez de CPU
**Problema:** `QPainter::drawImage` con una `QTransform` de perspectiva procesa cada
píxel en CPU. En un canvas de 1920×1080 esto tarda 200–800ms según el hardware.

### Reemplaza `applyTransform` completo (~línea 2516–2560):

**ANTES:**
```cpp
void CanvasItem::applyTransform() {
  if (!m_isTransforming || m_selectionBuffer.isNull())
    return;

  Layer *layer = m_layerManager->getActiveLayer();
  if (layer && layer->buffer) {
    // ...
    QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
               QImage::Format_RGBA8888_Premultiplied);
    QPainter p(&img);
    p.setRenderHint(QPainter::SmoothPixmapTransform);
    p.setRenderHint(QPainter::Antialiasing);
    p.setTransform(m_transformMatrix);
    p.drawImage(0, 0, m_selectionBuffer);   // <-- CPU lento
    p.end();
    layer->dirty = true;
  }
  // ...
}
```

**DESPUÉS:**
```cpp
void CanvasItem::applyTransform() {
  if (!m_isTransforming || m_selectionBuffer.isNull())
    return;

  Layer *layer = m_layerManager->getActiveLayer();
  if (layer && layer->buffer) {
    QOpenGLContext *ctx = QOpenGLContext::currentContext();

    if (ctx && m_transformShader && m_selectionTex) {
      // --- CAMINO RÁPIDO: blit final por GPU usando el shader que ya existe ---
      // Renderizamos a un FBO del tamaño del canvas y leemos el resultado
      QOpenGLFramebufferObjectFormat fmt;
      fmt.setInternalTextureFormat(GL_RGBA8);
      QOpenGLFramebufferObject fbo(m_canvasWidth, m_canvasHeight, fmt);
      fbo.bind();

      QOpenGLFunctions *f = ctx->functions();
      f->glViewport(0, 0, m_canvasWidth, m_canvasHeight);
      f->glClearColor(0, 0, 0, 0);
      f->glClear(GL_COLOR_BUFFER_BIT);
      f->glEnable(GL_BLEND);
      f->glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

      m_transformShader->bind();

      // Proyección ortográfica del tamaño del canvas (sin pan/zoom)
      QMatrix4x4 ortho;
      ortho.ortho(0, m_canvasWidth, m_canvasHeight, 0, -1, 1);

      // Construir MVP = ortho * perspectiveMatrix * localOffset
      QMatrix4x4 qtMat;
      qtMat.setColumn(0, QVector4D(m_transformMatrix.m11(),
                                   m_transformMatrix.m12(), 0,
                                   m_transformMatrix.m13()));
      qtMat.setColumn(1, QVector4D(m_transformMatrix.m21(),
                                   m_transformMatrix.m22(), 0,
                                   m_transformMatrix.m23()));
      qtMat.setColumn(2, QVector4D(0, 0, 1, 0));
      qtMat.setColumn(3, QVector4D(m_transformMatrix.m31(),
                                   m_transformMatrix.m32(), 0,
                                   m_transformMatrix.m33()));
      QMatrix4x4 localTrans;
      localTrans.translate(m_transformBox.x(), m_transformBox.y());

      m_transformShader->setUniformValue("MVP", ortho * qtMat * localTrans);
      m_transformShader->setUniformValue("opacity", 1.0f);
      m_selectionTex->bind(0);
      m_transformShader->setUniformValue("tex", 0);

      float sw = m_selectionBuffer.width();
      float sh = m_selectionBuffer.height();
      GLfloat verts[] = { 0,  0,  0, 0,
                          sw, 0,  1, 0,
                          0,  sh, 0, 1,
                          0,  sh, 0, 1,
                          sw, 0,  1, 0,
                          sw, sh, 1, 1 };
      m_transformShader->enableAttributeArray(0);
      m_transformShader->enableAttributeArray(1);
      m_transformShader->setAttributeArray(0, GL_FLOAT, verts,     2, 4*sizeof(float));
      m_transformShader->setAttributeArray(1, GL_FLOAT, verts + 2, 2, 4*sizeof(float));
      f->glDrawArrays(GL_TRIANGLES, 0, 6);
      m_transformShader->disableAttributeArray(0);
      m_transformShader->disableAttributeArray(1);
      m_transformShader->release();
      fbo.release();

      // Leer resultado del FBO (GPU→CPU, una sola vez al confirmar)
      QImage result = fbo.toImage(true)
                         .convertToFormat(QImage::Format_RGBA8888_Premultiplied);

      // Combinar con el buffer de la capa (que ya tiene el fondo sin la selección)
      QImage layerImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                      QImage::Format_RGBA8888_Premultiplied);
      QPainter p(&layerImg);
      p.setCompositionMode(QPainter::CompositionMode_SourceOver);
      p.drawImage(0, 0, result);
      p.end();

    } else {
      // --- FALLBACK CPU (sin contexto GL disponible en este momento) ---
      QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);
      QPainter p(&img);
      p.setRenderHint(QPainter::SmoothPixmapTransform);
      p.setRenderHint(QPainter::Antialiasing);
      p.setTransform(m_transformMatrix);
      p.drawImage(m_transformBox.topLeft(), m_selectionBuffer);
      p.end();
    }

    layer->dirty = true;
  }

  m_isTransforming = false;
  m_selectionBuffer = QImage();
  m_transformStaticCache = QImage();
  m_updateTransformTextures = false;

  // PUSH UNDO
  auto after = std::make_unique<artflow::ImageBuffer>(*layer->buffer);
  m_undoManager->pushCommand(std::make_unique<artflow::StrokeUndoCommand>(
      m_layerManager, m_activeLayerIndex, std::move(m_transformBeforeBuffer),
      std::move(after)));

  m_selectionPath = QPainterPath();
  m_hasSelection = false;
  emit isTransformingChanged();
  emit hasSelectionChanged();
  update();
}
```

---

## PARCHE 5 — Marching ants con timer persistente
**Problema:** `QTimer::singleShot(50, ...)` crea un objeto nuevo en **cada frame pintado**
mientras hay selección activa, acumulando timers y redraws extra.

### 5a) En `CanvasItem.h` — añadir miembro:
```cpp
QTimer *m_marchingAntsTimer = nullptr;
```

### 5b) En el constructor — después de `m_quickShapeTimer`:
```cpp
// Timer persistente para animación de marching ants
m_marchingAntsTimer = new QTimer(this);
m_marchingAntsTimer->setInterval(50); // 20fps — suficiente para la animación
connect(m_marchingAntsTimer, &QTimer::timeout, this, [this]() {
    if (!m_selectionPath.isEmpty())
        QQuickPaintedItem::update();
    else
        m_marchingAntsTimer->stop(); // auto-parar si no hay selección
});
```

### 5c) En `paint()` — localizar la sección de marching ants (~línea 785–787):

**ANTES:**
```cpp
    painter->restore();

    // Trigger a redraw for animation if selection exists
    QTimer::singleShot(50, this, [this]() { update(); });
  }
```

**DESPUÉS:**
```cpp
    painter->restore();

    // Arrancar el timer persistente si no está corriendo ya
    if (!m_marchingAntsTimer->isActive())
        m_marchingAntsTimer->start();
  }
```

### 5d) Cuando se limpia la selección (en `applyTransform`, `cancelTransform`,
### y donde hagas `m_selectionPath = QPainterPath()`), añadir:
```cpp
m_marchingAntsTimer->stop();
```

---

## Resumen: orden recomendado de aplicación

| # | Parche | Dificultad | Ganancia |
|---|--------|-----------|---------|
| 1 | Throttle `update()` | Baja | ⭐⭐⭐⭐⭐ — impacto inmediato |
| 5 | Timer marching ants | Baja | ⭐⭐⭐ |
| 2 | Skip `glCopyTexImage2D` en transform | Muy baja | ⭐⭐⭐⭐ |
| 3 | `compositeAll` en hilo secundario | Media | ⭐⭐⭐ — elimina freeze al activar |
| 4 | Commit GPU en `applyTransform` | Alta | ⭐⭐⭐⭐ — elimina freeze al confirmar |

Empieza por el **1, 5 y 2** — son cambios de pocas líneas y dan el mayor beneficio
de rendimiento durante el arrastre en tiempo real.
