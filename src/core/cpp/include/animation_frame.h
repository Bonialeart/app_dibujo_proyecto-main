#pragma once

#include "layer_manager.h"
#include <QTransform>

namespace artflow {

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

private:
    Layer* m_layerRef;
    int m_duration;
    float m_opacity;
    QTransform m_transform;
};

} // namespace artflow
