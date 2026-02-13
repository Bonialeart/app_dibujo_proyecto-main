"""
EJEMPLO: Cómo implementar el modo borrador en tu Canvas

Este archivo muestra cómo agregar la funcionalidad de borrador a tu clase Canvas.
Debes agregar estos métodos a tu archivo canvas existente.
"""

from PyQt6.QtWidgets import QWidget
from PyQt6.QtCore import Qt, QPoint
from PyQt6.QtGui import QPainter, QColor, QPen, QBrush, QPainterPath
from enum import Enum


class BrushMode(Enum):
    """Enum para los modos de dibujo."""
    NORMAL = 0
    ERASER = 1


class CanvasExample(QWidget):
    """Ejemplo de Canvas con modo borrador integrado."""
    
    def __init__(self):
        super().__init__()
        
        # Estado del pincel
        self.brush_color = QColor(0, 0, 0)
        self.brush_size = 20
        self.brush_opacity = 1.0
        self.brush_mode = BrushMode.NORMAL  # NUEVA VARIABLE
        
        # Estado del dibujo
        self.is_drawing = False
        self.last_point = QPoint()
        
        # Canvas buffer
        self.image = None
    
    def set_eraser_mode(self, enabled: bool):
        """
        MÉTODO PRINCIPAL: Activar/desactivar modo borrador.
        
        Args:
            enabled: True para activar borrador, False para pincel normal
        """
        if enabled:
            self.brush_mode = BrushMode.ERASER
            print("🧹 Modo Borrador ACTIVADO")
        else:
            self.brush_mode = BrushMode.NORMAL
            print("🖌️ Modo Pincel ACTIVADO")
    
    def mousePressEvent(self, event):
        """Iniciar trazo."""
        if event.button() == Qt.MouseButton.LeftButton:
            self.is_drawing = True
            self.last_point = event.pos()
    
    def mouseMoveEvent(self, event):
        """Continuar trazo."""
        if self.is_drawing:
            self.draw_line(self.last_point, event.pos())
            self.last_point = event.pos()
            self.update()
    
    def mouseReleaseEvent(self, event):
        """Terminar trazo."""
        if event.button() == Qt.MouseButton.LeftButton:
            self.is_drawing = False
    
    def draw_line(self, start: QPoint, end: QPoint):
        """
        Dibujar línea (o borrar si está en modo borrador).
        
        IMPORTANTE: Este es el método donde implementas la lógica de borrador.
        """
        if self.image is None:
            return
        
        painter = QPainter(self.image)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # === LÓGICA DEL MODO BORRADOR ===
        if self.brush_mode == BrushMode.ERASER:
            # OPCIÓN 1: Usar CompositionMode_DestinationOut (RECOMENDADO)
            # Esto "borra" haciendo transparente lo que hay debajo
            painter.setCompositionMode(QPainter.CompositionMode.CompositionMode_DestinationOut)
            
            # El color no importa, pero el alpha SÍ
            # Alpha = 255 borra completamente
            # Alpha < 255 borra parcialmente (borrador suave)
            eraser_color = QColor(0, 0, 0, 255)
            
            pen = QPen(eraser_color)
            pen.setWidth(self.brush_size)
            pen.setCapStyle(Qt.PenCapStyle.RoundCap)
            pen.setJoinStyle(Qt.PenJoinStyle.RoundJoin)
            
            painter.setPen(pen)
            painter.drawLine(start, end)
            
        else:
            # MODO PINCEL NORMAL
            painter.setCompositionMode(QPainter.CompositionMode.CompositionMode_SourceOver)
            
            # Aplicar opacidad al color
            brush_color = QColor(self.brush_color)
            brush_color.setAlphaF(self.brush_opacity)
            
            pen = QPen(brush_color)
            pen.setWidth(self.brush_size)
            pen.setCapStyle(Qt.PenCapStyle.RoundCap)
            pen.setJoinStyle(Qt.PenJoinStyle.RoundJoin)
            
            painter.setPen(pen)
            painter.drawLine(start, end)
        
        painter.end()


# =============================================================================
# INTEGRACIÓN CON EL SISTEMA C++ (brush_engine.cpp)
# =============================================================================

"""
Si estás usando el brush_engine.cpp, necesitas modificar la función paintStroke:

En brush_engine.cpp, línea ~175, REEMPLAZA:

  if (settings.type == BrushSettings::Type::Eraser) {
    // Usamos DestinationOut para "restar" de la capa actual.
    painter->setCompositionMode(QPainter::CompositionMode_DestinationOut);
    const_cast<BrushSettings&>(settings).color = QColor(0, 0, 0, 255);
  } else {
    painter->setCompositionMode(QPainter::CompositionMode_SourceOver);
  }

IMPORTANTE: Asegúrate de que tu BrushSettings tenga un enum Type con Eraser:

enum class Type {
    Normal = 0,
    Eraser = 1,
    // ... otros tipos
};

Y en Python, cuando actives el modo borrador, establece:

    self.brush_settings.type = BrushSettings.Type.Eraser

"""

# =============================================================================
# EJEMPLO DE USO COMPLETO EN TU CÓDIGO
# =============================================================================

"""
1. En tu archivo canvas.py (o como se llame), agrega:

   class Canvas(QWidget):
       def __init__(self):
           super().__init__()
           self.brush_mode = BrushMode.NORMAL
           # ... resto del código
       
       def set_eraser_mode(self, enabled: bool):
           if enabled:
               self.brush_mode = BrushMode.ERASER
           else:
               self.brush_mode = BrushMode.NORMAL
       
       def draw_line(self, start, end):
           # ... implementación como en el ejemplo de arriba

2. En main_window.py, conecta la señal:

   def _on_eraser_mode_changed(self, is_eraser: bool):
       self.canvas_panel.canvas.set_eraser_mode(is_eraser)

3. En colors_panel.py, el botón ya está configurado para emitir:

   self.eraser_btn.eraser_toggled.emit(is_eraser)

¡Y listo! El sistema completo funcionará.
"""

# =============================================================================
# DEBUGGING TIPS
# =============================================================================

"""
Si el borrador sigue dibujando negro en vez de borrar:

1. VERIFICA que estás usando CompositionMode_DestinationOut
2. VERIFICA que el canvas tenga fondo TRANSPARENTE (no blanco)
   - self.image = QImage(w, h, QImage.Format_ARGB32_Premultiplied)
   - self.image.fill(Qt.GlobalColor.transparent)
3. VERIFICA que el color del borrador tenga alpha = 255
4. Si usas layers/capas, asegúrate de borrar en la capa actual
5. Verifica que painter.end() se llame después de dibujar

Si el borrador funciona pero deja "bolitas":
- Reduce el spacing del brush
- Usa RoundCap y RoundJoin
- Implementa interpolación entre puntos
"""
