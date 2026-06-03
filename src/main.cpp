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
#include <QWindow>
#include <QQuickWindow>
#include <QQuickStyle>
#include <windows.h>
#include "WintabManager.h"

void myMessageOutput(QtMsgType type, const QMessageLogContext &context,
                     const QString &msg) {
  QByteArray localMsg = msg.toLocal8Bit();
  std::ofstream os("qml_errors.log", std::ios_base::app);
  os << localMsg.constData() << std::endl;
}

extern "C" {
    int32_t test_rust_integration(int32_t a, int32_t b);
}

int main(int argc, char *argv[]) {
  qInstallMessageHandler(myMessageOutput);

  // Probar la integración de Rust
  int32_t rust_sum = test_rust_integration(10, 32);
  std::cout << "[Rust Integration] Sum of 10 and 32 is: " << rust_sum << std::endl;

  // Forza al motor de estilos de Qt Quick Controls 2 a usar el estilo "Basic",
  // lo cual permite la personalización de propiedades como "background" e "indicator"
  // en sliders y switches que de otro modo estarían congelados bajo el estilo nativo de Windows.
  QQuickStyle::setStyle("Basic");

  // Forza a Qt Quick/QRhi a usar el backend de OpenGL bajo Qt 6,
  // asegurando consistencia absoluta con los contextos compartidos y FBOs en C++.
  QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

  // FORZAR DRIVERS DE TABLETA (Wintab):
  // Activamos esto porque Windows Ink no está enviando eventos correctamente.
  // QCoreApplication::setAttribute(Qt::AA_PluginApplication);

// High DPI support
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

  QGuiApplication app(argc, argv);
  app.setOrganizationName("KromoStudio");
  app.setApplicationName("Kromo Studio");

  // Registro del componente de dibujo nativo
  // Registro de tipos QML
  qmlRegisterType<CanvasItem>("Kromo", 1, 0, "QCanvasItem");
  qmlRegisterType<PreviewPadItem>("Kromo", 1, 0, "QPreviewPadItem");
  qmlRegisterType<ColorPicker>("Kromo", 1, 0, "ColorPicker");
  qmlRegisterUncreatableType<artflow::PanelListModel>(
      "Kromo", 1, 0, "PanelListModel",
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
        if (!obj && url == objUrl) {
          QCoreApplication::exit(-1);
        } else if (obj) {
          QWindow *window = qobject_cast<QWindow *>(obj);
          if (window) {
            HWND hwnd = (HWND)window->winId();
            WintabManager::instance()->init(hwnd);
          }
        }
      },
      Qt::QueuedConnection);

  engine.load(url);

  return app.exec();
}
