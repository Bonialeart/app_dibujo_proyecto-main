"""
ArtFlow Studio - Brush Engine Fix
Logic to actually switch brush characteristics
"""

from PyQt6.QtGui import QColor, QPen, QBrush, QPainter, QRadialGradient, QConicalGradient
from PyQt6.QtCore import Qt, QPoint

class SimpleBrushEngine:
    """Professional stamp-based brush engine (Krita style)."""
    
    @staticmethod
    def draw_dab(painter: QPainter, point: QPoint, brush_type: str, color: QColor, size: float, opacity: float):
        """Draw a single brush stamp (dab)."""
        effective_color = QColor(color)
        effective_color.setAlphaF(opacity)
        
        # Reset painter tools for this stamp
        painter.setPen(Qt.PenStyle.NoPen)
        
        if brush_type == "soft" or brush_type == "airbrush":
            # Radial gradient for soft edges
            grad = QRadialGradient(point, size / 2)
            grad.setColorAt(0, effective_color)
            color_transparent = QColor(effective_color)
            color_transparent.setAlphaF(0)
            grad.setColorAt(1, color_transparent)
            painter.setBrush(QBrush(grad))
            painter.drawEllipse(point, int(size/2), int(size/2))
            
        elif brush_type == "pencil" or brush_type == "hard":
            # Hard edges
            painter.setBrush(QBrush(effective_color))
            painter.drawEllipse(point, int(size/2), int(size/2))
            
        elif brush_type == "marker":
            # Square cap, semi-transparent
            mark_opacity = min(opacity, 0.4)
            effective_color.setAlphaF(mark_opacity)
            painter.setBrush(QBrush(effective_color))
            painter.drawRect(int(point.x() - size/2), int(point.y() - size/2), int(size), int(size))
            
        else: # "default" or "round"
            # Solid round dab
            painter.setBrush(QBrush(effective_color))
            painter.drawEllipse(point, int(size/2), int(size/2))

    @staticmethod
    def draw_line(painter: QPainter, p1: QPoint, p2: QPoint, brush_type: str, color: QColor, size: float, opacity: float):
        """Draw a continuous stroke using interpolated dabs."""
        # Calculate distance and steps for interpolation
        # Interpolation ensures smooth lines even with fast mouse/tablet movements
        dx = p2.x() - p1.x()
        dy = p2.y() - p1.y()
        distance = (dx**2 + dy**2)**0.5
        
        # Number of stamps to draw (spacing = 1/5 of size for smoothness)
        spacing = max(1.0, size / 10.0)
        steps = int(distance / spacing)
        
        if steps <= 1:
            SimpleBrushEngine.draw_dab(painter, p2, brush_type, color, size, opacity)
            return

        for i in range(steps + 1):
            t = i / steps
            px = int(p1.x() + dx * t)
            py = int(p1.y() + dy * t)
            SimpleBrushEngine.draw_dab(painter, QPoint(px, py), brush_type, color, size, opacity)
