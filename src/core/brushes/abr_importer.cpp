#include "abr_importer.h"
#include "../cpp/include/brush_preset_manager.h" 
#include <QFile>
#include <QDataStream>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QUrl>
#include <QUuid>
#include <QStandardPaths>
#include <QPainter>

namespace artflow {

bool AbrImporter::importFile(const QString& filePath, const QString& textureSavePath) {
    qDebug() << "========== INICIANDO IMPORTACIÓN ABR ==========";
    
    QString realPath = filePath;
    if (realPath.startsWith("file://")) {
        realPath = QUrl(realPath).toLocalFile();
    }

    QFile file(realPath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "[ABR Importer] ERROR: No se pudo abrir el archivo en disco:" << realPath;
        return false;
    }

    QByteArray data = file.readAll();
    file.close();

    if (data.size() < 4) {
        qWarning() << "[ABR Importer] ERROR: Archivo demasiado pequeño.";
        return false;
    }

    QDataStream in(data);
    in.setByteOrder(QDataStream::BigEndian);

    qint16 version;
    in >> version;
    qDebug() << "[ABR Importer] Versión ABR detectada:" << version;

    QList<ExtractedBrush> extractedBrushes;

    // Estrategia 1: Minería de PNG (La más fiable para pinceles HD)
    if (data.indexOf("\x89PNG") != -1) {
        qDebug() << "[ABR Importer] Detectada firma PNG. Ejecutando Modo Moderno...";
        readModernPNG(data, extractedBrushes);
    }

    if (extractedBrushes.isEmpty()) {
        qDebug() << "[ABR Importer] No se encontraron PNGs, intentando lectura estructural...";
        in.device()->seek(2); // Reset stream position after version
        
        if (version == 1 || version == 2) {
            if (!readAbrV1(data, in, extractedBrushes)) {
                qWarning() << "[ABR Importer] Falló la lectura V1/V2.";
            }
        } else if (version == 6 || version == 10) {
            if (!readAbrV6(data, in, extractedBrushes, version)) {
                qWarning() << "[ABR Importer] Falló la lectura V6/V10.";
            }
        } else {
            qWarning() << "[ABR Importer] ERROR: Versión no soportada (" << version << ").";
            return false;
        }
    }

    if (extractedBrushes.isEmpty()) {
        qWarning() << "[ABR Importer] ERROR: No se extrajo ninguna textura válida.";
        return false;
    }
    
    QString actualSavePath = textureSavePath;
    QDir dir;
    if (!dir.mkpath(actualSavePath)) {
        actualSavePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/ImportedBrushes";
        if (!dir.mkpath(actualSavePath)) {
            qWarning() << "[ABR Importer] ERROR CRÍTICO: No se puede crear la carpeta:" << actualSavePath;
            return false;
        }
    }

    QFileInfo abrInfo(realPath);
    QString groupName = abrInfo.baseName();
    int importedCount = 0;
    auto* bpm = BrushPresetManager::instance();

    for (int i = 0; i < extractedBrushes.size(); ++i) {
        const auto& extBrush = extractedBrushes[i];
        
        QString textureName = QString("abr_%1.png").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
        QString textureFullPath = QDir(actualSavePath).filePath(textureName);
        
        if (!extBrush.image.save(textureFullPath)) {
            qWarning() << "[ABR Importer] Falla al guardar textura PNG:" << textureFullPath;
            continue;
        }

        BrushPreset preset;
        preset.uuid = BrushPreset::generateUUID();
        preset.name = QString("%1 %2").arg(groupName).arg(i + 1);
        preset.category = "Imported"; 
        preset.author = "ABR Import";
        
        preset.shape.tipTexture = QDir::cleanPath(textureFullPath); 
        preset.shape.followStroke = true;
        
        preset.stroke.spacing = extBrush.spacing / 100.0f;
        preset.defaultSize = (float)qMax(extBrush.image.width(), extBrush.image.height());
        
        preset.sizeDynamics.pressureCurve = ResponseCurve::linear();
        preset.sizeDynamics.minLimit = 0.0f;

        bpm->addPreset(preset);
        bpm->savePreset(preset); 
        importedCount++;
    }

    qDebug() << "[ABR Importer] EXITOSO. Pinceles guardados:" << importedCount;
    return importedCount > 0;
}

bool AbrImporter::readAbrV1(const QByteArray& data, QDataStream& in, QList<ExtractedBrush>& brushes) {
    qint16 count; 
    in >> count;

    for (int i = 0; i < count; i++) {
        if (in.atEnd()) break;
        
        qint16 type; in >> type;
        quint32 size; in >> size;
        
        qint64 nextBrushPos = in.device()->pos() + size;

        if (type == 2) { 
            quint32 miscSize; in >> miscSize;
            in.skipRawData(miscSize);
            
            qint16 spacing; in >> spacing;
            qint16 diameter; in >> diameter;
            
            quint32 height; in >> height;
            quint32 width; in >> width;
            
            in.skipRawData(4); 
            
            if (width > 0 && height > 0 && width <= 4096 && height <= 4096) {
                QImage img(width, height, QImage::Format_Grayscale8);
                for (int y = 0; y < (int)height; y++) {
                    if (in.atEnd()) break;
                    in.readRawData((char*)img.scanLine(y), width);
                }
                img.invertPixels();
                ExtractedBrush b;
                b.image = img;
                b.spacing = spacing;
                brushes.append(b);
            }
        }
        
        in.device()->seek(nextBrushPos); 
    }
    return true;
}

bool AbrImporter::readAbrV6(const QByteArray& data, QDataStream& in, QList<ExtractedBrush>& brushes, int version) {
    // Buscar directamente la sección de texturas '8BIMsamp'
    int sampIdx = data.indexOf("8BIMsamp");
    if (sampIdx == -1) {
        qWarning() << "[ABR Importer] El archivo no contiene bloques 'samp' de imágenes.";
        return false;
    }

    in.device()->seek(sampIdx + 8); // Saltar firma "8BIMsamp"

    // Saltar el nombre del bloque (Pascal String)
    quint8 nameLen; in >> nameLen;
    in.skipRawData(nameLen);
    if ((nameLen + 1) % 2 != 0) in.skipRawData(1);

    // Leer tamaño del bloque 'samp' - Siempre es 32 bits en ABR
    quint32 sz; 
    in >> sz; 
    quint64 sectionSize = sz;

    qint64 sectionEnd = in.device()->pos() + sectionSize;
    qDebug() << "[ABR Importer] Bloque 'samp' encontrado. Versión:" << version << "Tamaño a leer:" << sectionSize << "bytes.";

    // EL BUCLE CORRECTO: Búsqueda Profunda (Deep Scan)
    // En las versiones legacy/intermedias sin PNGs limpios ni longitudes confiables, 
    // lo más seguro es buscar las cabeceras de imagen RAW (00 08 00) y RLE (00 08 01)
    
    QByteArray sampData = data.mid(in.device()->pos(), sectionSize);
    QDataStream memStream(sampData);
    memStream.setByteOrder(QDataStream::BigEndian);

    QList<QByteArray> patterns = { QByteArray("\x00\x08\x01", 3), QByteArray("\x00\x08\x00", 3) };
    
    for (const QByteArray& pattern : patterns) {
        int offset = 0;
        while (true) {
            int loc = sampData.indexOf(pattern, offset);
            if (loc == -1) break;

            int headerStart = loc - 16;
            if (headerStart >= 0) {
                memStream.device()->seek(headerStart);
                qint32 t, l, b, r;
                memStream >> t >> l >> b >> r;
                
                int w = r - l;
                int h = b - t;

                if (w > 0 && h > 0 && w <= 8192 && h <= 8192) {
                    memStream.device()->seek(loc + 3); // Saltar firma detectada (depth 8 + comp)
                    qint8 comp = pattern.at(2); // 0 = RAW, 1 = RLE

                    ExtractedBrush bBrush;
                    bBrush.spacing = 25;
                    bool success = false;

                    if (comp == 0) { // RAW
                        QImage img(w, h, QImage::Format_Grayscale8);
                        for (int y = 0; y < h; ++y) {
                            if (memStream.atEnd()) break;
                            memStream.readRawData((char*)img.scanLine(y), w);
                        }
                        if (!memStream.atEnd()) {
                            img.invertPixels();
                            bBrush.image = img;
                            success = true;
                        }
                    } else if (comp == 1) { // RLE Compression
                        QImage img = decodeRLEImage(memStream, w, h);
                        if (!img.isNull()) {
                            img.invertPixels();
                            bBrush.image = img;
                            success = true;
                        }
                    }

                    if (success) {
                        brushes.append(bBrush);
                        offset = memStream.device()->pos(); // Continuar desde donde terminó de leer
                        continue;
                    }
                }
            }
            offset = loc + 3; // Si falló la extracción o bounds, avanzar poco a poco
        }
    }

    return !brushes.isEmpty(); // Retornamos TRUE si logramos extraer al menos 1
}

QImage AbrImporter::decodeRLEImage(QDataStream& in, int width, int height) {
    QImage img(width, height, QImage::Format_Grayscale8);
    img.fill(255); // Fondo transparente por defecto (blanco -> negro)

    for (int y = 0; y < height; ++y) {
        uchar* scanline = img.scanLine(y);
        int x = 0;
        
        while (x < width) {
            if (in.atEnd()) break;
            qint8 n; 
            in >> n;

            if (n >= 0) { // Bloque RAW de longitud n+1
                int count = n + 1;
                for (int i = 0; i < count; ++i) {
                    if (in.atEnd()) break;
                    qint8 val; 
                    in >> val;
                    if (x < width) scanline[x++] = (uchar)val;
                }
            } else if (n >= -127 && n <= -1) { // Bloque repetido de longitud -n+1
                if (in.atEnd()) break;
                qint8 val; 
                in >> val;
                int count = -n + 1;
                for (int i = 0; i < count; ++i) {
                    if (x < width) scanline[x++] = (uchar)val;
                }
            }
            // n == -128 es un no-op
        }
    }
    return img;
}

bool AbrImporter::readModernPNG(const QByteArray& data, QList<ExtractedBrush>& brushes) {
    const QByteArray pngSig = QByteArrayLiteral("\x89PNG\r\n\x1a\n");
    const QByteArray iendSig = QByteArrayLiteral("IEND");
    
    int offset = 0;
    while (true) {
        int start = data.indexOf(pngSig, offset);
        if (start == -1) break;
        
        int iend = data.indexOf(iendSig, start);
        if (iend == -1) break;
        
        int end = iend + 8; // IEND chunk: length (4) + IEND (4) + CRC (4) = end of IEND is at IEND + 8
        
        QByteArray pngData = data.mid(start, end - start);
        QImage img;
        if (img.loadFromData(pngData, "PNG")) {
            // Un PNG puede tener fondo transparente y pinceladas negras o blancas.
            // Para el BrushEngine, idealmente partimos de fondo blanco (sin pintura)
            // y pixeles oscuros (pintura).
            // Componer PNG sobre fondo blanco:
            QImage composed(img.size(), QImage::Format_ARGB32_Premultiplied);
            composed.fill(Qt::white);
            QPainter p(&composed);
            p.drawImage(0, 0, img);
            p.end();

            // Convertir a escala de grises
            QImage finalImg = composed.convertToFormat(QImage::Format_Grayscale8);
            
            // Invertimos para que fondo (blanco) -> negro (0, nulo)
            // Y pintura (negro) -> blanco (255, opaco).
            // Nota: Originalmente AbrImporter invertía los RAW. Si la lógica de brush engine
            // espera negro=255 o negro=0, esto emula el comportamiento de readAbrV6.
            finalImg.invertPixels();
            
            ExtractedBrush b;
            b.image = finalImg;
            b.spacing = 25; // Spacing default
            brushes.append(b);
        }
        offset = end;
    }
    
    qDebug() << "[ABR Importer] Pinceles PNG extraídos:" << brushes.size();
    return !brushes.isEmpty();
}

} // namespace artflow
