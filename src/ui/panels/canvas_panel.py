"""
ArtFlow Studio - Canvas Panel (Refined with Brush Logic)
"""

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QFrame, QScrollArea, QSizePolicy
)
from PyQt6.QtCore import Qt, QPoint, QSize
from PyQt6.QtGui import QPainter, QColor, QPen, QImage, QPixmap, QMouseEvent, QWheelEvent
import numpy as np

from utils.simple_brush_logic import SimpleBrushEngine
from core.layer import Layer

class CanvasWidget(QWidget):
    """The actual drawing canvas widget with multi-layer support."""
    
    def __init__(self, width: int = 1920, height: int = 1080, parent=None):
        super().__init__(parent)
        
        self.canvas_width = width
        self.canvas_height = height
        self.zoom = 1.0
        
        # Color de fondo del lienzo (el "papel")
        self.canvas_bg_color = QColor(255, 255, 255) # Blanco por defecto
        
        # Sistema de CAPAS
        self.layers = []
        self.active_layer_index = 0
        
        # Añadir capa inicial
        self.add_layer("Capa 1")
        
        # Drawing state
        self.is_drawing = False
        self.last_point = None
        self.brush_size = 20
        self.brush_color = QColor(0, 0, 0)
        self.brush_opacity = 1.0
        self.brush_type = "default" # default, pencil, ink, airbrush, marker
        self.brush_mode = "normal"  # "normal" or "eraser"
        
        # Enable tablet events
        self.setAttribute(Qt.WidgetAttribute.WA_TabletTracking)
        self.setMouseTracking(True)
        
        # Background pattern (static for performance)
        self.bg_pattern = self._create_checkerboard_pattern()
        
        self._update_size()
    
    def add_layer(self, name: str):
        """Añadir una nueva capa ARRIBA."""
        new_layer = Layer(self.canvas_width, self.canvas_height, name)
        self.layers.insert(0, new_layer) # 0 es el tope en la UI
        self.active_layer_index = 0
        self.update()
        return new_layer

    def set_active_layer(self, index: int):
        """Establecer la capa activa para dibujar."""
        if 0 <= index < len(self.layers):
            self.active_layer_index = index
            print(f"🎨 Canvas: Capa activa cambiada a {index}")

    def set_canvas_background(self, color: QColor):
        """Cambiar el color del 'papel' de fondo."""
        self.canvas_bg_color = color
        self.update()

    def set_eraser_mode(self, enabled: bool):
        """Activar/desactivar modo borrador."""
        self.brush_mode = "eraser" if enabled else "normal"
        # Forzar actualización de la UI si es necesario
        self.update()
        print(f"🎨 Canvas: Modo {'Borrador' if enabled else 'Pincel'}")
    
    def _create_checkerboard_pattern(self):
        pixmap = QPixmap(32, 32)
        pixmap.fill(QColor(240, 240, 240))
        painter = QPainter(pixmap)
        color = QColor(200, 200, 200)
        painter.fillRect(0, 0, 16, 16, color)
        painter.fillRect(16, 16, 16, 16, color)
        painter.end()
        return pixmap
    
    def _update_size(self):
        """Update widget size based on zoom."""
        w = int(self.canvas_width * self.zoom)
        h = int(self.canvas_height * self.zoom)
        self.setFixedSize(w, h)
    
    def set_zoom(self, zoom: float):
        """Set canvas zoom level."""
        self.zoom = max(0.05, min(5.0, zoom))
        self._update_size()
        self.update()
    
    def paintEvent(self, event):
        """Render the canvas with multi-layer composition."""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform)
        
        # 1. Dibujar el patrón de transparencia (tablero de ajedrez)
        painter.drawTiledPixmap(self.rect(), self.bg_pattern)
        
        # 2. Dibujar el color de fondo del lienzo (el "papel")
        painter.fillRect(self.rect(), self.canvas_bg_color)
        
        # 3. Dibujar TODAS las capas (de abajo hacia arriba)
        target_rect = self.rect()
        # En la lista, el índice 0 es el TOPE. Así que dibujamos del final al principio.
        for layer in reversed(self.layers):
            if layer.visible:
                painter.setOpacity(layer.opacity)
                painter.drawImage(target_rect, layer.image)
        
    def mousePressEvent(self, event: QMouseEvent):
        if event.button() == Qt.MouseButton.LeftButton:
            if not self.layers or self.active_layer_index >= len(self.layers):
                return
                
            self.is_drawing = True
            pos = self._canvas_point(event.position())
            self.last_point = pos
            
            # Dibujar en la CAPA ACTIVA
            layer = self.layers[self.active_layer_index]
            painter = QPainter(layer.image)
            painter.setRenderHint(QPainter.RenderHint.Antialiasing)
            
            # CONFIGURACIÓN PROFESIONAL DEL BORRADOR
            if self.brush_mode == "eraser":
                # Usamos DestinationOut (estándar en Krita/Photoshop)
                painter.setCompositionMode(QPainter.CompositionMode.DestinationOut)
                # Para borrar necesitamos un color con ALPHA (el color da igual, pero el alpha no)
                draw_color = QColor(0, 0, 0, 255) 
            else:
                painter.setCompositionMode(QPainter.CompositionMode.SourceOver)
                draw_color = self.brush_color
                
            SimpleBrushEngine.draw_dab(
                painter, pos, self.brush_type, 
                draw_color, self.brush_size, self.brush_opacity
            )
            painter.end()
            self.update()
    
    def mouseMoveEvent(self, event: QMouseEvent):
        if self.is_drawing and self.last_point:
            if not self.layers or self.active_layer_index >= len(self.layers):
                return
                
            current = self._canvas_point(event.position())
            
            # Dibujar en la CAPA ACTIVA
            layer = self.layers[self.active_layer_index]
            painter = QPainter(layer.image)
            painter.setRenderHint(QPainter.RenderHint.Antialiasing)
            
            # CONFIGURACIÓN PROFESIONAL DEL BORRADOR
            if self.brush_mode == "eraser":
                painter.setCompositionMode(QPainter.CompositionMode.DestinationOut)
                draw_color = QColor(0, 0, 0, 255)
            else:
                painter.setCompositionMode(QPainter.CompositionMode.SourceOver)
                draw_color = self.brush_color
            
            # Use stamp-based engine for high precision (Krita style)
            SimpleBrushEngine.draw_line(
                painter, self.last_point, current,
                self.brush_type, draw_color, self.brush_size, self.brush_opacity
            )
            
            painter.end()
            self.last_point = current
            self.update()
    
    def mouseReleaseEvent(self, event: QMouseEvent):
        if event.button() == Qt.MouseButton.LeftButton:
            self.is_drawing = False
            self.last_point = None
    
    def wheelEvent(self, event: QWheelEvent):
        delta = event.angleDelta().y()
        factor = 1.1 if delta > 0 else 0.9
        self.set_zoom(self.zoom * factor)
    
    def _canvas_point(self, pos) -> QPoint:
        return QPoint(
            int(pos.x() / self.zoom),
            int(pos.y() / self.zoom)
        )
    
    def clear(self):
        """Limpiar la capa activa."""
        if 0 <= self.active_layer_index < len(self.layers):
            self.layers[self.active_layer_index].clear()
            self.update()


class CanvasPanel(QWidget):
    """Refined panel containing the canvas and viewport controls."""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._setup_ui()
    
    def _setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)
        
        # Viewport container (Gray background like Photoshop/Procreate workspace)
        self.viewport = QScrollArea()
        self.viewport.setWidgetResizable(True) 
        self.viewport.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.viewport.setStyleSheet("""
            QScrollArea {
                background-color: #282828;
                border: none;
            }
            QScrollBar {
                background: #333;
            }
        """)
        
        # Wrapper widget to center canvas if smaller than viewport
        self.scroll_content = QWidget()
        self.scroll_content.setStyleSheet("background: transparent;")
        scroll_layout = QVBoxLayout(self.scroll_content)
        scroll_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        self.canvas = CanvasWidget(2048, 2048)
        # Apply shadow to canvas to make it "pop"
        from PyQt6.QtWidgets import QGraphicsDropShadowEffect
        shadow = QGraphicsDropShadowEffect()
        shadow.setBlurRadius(20)
        shadow.setColor(QColor(0,0,0,100))
        self.canvas.setGraphicsEffect(shadow)
        
        scroll_layout.addWidget(self.canvas)
        self.viewport.setWidget(self.scroll_content)
        
        layout.addWidget(self.viewport)
    
    def create_new_canvas(self, width: int, height: int, dpi: int = 72):
        # Remove old canvas from layout
        layout = self.scroll_content.layout()
        if layout.count():
            item = layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
        
        # Create new one
        self.canvas = CanvasWidget(width, height)
        
        # Set DPI metadata
        dpm = int(dpi / 0.0254)
        self.canvas.canvas_image.setDotsPerMeterX(dpm)
        self.canvas.canvas_image.setDotsPerMeterY(dpm)
        
        # Apply shadow
        from PyQt6.QtWidgets import QGraphicsDropShadowEffect
        shadow = QGraphicsDropShadowEffect()
        shadow.setBlurRadius(25)
        shadow.setColor(QColor(0,0,0,150))
        self.canvas.setGraphicsEffect(shadow)
        
        layout.addWidget(self.canvas)
