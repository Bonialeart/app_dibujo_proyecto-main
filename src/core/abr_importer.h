#pragma once

#include "cpp/include/brush_preset.h"
#include <QByteArray>
#include <QImage>
#include <QList>
#include <QMap>
#include <QString>
#include <QVariant>
#include <functional>

namespace artflow {

class AbrImporter {
public:
  using ProgressCallback = std::function<void(int current, int total)>;

  static bool importFile(const QString &filePath,
                         const QString &textureSavePath,
                         ProgressCallback progress = nullptr);

  struct ExtractedBrush {
    QImage image;
    QString name;

    float diameter = 0;
    float spacing = 25;
    float hardness = 100;
    float angle = 0;
    float roundness = 100;
    float flow = 100;
    float opacity = 100;
    float scatter = 0;
    float wetness = 0;
    float sizeJitter = 0;
    float opacityJitter = 0;
    float minimumSize = 0;
    float minimumOpacity = 0;

    bool hasMetadata = false;
  };

  struct DescParam {
    QString key;
    QString type;
    QVariant value;
  };

private:
  // Texture extraction
  static bool readAbrV1(const QByteArray &data, class QDataStream &in,
                        QList<ExtractedBrush> &brushes);
  static bool readAbrV6(const QByteArray &data, class QDataStream &in,
                        QList<ExtractedBrush> &brushes, int version);
  static bool readModernPNG(const QByteArray &data,
                            QList<ExtractedBrush> &brushes);
  static bool readImageBlock(const QByteArray &blockData,
                             QList<ExtractedBrush> &brushes);
  static QImage decodeRLEImage(class QDataStream &in, int width, int height);

  // Descriptor metadata extraction
  static QList<QMap<QString, QVariant>>
  parseDescriptorMetadata(const QByteArray &data);
  static void extractNearbyParams(const QByteArray &area,
                                  QMap<QString, QVariant> &meta);

  // Generic descriptor block parser (alternative low-level approach)
  static QList<DescParam> parseDescriptorBlock(const QByteArray &descData);
  static QString findKeyBefore(const QByteArray &data, int pos,
                               int maxLookback = 50);
  static QList<QMap<QString, QVariant>>
  splitParamsIntoBrushes(const QList<DescParam> &params);

  // Metadata-texture correlation
  static void
  applyMetadataToBrushes(QList<ExtractedBrush> &brushes,
                         const QList<QMap<QString, QVariant>> &metadata);
  static void applyMetadataToSingleBrush(ExtractedBrush &brush,
                                         const QMap<QString, QVariant> &md);
};

} // namespace artflow
