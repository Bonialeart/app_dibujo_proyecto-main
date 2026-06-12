#pragma once

#include "animation_frame.h"
#include <string>
#include <map>
#include <cmath>

namespace artflow {

// ── Easing evaluation ─────────────────────────────────────────
// Evaluates a cubic bezier easing curve defined by control points
// (x1,y1) and (x2,y2) at progress t (0..1). Solves x(u)=t with
// Newton-Raphson and returns y(u).
inline float evalCubicBezier(float t, float x1, float y1, float x2, float y2) {
    if (t <= 0.0f) return 0.0f;
    if (t >= 1.0f) return 1.0f;
    float u = t;
    for (int i = 0; i < 8; ++i) {
        float omu = 1.0f - u;
        float x = 3.0f * u * omu * omu * x1 + 3.0f * u * u * omu * x2 + u * u * u;
        float dx = 3.0f * omu * omu * x1 + 6.0f * u * omu * (x2 - x1) + 3.0f * u * u * (1.0f - x2);
        float err = x - t;
        if (std::fabs(err) < 1e-5f) break;
        if (std::fabs(dx) < 1e-6f) break;
        u -= err / dx;
        if (u < 0.0f) u = 0.0f;
        if (u > 1.0f) u = 1.0f;
    }
    float omu = 1.0f - u;
    return 3.0f * u * omu * omu * y1 + 3.0f * u * u * omu * y2 + u * u * u;
}

inline float evalEasing(EasingType easing, float t, const float* bz = nullptr) {
    switch (easing) {
        case EasingType::EaseIn:    return evalCubicBezier(t, 0.42f, 0.0f, 1.0f, 1.0f);
        case EasingType::EaseOut:   return evalCubicBezier(t, 0.0f, 0.0f, 0.58f, 1.0f);
        case EasingType::EaseInOut: return evalCubicBezier(t, 0.42f, 0.0f, 0.58f, 1.0f);
        case EasingType::Bezier:
            if (bz) return evalCubicBezier(t, bz[0], bz[1], bz[2], bz[3]);
            return t;
        case EasingType::Linear:
        default:
            return t;
    }
}

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

    // Moves a keyframe to another frame index. If the destination
    // is occupied it is replaced. Returns false if the source
    // doesn't exist.
    bool moveKeyframe(int fromIndex, int toIndex) {
        if (fromIndex == toIndex) return true;
        auto it = m_keyframes.find(fromIndex);
        if (it == m_keyframes.end()) return false;
        AnimationFrame frame = it->second;
        m_keyframes.erase(it);
        m_keyframes[toIndex] = frame;
        return true;
    }

    bool duplicateKeyframe(int fromIndex, int toIndex) {
        auto it = m_keyframes.find(fromIndex);
        if (it == m_keyframes.end()) return false;
        m_keyframes[toIndex] = it->second;
        return true;
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

        // Apply the easing curve of the segment's leading keyframe
        t = evalEasing(a.getEasing(), t, a.getBezierHandles());

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
