#include "animation_manager.h"

namespace artflow {

AnimationManager::AnimationManager(LayerManager* layerManager, QObject* parent)
    : QObject(parent)
    , m_layerManager(layerManager)
    , m_currentFrame(0)
    , m_fps(24)
    , m_isPlaying(false)
{
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &AnimationManager::nextFrame);
}

void AnimationManager::play() {
    if (m_isPlaying) return;
    m_isPlaying = true;
    m_timer->start(1000 / m_fps);
    emit playStateChanged();
}

void AnimationManager::stop() {
    if (!m_isPlaying) return;
    m_isPlaying = false;
    m_timer->stop();
    emit playStateChanged();
}

void AnimationManager::setCurrentFrame(int frame) {
    if (m_currentFrame == frame) return;
    m_currentFrame = frame;
    emit currentFrameChanged(m_currentFrame);
    emit frameUpdated();
}

void AnimationManager::setFps(int fps) {
    if (m_fps == fps) return;
    m_fps = std::max(1, fps);
    if (m_isPlaying) {
        m_timer->start(1000 / m_fps);
    }
    emit fpsChanged(m_fps);
}

int AnimationManager::getTrackCount() const {
    return static_cast<int>(m_tracks.size());
}

QString AnimationManager::getTrackName(int trackIdx) const {
    if (trackIdx >= 0 && trackIdx < getTrackCount()) {
        return QString::fromStdString(m_tracks[trackIdx].getName());
    }
    return "";
}

void AnimationManager::setTrackName(int trackIdx, const QString& name) {
    if (trackIdx >= 0 && trackIdx < getTrackCount()) {
        m_tracks[trackIdx].setName(name.toStdString());
        emit tracksChanged();
    }
}

void AnimationManager::addTrack(const QString& name) {
    m_tracks.push_back(AnimationTrack(name.toStdString()));
    emit tracksChanged();
}

void AnimationManager::removeTrack(int trackIdx) {
    if (trackIdx >= 0 && trackIdx < getTrackCount()) {
        m_tracks.erase(m_tracks.begin() + trackIdx);
        emit tracksChanged();
        emit frameUpdated();
    }
}

void AnimationManager::addKeyframe(int trackIdx, int frameIdx, int layerIdx) {
    if (m_layerManager && trackIdx >= 0 && trackIdx < getTrackCount()) {
        Layer* layer = m_layerManager->getLayer(layerIdx);
        if (layer) {
            m_tracks[trackIdx].addKeyframe(frameIdx, layer);
            emit frameUpdated();
        }
    }
}

void AnimationManager::addKeyframeRaw(int trackIdx, int frameIdx, Layer* layer) {
    if (trackIdx >= 0 && trackIdx < getTrackCount() && layer) {
        m_tracks[trackIdx].addKeyframe(frameIdx, layer);
        emit frameUpdated();
    }
}

void AnimationManager::addKeyframeWithParams(int trackIdx, int frameIdx, int layerIdx, float opacity, float tx, float ty, float scale, float rotation) {
    if (m_layerManager && trackIdx >= 0 && trackIdx < getTrackCount()) {
        Layer* layer = m_layerManager->getLayer(layerIdx);
        if (layer) {
            QTransform transform;
            transform.translate(tx, ty);
            transform.scale(scale, scale);
            transform.rotate(rotation);
            m_tracks[trackIdx].addKeyframe(frameIdx, AnimationFrame(layer, 1, opacity, transform));
            emit frameUpdated();
        }
    }
}

void AnimationManager::addKeyframeWithParamsRaw(int trackIdx, int frameIdx, Layer* layer, float opacity, float tx, float ty, float scale, float rotation) {
    if (trackIdx >= 0 && trackIdx < getTrackCount() && layer) {
        QTransform transform;
        transform.translate(tx, ty);
        transform.scale(scale, scale);
        transform.rotate(rotation);
        m_tracks[trackIdx].addKeyframe(frameIdx, AnimationFrame(layer, 1, opacity, transform));
        emit frameUpdated();
    }
}

void AnimationManager::removeKeyframe(int trackIdx, int frameIdx) {
    if (trackIdx >= 0 && trackIdx < getTrackCount()) {
        m_tracks[trackIdx].removeKeyframe(frameIdx);
        emit frameUpdated();
    }
}

bool AnimationManager::hasKeyframe(int trackIdx, int frameIdx) const {
    if (trackIdx >= 0 && trackIdx < getTrackCount()) {
        const auto& keys = m_tracks[trackIdx].getKeyframes();
        return keys.find(frameIdx) != keys.end();
    }
    return false;
}

bool AnimationManager::moveKeyframe(int trackIdx, int fromFrame, int toFrame) {
    if (trackIdx < 0 || trackIdx >= getTrackCount() || toFrame < 0) return false;
    if (!m_tracks[trackIdx].moveKeyframe(fromFrame, toFrame)) return false;
    emit frameUpdated();
    return true;
}

bool AnimationManager::duplicateKeyframe(int trackIdx, int fromFrame, int toFrame) {
    if (trackIdx < 0 || trackIdx >= getTrackCount() || toFrame < 0) return false;
    if (!m_tracks[trackIdx].duplicateKeyframe(fromFrame, toFrame)) return false;
    emit frameUpdated();
    return true;
}

void AnimationManager::setKeyframeEasing(int trackIdx, int frameIdx, int easing,
                                         float x1, float y1, float x2, float y2) {
    if (trackIdx < 0 || trackIdx >= getTrackCount()) return;
    auto& keys = m_tracks[trackIdx].getKeyframes();
    auto it = keys.find(frameIdx);
    if (it == keys.end()) return;
    easing = std::max(0, std::min(easing, int(EasingType::Bezier)));
    it->second.setEasing(static_cast<EasingType>(easing));
    if (static_cast<EasingType>(easing) == EasingType::Bezier) {
        it->second.setBezierHandles(x1, y1, x2, y2);
    }
    emit frameUpdated();
}

int AnimationManager::getKeyframeEasing(int trackIdx, int frameIdx) const {
    if (trackIdx < 0 || trackIdx >= getTrackCount()) return 0;
    const auto& keys = m_tracks[trackIdx].getKeyframes();
    auto it = keys.find(frameIdx);
    if (it == keys.end()) return 0;
    return static_cast<int>(it->second.getEasing());
}

qreal AnimationManager::evaluateEasing(int easing, qreal t,
                                       qreal x1, qreal y1, qreal x2, qreal y2) const {
    float bz[4] = { float(x1), float(y1), float(x2), float(y2) };
    easing = std::max(0, std::min(easing, int(EasingType::Bezier)));
    return evalEasing(static_cast<EasingType>(easing), float(t), bz);
}

QVariantMap AnimationManager::getFrameProperties(int trackIdx, int frameIdx) {
    QVariantMap map;
    if (trackIdx >= 0 && trackIdx < getTrackCount()) {
        AnimationFrame frame = m_tracks[trackIdx].getFrame(frameIdx);
        map["opacity"] = frame.getOpacity();
        map["isKeyframe"] = frame.isKeyframe();
        
        QTransform t = frame.getTransform();
        map["tx"] = t.dx();
        map["ty"] = t.dy();
        map["m11"] = t.m11();
        map["m12"] = t.m12();
        map["m21"] = t.m21();
        map["m22"] = t.m22();
    }
    return map;
}

bool AnimationManager::exportVideo(const QString& path) {
    qDebug() << "Exporting video to path:" << path << "at FPS:" << m_fps;
    emit notificationRequested("Video export started (Stub)", "info");
    return true;
}

void AnimationManager::clear() {
    m_tracks.clear();
    m_currentFrame = 0;
    m_isPlaying = false;
    m_timer->stop();
    emit currentFrameChanged(m_currentFrame);
    emit playStateChanged();
    emit tracksChanged();
    emit frameUpdated();
}

void AnimationManager::nextFrame() {
    int maxFrame = 100;
    for (const auto& track : m_tracks) {
        if (!track.getKeyframes().empty()) {
            maxFrame = std::max(maxFrame, track.getKeyframes().rbegin()->first);
        }
    }
    
    int next = m_currentFrame + 1;
    if (next > maxFrame) {
        next = 0;
    }
    setCurrentFrame(next);
}

} // namespace artflow
