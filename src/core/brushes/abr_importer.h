#pragma once

#include "brush_preset.h"
#include <QByteArray>
#include <QImage>
#include <QList>
#include <QMap>
#include <QString>

namespace artflow {

class AbrImporter {
public:
  // Importa un archivo .abr, extrae los pinceles y los anade al
  // BrushPresetManager
  static bool importFile(const QString &filePath,
                         const QString &textureSavePath);

  // Estructura que representa un pincel extraido (imagen + metadatos)
  struct ExtractedBrush {
    QImage image;
    QString name;

    // Parametros extraidos del descriptor (valores en % o grados segun
    // contexto)
    float diameter = 0;    // px
    float spacing = 25;    // %
    float hardness = 100;  // %
    float angle = 0;       // degrees
    float roundness = 100; // %
    float flow = 100;      // %
    float opacity = 100;   // %
    float scatter = 0;
    float wetness = 0;

    // Dynamics
    float sizeJitter = 0;     // %
    float opacityJitter = 0;  // %
    float minimumSize = 0;    // %
    float minimumOpacity = 0; // %

    bool hasMetadata = false; // true si se extrajo del bloque descriptor
  };

  // Estructura para un parametro parseado del descriptor
  struct DescParam {
    QString key;
    QString type; // TEXT, UntF#Pxl, long, bool, enum, doub, Objc, VlLs
    QVariant value;
  };

private:
  // Extraccion de texturas
  static bool readAbrV1(const QByteArray &data, class QDataStream &in,
                        QList<ExtractedBrush> &brushes);
  static bool readAbrV6(const QByteArray &data, class QDataStream &in,
                        QList<ExtractedBrush> &brushes, int version);
  static bool readModernPNG(const QByteArray &data,
                            QList<ExtractedBrush> &brushes);
  static bool readImageBlock(const QByteArray &blockData,
                             QList<ExtractedBrush> &brushes);
  static QImage decodeRLEImage(class QDataStream &in, int width, int height);

  // Extraccion de metadatos del descriptor 8BIMdesc
  static QList<QMap<QString, QVariant>>
  parseDescriptorMetadata(const QByteArray &data);
  static QList<DescParam> parseDescriptorBlock(const QByteArray &descData);
  static QList<QMap<QString, QVariant>>
  splitParamsIntoBrushes(const QList<DescParam> &params);
  static QString findKeyBefore(const QByteArray &data, int pos,
                               int maxLookback = 50);
  static void extractNearbyParams(const QByteArray &area,
                                  QMap<QString, QVariant> &meta);

  // Correlacion texturas - metadatos
  static void
  applyMetadataToBrushes(QList<ExtractedBrush> &brushes,
                         const QList<QMap<QString, QVariant>> &metadata);
  static void applyMetadataToSingleBrush(ExtractedBrush &brush,
                                         const QMap<QString, QVariant> &md);
};

} // namespace artflow
