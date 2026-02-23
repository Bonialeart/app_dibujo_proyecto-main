#ifndef PREFERENCESMANAGER_H
#define PREFERENCESMANAGER_H

#include <QColor>
#include <QDir>
#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QVariantList>

class PreferencesManager : public QObject {
  Q_OBJECT
  // --- APPEARANCE ---
  Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY
                 settingsChanged)
  Q_PROPERTY(QString themeAccent READ themeAccent WRITE setThemeAccent NOTIFY
                 settingsChanged)
  Q_PROPERTY(
      QString language READ language WRITE setLanguage NOTIFY settingsChanged)

  // --- PERFORMANCE ---
  Q_PROPERTY(bool gpuAcceleration READ gpuAcceleration WRITE setGpuAcceleration
                 NOTIFY settingsChanged)
  Q_PROPERTY(
      int undoLevels READ undoLevels WRITE setUndoLevels NOTIFY settingsChanged)
  Q_PROPERTY(int memoryUsageLimit READ memoryUsageLimit WRITE
                 setMemoryUsageLimit NOTIFY settingsChanged)

  // --- CURSOR ---
  Q_PROPERTY(bool cursorShowOutline READ cursorShowOutline WRITE
                 setCursorShowOutline NOTIFY settingsChanged)
  Q_PROPERTY(bool cursorShowCrosshair READ cursorShowCrosshair WRITE
                 setCursorShowCrosshair NOTIFY settingsChanged)

  // --- TABLET ---
  Q_PROPERTY(QString tabletInputMode READ tabletInputMode WRITE
                 setTabletInputMode NOTIFY settingsChanged)

  // --- TOOLS ---
  Q_PROPERTY(int toolSwitchDelay READ toolSwitchDelay WRITE setToolSwitchDelay
                 NOTIFY settingsChanged)
  Q_PROPERTY(int dragDistance READ dragDistance WRITE setDragDistance NOTIFY
                 settingsChanged)
  Q_PROPERTY(bool autoSaveEnabled READ autoSaveEnabled WRITE setAutoSaveEnabled
                 NOTIFY settingsChanged)
  Q_PROPERTY(
      double uiScale READ uiScale WRITE setUiScale NOTIFY settingsChanged)

  // --- TOUCH GESTURES ---
  Q_PROPERTY(bool touchGesturesEnabled READ touchGesturesEnabled WRITE
                 setTouchGesturesEnabled NOTIFY settingsChanged)
  Q_PROPERTY(bool touchEyedropperEnabled READ touchEyedropperEnabled WRITE
                 setTouchEyedropperEnabled NOTIFY settingsChanged)
  Q_PROPERTY(bool multitouchUndoRedoEnabled READ multitouchUndoRedoEnabled WRITE
                 setMultitouchUndoRedoEnabled NOTIFY settingsChanged)

  Q_PROPERTY(QVariantList pressureCurve READ pressureCurve WRITE
                 setPressureCurve NOTIFY pressureCurveChanged)

public:
  static PreferencesManager *instance();

  explicit PreferencesManager(QObject *parent = nullptr) : QObject(parent) {
    m_instance = this;
    QString dataPath =
        QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(dataPath);
    m_settings = new QSettings(dataPath + "/user_preferences.ini",
                               QSettings::IniFormat, this);
  }

  // --- GETTERS ---
  QString themeMode() const {
    return m_settings->value("theme_mode", "Dark").toString();
  }
  QString themeAccent() const {
    return m_settings->value("theme_accent", "#6366f1").toString();
  }
  QString language() const {
    return m_settings->value("language", "es").toString();
  }
  bool gpuAcceleration() const {
    return m_settings->value("gpu_acceleration", true).toBool();
  }
  int undoLevels() const {
    return m_settings->value("undo_levels", 50).toInt();
  }
  int memoryUsageLimit() const {
    return m_settings->value("memory_usage_limit", 70).toInt();
  }
  bool cursorShowOutline() const {
    return m_settings->value("cursor_show_outline", true).toBool();
  }
  bool cursorShowCrosshair() const {
    return m_settings->value("cursor_show_crosshair", true).toBool();
  }
  QString tabletInputMode() const {
    return m_settings->value("tablet_input_mode", "WindowsInk").toString();
  }
  int toolSwitchDelay() const {
    return m_settings->value("tool_switch_delay", 500).toInt();
  }
  int dragDistance() const {
    return m_settings->value("drag_distance", 3).toInt();
  }
  bool autoSaveEnabled() const {
    return m_settings->value("auto_save_enabled", true).toBool();
  }
  double uiScale() const {
    return m_settings->value("ui_scale", 1.0).toDouble();
  }

  bool touchGesturesEnabled() const {
    return m_settings->value("touch_gestures_enabled", true).toBool();
  }
  bool touchEyedropperEnabled() const {
    return m_settings->value("touch_eyedropper_enabled", true).toBool();
  }
  bool multitouchUndoRedoEnabled() const {
    return m_settings->value("multitouch_undo_redo_enabled", true).toBool();
  }

  QVariantList pressureCurve() const {
    QVariantList defaultCurve;
    defaultCurve << 0.0 << 0.0 << 1.0 << 1.0;
    return m_settings->value("pressure_curve", defaultCurve).toList();
  }

public slots:
  // --- SETTERS ---
  void setThemeMode(const QString &mode) {
    if (themeMode() != mode) {
      m_settings->setValue("theme_mode", mode);
      emit settingsChanged();
    }
  }
  void setThemeAccent(const QString &accent) {
    if (themeAccent() != accent) {
      m_settings->setValue("theme_accent", accent);
      emit settingsChanged();
    }
  }
  void setLanguage(const QString &lang) {
    if (language() != lang) {
      m_settings->setValue("language", lang);
      emit settingsChanged();
    }
  }
  void setGpuAcceleration(bool enabled) {
    if (gpuAcceleration() != enabled) {
      m_settings->setValue("gpu_acceleration", enabled);
      emit settingsChanged();
    }
  }
  void setUndoLevels(int levels) {
    if (undoLevels() != levels) {
      m_settings->setValue("undo_levels", levels);
      emit settingsChanged();
    }
  }
  void setMemoryUsageLimit(int limit) {
    if (memoryUsageLimit() != limit) {
      m_settings->setValue("memory_usage_limit", limit);
      emit settingsChanged();
    }
  }
  void setCursorShowOutline(bool show) {
    if (cursorShowOutline() != show) {
      m_settings->setValue("cursor_show_outline", show);
      emit settingsChanged();
    }
  }
  void setCursorShowCrosshair(bool show) {
    if (cursorShowCrosshair() != show) {
      m_settings->setValue("cursor_show_crosshair", show);
      emit settingsChanged();
    }
  }
  void setTabletInputMode(const QString &mode) {
    if (tabletInputMode() != mode) {
      m_settings->setValue("tablet_input_mode", mode);
      emit settingsChanged();
    }
  }
  void setToolSwitchDelay(int delay) {
    if (toolSwitchDelay() != delay) {
      m_settings->setValue("tool_switch_delay", delay);
      emit settingsChanged();
    }
  }
  void setDragDistance(int distance) {
    if (dragDistance() != distance) {
      m_settings->setValue("drag_distance", distance);
      emit settingsChanged();
    }
  }
  void setAutoSaveEnabled(bool enabled) {
    if (autoSaveEnabled() != enabled) {
      m_settings->setValue("auto_save_enabled", enabled);
      emit settingsChanged();
    }
  }
  void setUiScale(double scale) {
    if (uiScale() != scale) {
      m_settings->setValue("ui_scale", scale);
      emit settingsChanged();
    }
  }
  void setTouchGesturesEnabled(bool enabled) {
    if (touchGesturesEnabled() != enabled) {
      m_settings->setValue("touch_gestures_enabled", enabled);
      emit settingsChanged();
    }
  }
  void setTouchEyedropperEnabled(bool enabled) {
    if (touchEyedropperEnabled() != enabled) {
      m_settings->setValue("touch_eyedropper_enabled", enabled);
      emit settingsChanged();
    }
  }
  void setMultitouchUndoRedoEnabled(bool enabled) {
    if (multitouchUndoRedoEnabled() != enabled) {
      m_settings->setValue("multitouch_undo_redo_enabled", enabled);
      emit settingsChanged();
    }
  }
  void setPressureCurve(const QVariantList &curve) {
    m_settings->setValue("pressure_curve", curve);
    emit pressureCurveChanged();
  }

  void resetDefaults() {
    m_settings->clear();
    emit settingsChanged();
    QVariantList defCurve;
    defCurve << 0.0 << 0.0 << 1.0 << 1.0;
    setPressureCurve(defCurve);
  }

signals:
  void settingsChanged();
  void pressureCurveChanged();

private:
  QSettings *m_settings;
  static PreferencesManager *m_instance;
};

#endif // PREFERENCESMANAGER_H
