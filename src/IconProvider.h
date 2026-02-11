#ifndef ICONPROVIDER_H
#define ICONPROVIDER_H

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QIcon>
#include <QPainter>
#include <QQuickImageProvider>
#include <QStringList>
#include <QSvgRenderer>

class IconProvider : public QQuickImageProvider {
public:
  IconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

  QPixmap requestPixmap(const QString &id, QSize *size,
                        const QSize &requestedSize) override {
    QString fileName = id;
    if (!fileName.endsWith(".svg") && !fileName.endsWith(".png")) {
      fileName += ".svg";
    }

    // Lista de rutas posibles para buscar iconos
    QStringList searchPaths;
    // Ruta basada en el directorio de la aplicación
    searchPaths << QCoreApplication::applicationDirPath() + "/assets/icons/" +
                       fileName;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/../src/assets/icons/" + fileName;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/../../src/assets/icons/" + fileName;
    // Rutas absolutas del proyecto (para desarrollo)
    searchPaths << "d:/app_dibujo_proyecto-main/src/assets/icons/" + fileName;
    searchPaths << "d:/app_dibujo_proyecto-main/assets/icons/" + fileName;
    // Rutas relativas al directorio de trabajo actual (Qt Creator suele usar el
    // directorio de build)
    searchPaths << QDir::currentPath() + "/src/assets/icons/" + fileName;
    searchPaths << QDir::currentPath() + "/../src/assets/icons/" + fileName;
    searchPaths << QDir::currentPath() + "/../../src/assets/icons/" + fileName;
    searchPaths << "assets/icons/" + fileName;
    searchPaths << "../src/assets/icons/" + fileName;
    searchPaths << "../../src/assets/icons/" + fileName;

    QString path;
    for (const QString &searchPath : searchPaths) {
      if (QFile::exists(searchPath)) {
        path = searchPath;
        break;
      }
    }

    // Si no se encontró, usar la primera ruta como fallback
    if (path.isEmpty()) {
      path = searchPaths.first();
      qWarning() << "Icon not found:" << fileName
                 << "- Searched in:" << searchPaths;
    }

    int w = requestedSize.width() > 0 ? requestedSize.width() : 64;
    int h = requestedSize.height() > 0 ? requestedSize.height() : 64;
    QPixmap pixmap(w, h);
    pixmap.fill(Qt::transparent);

    if (QFile::exists(path)) {
      if (path.endsWith(".svg")) {
        QSvgRenderer renderer(path);
        QPainter painter(&pixmap);
        renderer.render(&painter);
      } else {
        pixmap.load(path);
      }
    } else {
      // Fallback: draw a basic circle or placeholder
      QPainter painter(&pixmap);
      painter.setRenderHint(QPainter::Antialiasing);
      painter.setPen(QPen(Qt::white, 1));
      painter.drawEllipse(w / 4, h / 4, w / 2, h / 2);
    }

    if (size)
      *size = pixmap.size();
    return pixmap;
  }
};

#endif // ICONPROVIDER_H
