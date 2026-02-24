#include "CanvasItem.h"
#include "ColorPicker.h"
#include "IconProvider.h"
#include "PreferencesManager.h"
#include "ProjectModel.h"
#include "color_harmony.h"
#include "drag_zone_calculator.h"
#include "panel_list_model.h"
#include "panel_manager.h"
#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <fstream>
#include <iostream>

void myMessageOutput(QtMsgType type, const QMessageLogContext &context,
                     const QString &msg) {
  QByteArray localMsg = msg.toLocal8Bit();
  std::ofstream os("qml_errors.log", std::ios_base::app);
  os << localMsg.constData() << std::endl;
}

int main(int argc, char *argv[]) {
  qInstallMessageHandler(myMessageOutput);

  // FORZAR DRIVERS DE TABLETA (Wintab):
  // Activamos esto porque Windows Ink no está enviando eventos correctamente.
  // QCoreApplication::setAttribute(Qt::AA_PluginApplication);

// High DPI support
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

  QGuiApplication app(argc, argv);
  app.setOrganizationName("ArtFlowStudio");
  app.setApplicationName("ArtFlow Pro");

  // Registro del componente de dibujo nativo
  // Registro de tipos QML
  qmlRegisterType<CanvasItem>("ArtFlow", 1, 0, "QCanvasItem");
  qmlRegisterType<ColorPicker>("ArtFlow", 1, 0, "ColorPicker");
  qmlRegisterUncreatableType<artflow::PanelListModel>(
      "ArtFlow", 1, 0, "PanelListModel",
      "PanelListModel is managed by PanelManager");

  QQmlApplicationEngine engine;
  engine.addImageProvider(QLatin1String("icons"), new IconProvider());

  // Inyectar managers globales
  ProjectModel projectModel;
  PreferencesManager preferencesManager;
  artflow::PanelManager panelManager;
  artflow::ColorHarmony colorHarmony;
  artflow::DragZoneCalculator dragCalculator;

  engine.rootContext()->setContextProperty("nativeProjectModel", &projectModel);
  engine.rootContext()->setContextProperty("preferencesManager",
                                           &preferencesManager);
  engine.rootContext()->setContextProperty("panelManager", &panelManager);
  engine.rootContext()->setContextProperty("colorHarmony", &colorHarmony);
  engine.rootContext()->setContextProperty("dragCalculator", &dragCalculator);

  // Carga de la App desde Recursos (.qrc)
  const QUrl url(QStringLiteral("qrc:/qml/main_pro.qml"));

  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
          QCoreApplication::exit(-1);
      },
      Qt::QueuedConnection);

  engine.load(url);

  return app.exec();
}
