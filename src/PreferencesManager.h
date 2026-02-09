#ifndef PREFERENCESMANAGER_H
#define PREFERENCESMANAGER_H

#include <QColor>
#include <QDir>
#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class PreferencesManager : public QObject {
  Q_OBJECT
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

  QString themeMode() const {
    return m_settings->value("theme_mode", "Dark").toString();
  }
  void setThemeMode(const QString &mode) {
    m_settings->setValue("theme_mode", mode);
    emit settingsChanged();
  }

  QString themeAccent() const {
    return m_settings->value("theme_accent", "#6366f1").toString();
  }
  void setThemeAccent(const QString &accent) {
    m_settings->setValue("theme_accent", accent);
    emit settingsChanged();
  }

  QString language() const {
    return m_settings->value("language", "es").toString();
  }
  void setLanguage(const QString &lang) {
    m_settings->setValue("language", lang);
    emit settingsChanged();
  }

  QVariantList pressureCurve() const {
    // Default linear curve [0,0, 1,1]
    QVariantList defaultCurve;
    defaultCurve << 0.0 << 0.0 << 1.0 << 1.0;
    return m_settings->value("pressure_curve", defaultCurve).toList();
  }

  void setPressureCurve(const QVariantList &curve) {
    m_settings->setValue("pressure_curve", curve);
    emit pressureCurveChanged();
  }

signals:
  void settingsChanged();
  void pressureCurveChanged();

private:
  QSettings *m_settings;
  static PreferencesManager *m_instance;
};

#endif // PREFERENCESMANAGER_H
