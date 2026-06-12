#pragma once

#include "layer_manager.h"
#include <QTransform>

namespace artflow {

// Interpolation curve applied to the segment that LEAVES a keyframe
// (i.e. between this keyframe and the next one), After Effects style.
enum class EasingType {
    Linear = 0,
    EaseIn,
    EaseOut,
    EaseInOut,
    Bezier      // custom cubic bezier via control points
};

class AnimationFrame {
public:
    AnimationFrame()
        : m_layerRef(nullptr), m_duration(1), m_opacity(1.0f), m_transform(QTransform()) {}

    AnimationFrame(Layer* layerRef, int duration = 1, float opacity = 1.0f, const QTransform& transform = QTransform())
        : m_layerRef(layerRef), m_duration(duration), m_opacity(opacity), m_transform(transform) {}

    Layer* getLayerRef() const { return m_layerRef; }
    void setLayerRef(Layer* layer) { m_layerRef = layer; }

    int getDuration() const { return m_duration; }
    void setDuration(int duration) { m_duration = duration; }

    float getOpacity() const { return m_opacity; }
    void setOpacity(float opacity) { m_opacity = opacity; }

    QTransform getTransform() const { return m_transform; }
    void setTransform(const QTransform& transform) { m_transform = transform; }

    bool isKeyframe() const { return m_layerRef != nullptr; }

    EasingType getEasing() const { return m_easing; }
    void setEasing(EasingType easing) { m_easing = easing; }

    // Custom cubic-bezier control points (x1, y1, x2, y2), only
    // meaningful when m_easing == EasingType::Bezier.
    void setBezierHandles(float x1, float y1, float x2, float y2) {
        m_bezier[0] = x1; m_bezier[1] = y1; m_bezier[2] = x2; m_bezier[3] = y2;
    }
    const float* getBezierHandles() const { return m_bezier; }

private:
    Layer* m_layerRef;
    int m_duration;
    float m_opacity;
    QTransform m_transform;
    EasingType m_easing = EasingType::Linear;
    float m_bezier[4] = { 0.42f, 0.0f, 0.58f, 1.0f };
};

} // namespace artflow
