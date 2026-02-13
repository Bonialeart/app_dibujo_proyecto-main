"""
ArtFlow Studio - Colors Panel
Panel de colores con selector de color, paletas y botón de borrador mejorado
"""

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QGridLayout,
    QPushButton, QLabel, QColorDialog, QFrame
)
from PyQt6.QtCore import Qt, pyqtSignal, QSize
from PyQt6.QtGui import QColor, QIcon, QPainter, QBrush, QPen


class ColorButton(QPushButton):
    """Botón de color circular mejorado."""
    
    color_selected = pyqtSignal(QColor)
    
    def __init__(self, color: QColor, size: int = 40):
        super().__init__()
        self._color = color
        self._size = size
        self.setFixedSize(size, size)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self._update_style()
        self.clicked.connect(self._on_clicked)
    
    def _update_style(self):
        """Actualizar estilo del botón."""
        self.setStyleSheet(f"""
            QPushButton {{
                background-color: {self._color.name()};
                border: 3px solid #3a3a5a;
                border-radius: {self._size // 2}px;
            }}
            QPushButton:hover {{
                border-color: #00d4aa;
                border-width: 4px;
            }}
            QPushButton:pressed {{
                border-color: #00ffcc;
            }}
        """)
    
    def _on_clicked(self):
        """Emitir señal cuando se hace clic."""
        self.color_selected.emit(self._color)
    
    def set_color(self, color: QColor):
        """Establecer nuevo color."""
        self._color = color
        self._update_style()


class EraserButton(QPushButton):
    """Botón de borrador con diseño profesional estilo Clip Studio Paint."""
    
    eraser_toggled = pyqtSignal(bool)  # True = borrador activo, False = pincel normal
    
    def __init__(self, size: int = 40):
        super().__init__()
        self._size = size
        self._is_eraser_mode = False
        self.setFixedSize(size, size)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setCheckable(True)  # Hacer que sea un botón toggle
        self.clicked.connect(self._on_clicked)
        self._update_style()
    
    def _update_style(self):
        """Actualizar estilo según el estado."""
        if self._is_eraser_mode:
            # Modo borrador activo - resaltado en cyan
            self.setStyleSheet(f"""
                QPushButton {{
                    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                        stop:0 #00d4aa, stop:1 #00a488);
                    border: 3px solid #00ffcc;
                    border-radius: {self._size // 2}px;
                    color: #0f0f1a;
                    font-size: 20px;
                    font-weight: bold;
                }}
                QPushButton:hover {{
                    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                        stop:0 #00ffcc, stop:1 #00d4aa);
                    border-color: #ffffff;
                }}
            """)
        else:
            # Modo pincel normal
            self.setStyleSheet(f"""
                QPushButton {{
                    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                        stop:0 #2a2a3e, stop:1 #1a1a2e);
                    border: 3px solid #3a3a5a;
                    border-radius: {self._size // 2}px;
                    color: #ffffff;
                    font-size: 18px;
                }}
                QPushButton:hover {{
                    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                        stop:0 #3a3a4e, stop:1 #2a2a3e);
                    border-color: #00d4aa;
                }}
            """)
        
        # Cambiar icono según el modo
        self.setText("🧹" if self._is_eraser_mode else "⌧")
    
    def _on_clicked(self):
        """Toggle entre modo borrador y pincel."""
        self._is_eraser_mode = not self._is_eraser_mode
        self._update_style()
        self.eraser_toggled.emit(self._is_eraser_mode)
    
    def set_eraser_mode(self, enabled: bool):
        """Establecer modo borrador programáticamente."""
        if self._is_eraser_mode != enabled:
            self._is_eraser_mode = enabled
            self.setChecked(enabled)
            self._update_style()


class TransparentPatternButton(QPushButton):
    """Botón con patrón de tablero de ajedrez para representar transparencia."""
    
    def __init__(self, size: int = 40):
        super().__init__()
        self.setFixedSize(size, size)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
    
    def paintEvent(self, event):
        """Dibujar patrón de tablero de ajedrez."""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Fondo del botón
        painter.setPen(QPen(QColor("#3a3a5a"), 3))
        painter.setBrush(QBrush(QColor("#1a1a2e")))
        painter.drawRoundedRect(self.rect().adjusted(2, 2, -2, -2), self.width() // 2, self.height() // 2)
        
        # Patrón de tablero de ajedrez
        square_size = self.width() // 6
        for row in range(6):
            for col in range(6):
                if (row + col) % 2 == 0:
                    color = QColor("#cccccc")
                else:
                    color = QColor("#999999")
                
                x = col * square_size + 5
                y = row * square_size + 5
                painter.fillRect(x, y, square_size, square_size, color)
        
        painter.end()


class ColorsPanel(QWidget):
    """Panel de colores con selector y paletas."""
    
    color_changed = pyqtSignal(QColor)
    eraser_mode_changed = pyqtSignal(bool)  # Nueva señal para modo borrador
    
    def __init__(self):
        super().__init__()
        self._current_color = QColor(255, 255, 255)  # Blanco por defecto
        self._previous_color = QColor(0, 0, 0)  # Negro
        self._setup_ui()
    
    def _setup_ui(self):
        """Configurar interfaz."""
        layout = QVBoxLayout(self)
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(16)
        
        # === Sección: Colores Principal y Secundario ===
        main_colors_layout = QHBoxLayout()
        main_colors_layout.setSpacing(12)
        
        # Color actual (grande)
        self.current_color_btn = ColorButton(self._current_color, 60)
        self.current_color_btn.color_selected.connect(self._show_color_picker)
        main_colors_layout.addWidget(self.current_color_btn)
        
        # Color anterior (pequeño, superpuesto)
        self.previous_color_btn = ColorButton(self._previous_color, 40)
        self.previous_color_btn.color_selected.connect(self._swap_colors)
        main_colors_layout.addWidget(self.previous_color_btn)
        
        # Botón de borrador
        self.eraser_btn = EraserButton(50)
        self.eraser_btn.eraser_toggled.connect(self._on_eraser_toggled)
        main_colors_layout.addWidget(self.eraser_btn)
        
        main_colors_layout.addStretch()
        layout.addLayout(main_colors_layout)
        
        # Separador
        separator = QFrame()
        separator.setFrameShape(QFrame.Shape.HLine)
        separator.setStyleSheet("background: #3a3a5a; max-height: 1px;")
        layout.addWidget(separator)
        
        # === Paleta de Colores Rápidos ===
        palette_label = QLabel("🎨 Paleta Rápida")
        palette_label.setStyleSheet("color: #ffffff; font-weight: bold; font-size: 13px;")
        layout.addWidget(palette_label)
        
        # Grid de colores
        self.palette_grid = QGridLayout()
        self.palette_grid.setSpacing(8)
        
        # Paleta de colores predefinida
        palette_colors = [
            # Fila 1: Grises y negro/blanco
            "#000000", "#3a3a3a", "#7a7a7a", "#b8b8b8", "#ffffff",
            # Fila 2: Colores primarios vibrantes
            "#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff",
            # Fila 3: Colores cálidos
            "#ff6b35", "#f7931e", "#fdc82f", "#8ac926", "#1982c4",
            # Fila 4: Colores fríos
            "#6a4c93", "#1982c4", "#8ac926", "#ffca3a", "#ff595e",
            # Fila 5: Tonos pastel
            "#ffb3ba", "#ffdfba", "#ffffba", "#baffc9", "#bae1ff",
        ]
        
        row, col = 0, 0
        for color_hex in palette_colors:
            btn = ColorButton(QColor(color_hex), 32)
            btn.color_selected.connect(self._on_palette_color_selected)
            self.palette_grid.addWidget(btn, row, col)
            col += 1
            if col >= 5:
                col = 0
                row += 1
        
        layout.addLayout(self.palette_grid)
        
        # Botón para selector de color avanzado
        pick_color_btn = QPushButton("🎨 Selector Avanzado")
        pick_color_btn.setStyleSheet("""
            QPushButton {
                background: #252540;
                color: #ffffff;
                border: 2px solid #3a3a5a;
                border-radius: 8px;
                padding: 10px;
                font-weight: bold;
                font-size: 12px;
            }
            QPushButton:hover {
                background: #2a2a50;
                border-color: #00d4aa;
            }
            QPushButton:pressed {
                background: #1a1a30;
            }
        """)
        pick_color_btn.clicked.connect(self._show_color_picker)
        layout.addWidget(pick_color_btn)
        
        layout.addStretch()
    
    def _show_color_picker(self):
        """Mostrar selector de color."""
        color = QColorDialog.getColor(self._current_color, self, "Seleccionar Color")
        if color.isValid():
            self._set_current_color(color)
    
    def _set_current_color(self, color: QColor):
        """Establecer color actual y emitir señal."""
        # Guardar color anterior
        self._previous_color = self._current_color
        self._current_color = color
        
        # Actualizar botones
        self.current_color_btn.set_color(color)
        self.previous_color_btn.set_color(self._previous_color)
        
        # Desactivar modo borrador al seleccionar un color
        if self.eraser_btn._is_eraser_mode:
            self.eraser_btn.set_eraser_mode(False)
            self.eraser_mode_changed.emit(False)
        
        # Emitir señal
        self.color_changed.emit(color)
    
    def _swap_colors(self):
        """Intercambiar color actual con anterior."""
        temp = self._current_color
        self._current_color = self._previous_color
        self._previous_color = temp
        
        self.current_color_btn.set_color(self._current_color)
        self.previous_color_btn.set_color(self._previous_color)
        
        self.color_changed.emit(self._current_color)
    
    def _on_palette_color_selected(self, color: QColor):
        """Manejar selección de color de la paleta."""
        self._set_current_color(color)
    
    def _on_eraser_toggled(self, is_eraser: bool):
        """Manejar activación/desactivación del borrador."""
        self.eraser_mode_changed.emit(is_eraser)
        
        # Feedback visual
        if is_eraser:
            print("🧹 Modo Borrador ACTIVADO")
        else:
            print("🖌️ Modo Pincel ACTIVADO")
    
    def get_current_color(self) -> QColor:
        """Obtener color actual."""
        return self._current_color
    
    def set_current_color(self, color: QColor):
        """Establecer color externamente."""
        self._set_current_color(color)
