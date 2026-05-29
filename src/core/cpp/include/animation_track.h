#pragma once

#include "animation_frame.h"
#include <string>
#include <map>

namespace artflow {

class AnimationTrack {
public:
    AnimationTrack(const std::string& name = "Track")
        : m_name(name) {}

    const std::string& getName() const { return m_name; }
    void setName(const std::string& name) { m_name = name; }

    const std::map<int, AnimationFrame>& getKeyframes() const { return m_keyframes; }
    std::map<int, AnimationFrame>& getKeyframes() { return m_keyframes; }

    void addKeyframe(int index, Layer* layer) {
        m_keyframes[index] = AnimationFrame(layer);
    }

    void addKeyframe(int index, const AnimationFrame& frame) {
        m_keyframes[index] = frame;
    }

    void removeKeyframe(int index) {
        m_keyframes.erase(index);
    }

    AnimationFrame getFrame(int index) {
        if (m_keyframes.empty()) {
            return AnimationFrame();
        }

        // Exact match
        auto it = m_keyframes.find(index);
        if (it != m_keyframes.end()) {
            return it->second;
        }

        // Find previous and next keyframes
        auto nextIt = m_keyframes.upper_bound(index);
        if (nextIt == m_keyframes.begin()) {
            // Index is before the first keyframe, return the first keyframe without interpolating
            return nextIt->second;
        }

        auto prevIt = std::prev(nextIt);

        if (nextIt == m_keyframes.end()) {
            // Index is after the last keyframe, return the last keyframe
            return prevIt->second;
        }

        // Interpolation between prevIt and nextIt
        int prevIdx = prevIt->first;
        int nextIdx = nextIt->first;
        float t = float(index - prevIdx) / float(nextIdx - prevIdx);

        const AnimationFrame& a = prevIt->second;
        const AnimationFrame& b = nextIt->second;

        float opacity = a.getOpacity() * (1.0f - t) + b.getOpacity() * t;

        qreal m11 = a.getTransform().m11() * (1.0 - t) + b.getTransform().m11() * t;
        qreal m12 = a.getTransform().m12() * (1.0 - t) + b.getTransform().m12() * t;
        qreal m13 = a.getTransform().m13() * (1.0 - t) + b.getTransform().m13() * t;
        qreal m21 = a.getTransform().m21() * (1.0 - t) + b.getTransform().m21() * t;
        qreal m22 = a.getTransform().m22() * (1.0 - t) + b.getTransform().m22() * t;
        qreal m23 = a.getTransform().m23() * (1.0 - t) + b.getTransform().m23() * t;
        qreal m31 = a.getTransform().m31() * (1.0 - t) + b.getTransform().m31() * t;
        qreal m32 = a.getTransform().m32() * (1.0 - t) + b.getTransform().m32() * t;
        qreal m33 = a.getTransform().m33() * (1.0 - t) + b.getTransform().m33() * t;
        QTransform interpTransform(m11, m12, m13, m21, m22, m23, m31, m32, m33);

        AnimationFrame interpFrame(a.getLayerRef(), a.getDuration(), opacity, interpTransform);
        return interpFrame;
    }

private:
    std::string m_name;
    std::map<int, AnimationFrame> m_keyframes;
};

} // namespace artflow
