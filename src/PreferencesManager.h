#ifndef PREFERENCESMANAGER_H
#define PREFERENCESMANAGER_H

#include <QColor>
#include <QDir>
#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QVariantList>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonValue>
#include <QDebug>

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

  // --- SHORTCUTS ---
  Q_PROPERTY(QVariantMap shortcuts READ shortcuts WRITE setShortcuts NOTIFY
                 shortcutsChanged)

  // --- CUSTOM UI VISIBILITY PREFERENCES ---
  Q_PROPERTY(bool showTopProjectInfo READ showTopProjectInfo WRITE setShowTopProjectInfo NOTIFY settingsChanged)
  Q_PROPERTY(bool showTopBrushControls READ showTopBrushControls WRITE setShowTopBrushControls NOTIFY settingsChanged)
  Q_PROPERTY(bool showTopActionButtons READ showTopActionButtons WRITE setShowTopActionButtons NOTIFY settingsChanged)
  Q_PROPERTY(bool showTopSymmetryUndoRedo READ showTopSymmetryUndoRedo WRITE setShowTopSymmetryUndoRedo NOTIFY settingsChanged)
  Q_PROPERTY(bool showTopWorkspaceSwitcher READ showTopWorkspaceSwitcher WRITE setShowTopWorkspaceSwitcher NOTIFY settingsChanged)
  Q_PROPERTY(bool showRightToolbar READ showRightToolbar WRITE setShowRightToolbar NOTIFY settingsChanged)
  Q_PROPERTY(bool showRightColorSelector READ showRightColorSelector WRITE setShowRightColorSelector NOTIFY settingsChanged)

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

  // --- UI VISIBILITY GETTERS ---
  bool showTopProjectInfo() const {
    return m_settings->value("show_top_project_info", true).toBool();
  }
  bool showTopBrushControls() const {
    return m_settings->value("show_top_brush_controls", true).toBool();
  }
  bool showTopActionButtons() const {
    return m_settings->value("show_top_action_buttons", true).toBool();
  }
  bool showTopSymmetryUndoRedo() const {
    return m_settings->value("show_top_symmetry_undo_redo", true).toBool();
  }
  bool showTopWorkspaceSwitcher() const {
    return m_settings->value("show_top_workspace_switcher", true).toBool();
  }
  bool showRightToolbar() const {
    return m_settings->value("show_right_toolbar", true).toBool();
  }
  bool showRightColorSelector() const {
    return m_settings->value("show_right_color_selector", true).toBool();
  }

  QVariantList pressureCurve() const {
    QVariant val = m_settings->value("pressure_curve");
    QVariantList result;
    QStringList parts;
    if (val.userType() == QMetaType::QString) {
        parts = val.toString().remove("\"").split(",");
    } else {
        parts = val.toStringList();
    }
    
    // DEBUG LOGGING TO FILE
    QFile debugFile("e:/Programacion/Rescate_Proyecto/debug_curve.txt");
    if(debugFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
        QTextStream out(&debugFile);
        out << "GETTER: Raw QVariant type: " << val.typeName() << " - value: " << val.toString() << "\n";
        out << "GETTER: Parsed parts: " << parts.join("|") << "\n";
        debugFile.close();
    }
    
    for (const auto &s : parts) {
      bool ok;
      double v = s.trimmed().toDouble(&ok);
      if (ok) {
        result << v;
      } else {
        // DEBUG: LOG PARSE FAILURE
        QFile debugFile("e:/Programacion/Rescate_Proyecto/debug_curve.txt");
        if(debugFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
            QTextStream out(&debugFile);
            out << "GETTER: FAILED to parse double from: " << s << "\n";
            debugFile.close();
        }
      }
    }
    
    // Fallback if parsing failed or curve is too short (needs at least 2 points / 4 values)
    if (result.size() < 4) {
      QFile debugFile("e:/Programacion/Rescate_Proyecto/debug_curve.txt");
      if(debugFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
          QTextStream out(&debugFile);
          out << "GETTER: FALLBACK TRIGGERED. Result size is: " << result.size() << "\n";
          debugFile.close();
      }
      
      QVariantList defaultCurve;
      defaultCurve << 0.0 << 0.0 << 0.5 << 0.5 << 1.0 << 1.0;
      return defaultCurve;
    }
    
    QFile debugFile2("e:/Programacion/Rescate_Proyecto/debug_curve.txt");
    if(debugFile2.open(QIODevice::WriteOnly | QIODevice::Append)) {
        QTextStream out(&debugFile2);
        out << "GETTER: SUCCESS! Parsed " << result.size() << " doubles.\n";
        debugFile2.close();
    }
    
    return result;
  }

  QVariantMap shortcuts() const {
    QVariantMap def;
    def["New Project"] = "Ctrl+N";
    def["Open Project"] = "Ctrl+O";
    def["Save"] = "Ctrl+S";
    def["Undo"] = "Ctrl+Z";
    def["Redo"] = "Ctrl+Y";
    def["New Layer"] = "Ctrl+Shift+N";
    def["Pen Tool"] = "P";
    def["Brush Tool"] = "B";
    def["Eraser Tool"] = "E";
    def["Lasso Tool"] = "L";
    def["Hand Tool"] = "H";
    def["Eyedropper Tool"] = "I";
    def["Move Tool"] = "V";
    def["Transform"] = "Ctrl+T";
    def["Select None"] = "Ctrl+D";
    def["Zoom In"] = "Ctrl++";
    def["Zoom Out"] = "Ctrl+-";
    def["Fit to Screen"] = "Ctrl+0";
    return m_settings->value("shortcuts", def).toMap();
  }

  Q_INVOKABLE QString getShortcut(const QString &name) const {
    return shortcuts().value(name).toString();
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

  // --- UI VISIBILITY SETTERS ---
  void setShowTopProjectInfo(bool show) {
    if (showTopProjectInfo() != show) {
      m_settings->setValue("show_top_project_info", show);
      emit settingsChanged();
    }
  }
  void setShowTopBrushControls(bool show) {
    if (showTopBrushControls() != show) {
      m_settings->setValue("show_top_brush_controls", show);
      emit settingsChanged();
    }
  }
  void setShowTopActionButtons(bool show) {
    if (showTopActionButtons() != show) {
      m_settings->setValue("show_top_action_buttons", show);
      emit settingsChanged();
    }
  }
  void setShowTopSymmetryUndoRedo(bool show) {
    if (showTopSymmetryUndoRedo() != show) {
      m_settings->setValue("show_top_symmetry_undo_redo", show);
      emit settingsChanged();
    }
  }
  void setShowTopWorkspaceSwitcher(bool show) {
    if (showTopWorkspaceSwitcher() != show) {
      m_settings->setValue("show_top_workspace_switcher", show);
      emit settingsChanged();
    }
  }
  void setShowRightToolbar(bool show) {
    if (showRightToolbar() != show) {
      m_settings->setValue("show_right_toolbar", show);
      emit settingsChanged();
    }
  }
  void setShowRightColorSelector(bool show) {
    if (showRightColorSelector() != show) {
      m_settings->setValue("show_right_color_selector", show);
      emit settingsChanged();
    }
  }
  void setPressureCurve(const QVariantList &curve) {
    QStringList parts;
    for (const auto &v : curve) {
      parts << QString::number(v.toDouble(), 'f', 6);
    }
    QString strToSave = parts.join(",");
    
    // DEBUG LOGGING TO FILE
    QFile debugFile("e:/Programacion/Rescate_Proyecto/debug_curve.txt");
    if(debugFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
        QTextStream out(&debugFile);
        out << "SETTER: Saving string: " << strToSave << "\n";
        debugFile.close();
    }
    
    m_settings->setValue("pressure_curve", strToSave);
    emit pressureCurveChanged();
  }

  void setShortcuts(const QVariantMap &map) {
    if (shortcuts() != map) {
      m_settings->setValue("shortcuts", map);
      emit shortcutsChanged();
    }
  }

  Q_INVOKABLE void setShortcut(const QString &name, const QString &seq) {
    QVariantMap map = shortcuts();
    map[name] = seq;
    setShortcuts(map);
  }

  Q_INVOKABLE QString serializeLayout(const QString &activeWorkspace, const QVariantList &docks) {
    QJsonObject root;
    root["activeWorkspace"] = activeWorkspace;

    QJsonArray docksArray;
    for (const auto &val : docks) {
        QVariantMap map = val.toMap();
        QJsonObject dockObj;
        dockObj["panelId"] = map.value("panelId").toString();
        dockObj["dockArea"] = map.value("dockArea").toString();
        dockObj["positionIndex"] = map.value("positionIndex").toInt();
        dockObj["floating"] = map.value("floating").toBool();
        dockObj["collapsed"] = map.value("collapsed").toBool();
        if (map.contains("width")) {
            dockObj["width"] = map.value("width").toInt();
        }
        if (map.contains("height")) {
            dockObj["height"] = map.value("height").toInt();
        }
        docksArray.append(dockObj);
    }
    root["docks"] = docksArray;

    QJsonDocument doc(root);
    return QString::fromUtf8(doc.toJson(QJsonDocument::Indented));
  }

  Q_INVOKABLE QVariantMap deserializeLayout(const QString &jsonStr) {
    QVariantMap result;
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8(), &error);
    if (doc.isNull() || !doc.isObject()) {
        qWarning() << "Failed to parse layout JSON:" << error.errorString();
        return result;
    }

    QJsonObject root = doc.object();
    result["activeWorkspace"] = root.value("activeWorkspace").toString();

    QVariantList docksList;
    QJsonArray docksArray = root.value("docks").toArray();
    for (const auto &val : docksArray) {
        QJsonObject dockObj = val.toObject();
        QVariantMap dockMap;
        dockMap["panelId"] = dockObj.value("panelId").toString();
        dockMap["dockArea"] = dockObj.value("dockArea").toString();
        dockMap["positionIndex"] = dockObj.value("positionIndex").toInt();
        dockMap["floating"] = dockObj.value("floating").toBool();
        dockMap["collapsed"] = dockObj.value("collapsed").toBool();
        if (dockObj.contains("width")) {
            dockMap["width"] = dockObj.value("width").toInt();
        }
        if (dockObj.contains("height")) {
            dockMap["height"] = dockObj.value("height").toInt();
        }
        docksList.append(dockMap);
    }
    result["docks"] = docksList;
    return result;
  }

  Q_INVOKABLE void saveLayoutJson(const QString &workspaceName, const QString &jsonStr) {
    m_settings->setValue("Layouts/" + workspaceName, jsonStr);
  }

  Q_INVOKABLE QString getLayoutJson(const QString &workspaceName) const {
    return m_settings->value("Layouts/" + workspaceName, QString()).toString();
  }

  void resetDefaults() {
    m_settings->clear();
    emit settingsChanged();
    QVariantList defCurve;
    defCurve << 0.0 << 0.0 << 0.5 << 0.5 << 1.0 << 1.0;
    setPressureCurve(defCurve);
  }

signals:
  void settingsChanged();
  void pressureCurveChanged();
  void shortcutsChanged();

private:
  QSettings *m_settings;
  static PreferencesManager *m_instance;
};

#endif // PREFERENCESMANAGER_H
