#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>
#include "animation_track.h"
#include "layer_manager.h"

namespace artflow {

class AnimationManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(int currentFrame READ currentFrame WRITE setCurrentFrame NOTIFY currentFrameChanged)
    Q_PROPERTY(int fps READ fps WRITE setFps NOTIFY fpsChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playStateChanged)

public:
    explicit AnimationManager(LayerManager* layerManager = nullptr, QObject* parent = nullptr);

    int currentFrame() const { return m_currentFrame; }
    int fps() const { return m_fps; }
    bool isPlaying() const { return m_isPlaying; }

    const std::vector<AnimationTrack>& getTracks() const { return m_tracks; }
    std::vector<AnimationTrack>& getTracks() { return m_tracks; }

    Q_INVOKABLE void play();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setCurrentFrame(int frame);
    Q_INVOKABLE void setFps(int fps);

    // Pistas (Tracks) API
    Q_INVOKABLE int getTrackCount() const;
    Q_INVOKABLE QString getTrackName(int trackIdx) const;
    Q_INVOKABLE void setTrackName(int trackIdx, const QString& name);
    Q_INVOKABLE void addTrack(const QString& name);
    Q_INVOKABLE void removeTrack(int trackIdx);

    // Keyframes API
    Q_INVOKABLE void addKeyframe(int trackIdx, int frameIdx, int layerIdx);
    void addKeyframeRaw(int trackIdx, int frameIdx, Layer* layer);
    Q_INVOKABLE void addKeyframeWithParams(int trackIdx, int frameIdx, int layerIdx, float opacity, float tx, float ty, float scale, float rotation);
    void addKeyframeWithParamsRaw(int trackIdx, int frameIdx, Layer* layer, float opacity, float tx, float ty, float scale, float rotation);
    Q_INVOKABLE void removeKeyframe(int trackIdx, int frameIdx);
    Q_INVOKABLE bool hasKeyframe(int trackIdx, int frameIdx) const;
    Q_INVOKABLE QVariantMap getFrameProperties(int trackIdx, int frameIdx);

    // Keyframe editing (drag & drop / duplicate from the timeline)
    Q_INVOKABLE bool moveKeyframe(int trackIdx, int fromFrame, int toFrame);
    Q_INVOKABLE bool duplicateKeyframe(int trackIdx, int fromFrame, int toFrame);

    // Easing / interpolation curves. `easing` matches EasingType:
    // 0 Linear, 1 EaseIn, 2 EaseOut, 3 EaseInOut, 4 Bezier.
    Q_INVOKABLE void setKeyframeEasing(int trackIdx, int frameIdx, int easing,
                                       float x1 = 0.42f, float y1 = 0.0f,
                                       float x2 = 0.58f, float y2 = 1.0f);
    Q_INVOKABLE int getKeyframeEasing(int trackIdx, int frameIdx) const;
    // Shared curve math so QML-side animatables (e.g. the camera)
    // stay in sync with the C++ interpolator.
    Q_INVOKABLE qreal evaluateEasing(int easing, qreal t,
                                     qreal x1 = 0.42, qreal y1 = 0.0,
                                     qreal x2 = 0.58, qreal y2 = 1.0) const;

    Q_INVOKABLE bool exportVideo(const QString& path);

    void clear();
    void setLayerManager(LayerManager* manager) { m_layerManager = manager; }

signals:
    void currentFrameChanged(int frame);
    void fpsChanged(int fps);
    void playStateChanged();
    void tracksChanged();
    void frameUpdated();
    void notificationRequested(const QString& message, const QString& type);

private slots:
    void nextFrame();

private:
    std::vector<AnimationTrack> m_tracks;
    LayerManager* m_layerManager;
    int m_currentFrame;
    int m_fps;
    bool m_isPlaying;
    QTimer* m_timer;
};

} // namespace artflow
