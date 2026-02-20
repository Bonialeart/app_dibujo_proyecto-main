#pragma once

#include "brush_preset.h"
#include <QString>
#include <QList>
#include <QImage>
#include <QByteArray>

namespace artflow {

class AbrImporter {
public:
    // Importa un archivo .abr, extrae los pinceles y los añade al BrushPresetManager
    static bool importFile(const QString& filePath, const QString& textureSavePath);

private:
    struct ExtractedBrush {
        QImage image;
        int spacing = 25; 
    };

    static bool readAbrV1(const QByteArray& data, class QDataStream& in, QList<ExtractedBrush>& brushes);
    static bool readAbrV6(const QByteArray& data, class QDataStream& in, QList<ExtractedBrush>& brushes, int version);
    static bool readModernPNG(const QByteArray& data, QList<ExtractedBrush>& brushes);
    static QImage decodeRLEImage(class QDataStream& in, int width, int height);
};

} // namespace artflow
