#include "abr_importer.h"
#include "cpp/include/brush_preset_manager.h"
#include <QDataStream>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QPainter>
#include <QStandardPaths>
#include <QUrl>
#include <QUuid>
#include <QVariant>

namespace artflow {

// ============================================================================
//  INTERNAL UTILITIES
// ============================================================================

// Converts a Grayscale8 brush image (white=paint, black=background after
// inversion) to the RGBA format the brush engine expects.
// The engine's shader does: shapeAlpha = luminance(rgb) * alpha
// So we need: white(255,255,255) with alpha=luminance for paint areas,
// and transparent black for background.
static QImage grayscaleToTipTexture(const QImage &graySrc) {
  QImage out(graySrc.width(), graySrc.height(),
             QImage::Format_RGBA8888_Premultiplied);
  out.fill(Qt::transparent);

  for (int y = 0; y < graySrc.height(); ++y) {
    const uchar *srcLine = graySrc.constScanLine(y);
    uchar *dstLine = out.scanLine(y);
    for (int x = 0; x < graySrc.width(); ++x) {
      uchar luma = srcLine[x]; // 0=transparent, 255=full paint
      // Premultiplied RGBA: R=luma, G=luma, B=luma, A=luma
      dstLine[x * 4 + 0] = luma; // R
      dstLine[x * 4 + 1] = luma; // G
      dstLine[x * 4 + 2] = luma; // B
      dstLine[x * 4 + 3] = luma; // A
    }
  }
  return out;
}

struct Block8BIM {
  QString key;
  qint64 offset;
  qint64 dataStart;
  qint64 dataSize;
};

static QList<Block8BIM> findAll8BIMBlocks(const QByteArray &data) {
  QList<Block8BIM> blocks;
  int pos = 4; // skip 4-byte version header

  while (pos < data.size() - 8) {
    if (data.mid(pos, 4) != QByteArrayLiteral("8BIM"))
      break;

    Block8BIM block;
    block.key = QString::fromLatin1(data.mid(pos + 4, 4));
    block.offset = pos;
    block.dataStart = pos + 12;

    int next = data.indexOf("8BIM", pos + 8);
    if (next == -1)
      block.dataSize = data.size() - block.dataStart;
    else
      block.dataSize = next - block.dataStart;

    blocks.append(block);
    pos = (next != -1) ? next : data.size();
  }

  return blocks;
}

// ============================================================================
//  MAIN IMPORT
// ============================================================================

bool AbrImporter::importFile(const QString &filePath,
                             const QString &textureSavePath) {
  qDebug() << "========== ABR IMPORT V3 (MULTI-BLOCK) ==========";

  QString realPath = filePath;
  if (realPath.startsWith("file://")) {
    realPath = QUrl(realPath).toLocalFile();
  }

  QFile file(realPath);
  if (!file.open(QIODevice::ReadOnly)) {
    qWarning() << "[ABR] ERROR: Cannot open file:" << realPath;
    return false;
  }

  QByteArray data = file.readAll();
  file.close();

  if (data.size() < 4) {
    qWarning() << "[ABR] ERROR: File too small.";
    return false;
  }

  QDataStream in(data);
  in.setByteOrder(QDataStream::BigEndian);

  qint16 version;
  in >> version;
  qDebug() << "[ABR] Version:" << version;

  // --- PHASE 1: Find all 8BIM blocks ---
  QList<Block8BIM> blocks = findAll8BIMBlocks(data);
  qDebug() << "[ABR] 8BIM blocks found:" << blocks.size();
  for (const auto &b : blocks) {
    qDebug() << "  8BIM" << b.key << "offset:" << b.offset
             << "size:" << b.dataSize;
  }

  // --- PHASE 2: Extract METADATA from descriptor block ---
  auto brushMetadata = parseDescriptorMetadata(data);
  qDebug() << "[ABR] Metadata entries:" << brushMetadata.size();

  for (int i = 0; i < qMin(brushMetadata.size(), 20); ++i) {
    auto &md = brushMetadata[i];
    qDebug() << "  [" << i << "]" << md.value("name", "???").toString() << "| Ø"
             << md.value("diameter", 0).toFloat()
             << "| Spc:" << md.value("spacing", 0).toFloat() << "%"
             << "| Hrd:" << md.value("hardness", 0).toFloat() << "%";
  }

  // --- PHASE 3: Extract TEXTURES from ALL image blocks ---
  QList<ExtractedBrush> extractedBrushes;

  // Strategy 1: PNG mining (most reliable for HD brushes)
  if (data.indexOf("\x89PNG") != -1) {
    qDebug() << "[ABR] PNG signature found. Running Modern PNG mode...";
    readModernPNG(data, extractedBrushes);
  }

  // Strategy 2: Structural scan
  if (extractedBrushes.isEmpty()) {
    qDebug() << "[ABR] No PNGs found, trying structural scan...";
    in.device()->seek(2);

    if (version == 1 || version == 2) {
      if (!readAbrV1(data, in, extractedBrushes)) {
        qWarning() << "[ABR] V1/V2 read failed.";
      }
    } else if (version == 6 || version == 10) {
      // Scan ALL blocks that may contain images: 'samp' AND 'IDNA'
      bool foundAny = false;
      for (const auto &block : blocks) {
        if (block.key == "samp" || block.key == "IDNA") {
          qDebug() << "[ABR] Scanning block" << block.key << "("
                   << block.dataSize << "bytes)...";
          QByteArray blockData = data.mid(block.dataStart, block.dataSize);
          readImageBlock(blockData, extractedBrushes);
          foundAny = true;
        }
      }
      if (!foundAny) {
        qWarning() << "[ABR] No samp/IDNA blocks found.";
      }
    } else {
      qWarning() << "[ABR] ERROR: Unsupported version (" << version << ").";
      return false;
    }
  }

  if (extractedBrushes.isEmpty()) {
    qWarning() << "[ABR] ERROR: No valid textures extracted.";
    return false;
  }

  qDebug() << "[ABR] Textures extracted:" << extractedBrushes.size();

  // --- PHASE 4: CORRELATE metadata with textures ---
  if (!brushMetadata.isEmpty()) {
    applyMetadataToBrushes(extractedBrushes, brushMetadata);
  }

  // --- PHASE 5: Save textures and create presets ---
  QString actualSavePath = textureSavePath;
  QDir dir;
  if (!dir.mkpath(actualSavePath)) {
    actualSavePath =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
        "/ImportedBrushes";
    if (!dir.mkpath(actualSavePath)) {
      qWarning() << "[ABR] CRITICAL: Cannot create folder:" << actualSavePath;
      return false;
    }
  }

  QFileInfo abrInfo(realPath);
  QString groupName = abrInfo.baseName();
  int importedCount = 0;
  auto *bpm = BrushPresetManager::instance();

  for (int i = 0; i < extractedBrushes.size(); ++i) {
    const auto &extBrush = extractedBrushes[i];

    // Convert grayscale brush to proper RGBA tip texture
    // The engine expects white=paint with alpha, black=transparent
    QImage tipImage = grayscaleToTipTexture(extBrush.image);

    QString textureName =
        QString("abr_%1.png")
            .arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    QString textureFullPath = QDir(actualSavePath).filePath(textureName);

    if (!tipImage.save(textureFullPath)) {
      qWarning() << "[ABR] Failed to save texture:" << textureFullPath;
      continue;
    }

    BrushPreset preset;
    preset.uuid = BrushPreset::generateUUID();

    if (!extBrush.name.isEmpty()) {
      preset.name = extBrush.name;
    } else {
      preset.name = QString("%1 %2").arg(groupName).arg(i + 1);
    }

    preset.category = "Imported";
    preset.author = "ABR Import (" + groupName + ")";

    preset.shape.tipTexture = QDir::cleanPath(textureFullPath);
    preset.shape.followStroke = true;
    preset.shape.rotation = extBrush.angle;
    preset.shape.roundness = extBrush.roundness / 100.0f;
    preset.shape.scatter = extBrush.scatter / 100.0f;

    preset.stroke.spacing = extBrush.spacing / 100.0f;

    if (extBrush.diameter > 0) {
      preset.defaultSize = extBrush.diameter;
    } else {
      preset.defaultSize =
          (float)qMax(extBrush.image.width(), extBrush.image.height());
    }

    preset.defaultHardness = extBrush.hardness / 100.0f;
    preset.defaultFlow = extBrush.flow / 100.0f;
    preset.defaultOpacity = extBrush.opacity / 100.0f;

    if (extBrush.wetness > 0) {
      preset.wetMix.wetMix = extBrush.wetness / 100.0f;
    }

    preset.sizeDynamics.pressureCurve = ResponseCurve::linear();
    preset.sizeDynamics.minLimit = extBrush.minimumSize / 100.0f;
    preset.sizeDynamics.jitter = extBrush.sizeJitter / 100.0f;

    preset.opacityDynamics.pressureCurve = ResponseCurve::linear();
    preset.opacityDynamics.minLimit = extBrush.minimumOpacity / 100.0f;
    preset.opacityDynamics.jitter = extBrush.opacityJitter / 100.0f;

    if (extBrush.sizeJitter > 0) {
      preset.randomize.sizeJitter = extBrush.sizeJitter / 100.0f;
    }
    if (extBrush.opacityJitter > 0) {
      preset.randomize.opacityJitter = extBrush.opacityJitter / 100.0f;
    }

    bpm->addPreset(preset);
    bpm->savePreset(preset);
    importedCount++;

    qDebug() << "[ABR] Preset created:" << preset.name
             << "| Size:" << preset.defaultSize
             << "| Spacing:" << preset.stroke.spacing;
  }

  qDebug() << "[ABR] SUCCESS. Brushes saved:" << importedCount;
  return importedCount > 0;
}

// ============================================================================
//  METADATA EXTRACTION FROM 8BIMdesc
//  Scans for "Nm  " + "TEXT" patterns to extract all brush names
// ============================================================================

QList<QMap<QString, QVariant>>
AbrImporter::parseDescriptorMetadata(const QByteArray &data) {
  QList<QMap<QString, QVariant>> result;

  int descIdx = data.indexOf("8BIMdesc");
  int descDataStart;

  if (descIdx != -1) {
    descDataStart = descIdx + 12;
  } else {
    descIdx = data.indexOf("desc");
    if (descIdx == -1)
      return result;
    descDataStart = descIdx + 4;
  }

  if (descIdx + 12 > data.size())
    return result;

  QDataStream sizeStream(data.mid(descIdx + 8, 4));
  sizeStream.setByteOrder(QDataStream::BigEndian);
  quint32 descSize;
  sizeStream >> descSize;

  qint64 maxSize = data.size() - descDataStart;
  if ((qint64)descSize > maxSize)
    descSize = (quint32)maxSize;

  QByteArray descData = data.mid(descDataStart, descSize);
  if (descData.size() < 10)
    return result;

  qDebug() << "[ABR] Descriptor block at offset" << descIdx
           << ", size:" << descSize;

  // Scan for ALL "Nm  " + "TEXT" occurrences
  QByteArray nmMarker("Nm  ", 4);
  QByteArray textMarker("TEXT", 4);

  int searchPos = 0;
  while (searchPos < descData.size() - 12) {
    int nmIdx = descData.indexOf(nmMarker, searchPos);
    if (nmIdx == -1)
      break;

    if (nmIdx + 4 + 4 + 4 > descData.size()) {
      searchPos = nmIdx + 4;
      continue;
    }

    if (descData.mid(nmIdx + 4, 4) != textMarker) {
      searchPos = nmIdx + 4;
      continue;
    }

    QDataStream ts(descData.mid(nmIdx + 8, 4));
    ts.setByteOrder(QDataStream::BigEndian);
    quint32 textLen;
    ts >> textLen;

    if (textLen == 0 || textLen > 500) {
      searchPos = nmIdx + 12;
      continue;
    }

    int textStart = nmIdx + 12;
    int textEnd = qMin(textStart + (int)textLen * 2, descData.size());

    QByteArray textBytes = descData.mid(textStart, textEnd - textStart);
    QString name;
    for (int i = 0; i + 1 < textBytes.size(); i += 2) {
      quint16 ch = ((quint8)textBytes[i] << 8) | (quint8)textBytes[i + 1];
      if (ch == 0)
        break;
      name.append(QChar(ch));
    }

    name = name.trimmed();
    if (!name.isEmpty()) {
      QMap<QString, QVariant> brushMeta;
      brushMeta["name"] = name;

      int paramSearchStart = textEnd;
      int paramSearchEnd = qMin(paramSearchStart + 2000, descData.size());
      QByteArray paramArea =
          descData.mid(paramSearchStart, paramSearchEnd - paramSearchStart);

      extractNearbyParams(paramArea, brushMeta);

      result.append(brushMeta);
    }

    searchPos = textEnd;
  }

  qDebug() << "[ABR] Names extracted from descriptor:" << result.size();
  return result;
}

void AbrImporter::extractNearbyParams(const QByteArray &area,
                                      QMap<QString, QVariant> &meta) {
  static const QMap<QByteArray, QString> knownKeys = {
      {QByteArray("Dmtr", 4), "diameter"},
      {QByteArray("Hrdn", 4), "hardness"},
      {QByteArray("Spcn", 4), "spacing"},
      {QByteArray("Angl", 4), "angle"},
      {QByteArray("Rndn", 4), "roundness"},
      {QByteArray("FlwR", 4), "flow"},
      {QByteArray("Opct", 4), "opacity"},
      {QByteArray("szJt", 4), "size_jitter"},
      {QByteArray("opJt", 4), "opacity_jitter"},
      {QByteArray("Sctr", 4), "scatter"},
      {QByteArray("mnmS", 4), "minimum_size"},
      {QByteArray("mnmO", 4), "minimum_opacity"},
  };

  QByteArray untfMarker("UntF", 4);

  int nextNm = area.indexOf(QByteArray("Nm  ", 4));
  int searchLimit = (nextNm != -1) ? nextNm : area.size();

  int pos = 0;
  while (pos < searchLimit - 16) {
    int untfIdx = area.indexOf(untfMarker, pos);
    if (untfIdx == -1 || untfIdx >= searchLimit)
      break;

    if (untfIdx >= 4) {
      QByteArray keyBytes = area.mid(untfIdx - 4, 4);
      auto it = knownKeys.find(keyBytes);
      if (it != knownKeys.end()) {
        if (untfIdx + 16 <= area.size()) {
          QDataStream ds(area.mid(untfIdx + 4 + 4, 8));
          ds.setByteOrder(QDataStream::BigEndian);
          ds.setFloatingPointPrecision(QDataStream::DoublePrecision);
          double val;
          ds >> val;
          meta[it.value()] = val;
        }
      }
    }
    pos = untfIdx + 16;
  }
}

// ============================================================================
//  GENERIC DESCRIPTOR BLOCK PARSER
//  Alternative low-level parser for all marker types
// ============================================================================

QString AbrImporter::findKeyBefore(const QByteArray &data, int pos,
                                   int maxLookback) {
  int start = qMax(0, pos - maxLookback);
  QString key;
  for (int i = pos - 1; i >= start; --i) {
    quint8 ch = (quint8)data[i];
    if (ch >= 32 && ch <= 126) {
      key.prepend((char)ch);
    } else {
      break;
    }
  }
  return key.trimmed();
}

QList<AbrImporter::DescParam>
AbrImporter::parseDescriptorBlock(const QByteArray &descData) {
  QList<DescParam> results;
  int L = descData.size();
  int pos = 0;

  struct MarkerDef {
    QByteArray sig;
    QString name;
  };

  QList<MarkerDef> markers = {
      {QByteArray("UntF", 4), "UntF"}, {QByteArray("bool", 4), "bool"},
      {QByteArray("long", 4), "long"}, {QByteArray("doub", 4), "doub"},
      {QByteArray("enum", 4), "enum"}, {QByteArray("TEXT", 4), "TEXT"},
      {QByteArray("Objc", 4), "Objc"}, {QByteArray("VlLs", 4), "VlLs"},
  };

  while (pos < L - 4) {
    bool foundMarker = false;

    for (const auto &marker : markers) {
      if (descData.mid(pos, 4) != marker.sig)
        continue;

      QString key = findKeyBefore(descData, pos);

      if (marker.name == "TEXT") {
        if (pos + 8 <= L) {
          QDataStream s(descData.mid(pos + 4, 4));
          s.setByteOrder(QDataStream::BigEndian);
          quint32 length;
          s >> length;

          int textStart = pos + 8;
          int textEnd = qMin(textStart + (int)length * 2, L);

          QByteArray textBytes = descData.mid(textStart, textEnd - textStart);
          QString text;
          for (int i = 0; i + 1 < textBytes.size(); i += 2) {
            quint16 ch = ((quint8)textBytes[i] << 8) | (quint8)textBytes[i + 1];
            if (ch == 0)
              break;
            text.append(QChar(ch));
          }

          results.append({key, "TEXT", text});
          pos = textEnd;
          foundMarker = true;
          break;
        }
      } else if (marker.name == "UntF") {
        if (pos + 16 <= L) {
          QString unitCode =
              QString::fromLatin1(descData.mid(pos + 4, 4)).trimmed();

          QDataStream s(descData.mid(pos + 8, 8));
          s.setByteOrder(QDataStream::BigEndian);
          s.setFloatingPointPrecision(QDataStream::DoublePrecision);
          double val;
          s >> val;

          results.append({key, "UntF#" + unitCode, val});
          pos += 16;
          foundMarker = true;
          break;
        }
      } else if (marker.name == "long") {
        if (pos + 8 <= L) {
          QDataStream s(descData.mid(pos + 4, 4));
          s.setByteOrder(QDataStream::BigEndian);
          qint32 val;
          s >> val;

          results.append({key, "long", val});
          pos += 8;
          foundMarker = true;
          break;
        }
      } else if (marker.name == "bool") {
        if (pos + 5 <= L) {
          bool val = (descData[pos + 4] != 0);
          results.append({key, "bool", val});
          pos += 5;
          foundMarker = true;
          break;
        }
      } else if (marker.name == "doub") {
        if (pos + 12 <= L) {
          QDataStream s(descData.mid(pos + 4, 8));
          s.setByteOrder(QDataStream::BigEndian);
          s.setFloatingPointPrecision(QDataStream::DoublePrecision);
          double val;
          s >> val;

          results.append({key, "doub", val});
          pos += 12;
          foundMarker = true;
          break;
        }
      } else if (marker.name == "enum") {
        if (pos + 12 <= L) {
          QString enumType =
              QString::fromLatin1(descData.mid(pos + 8, 4)).trimmed();
          if (enumType.isEmpty()) {
            enumType = QString::fromLatin1(descData.mid(pos + 4, 4)).trimmed();
          }

          int enumPos = pos + 12;
          while (enumPos < L &&
                 ((quint8)descData[enumPos] == 0 || descData[enumPos] == ' '))
            enumPos++;

          QString enumValue;
          while (enumPos < L && (quint8)descData[enumPos] >= 32 &&
                 (quint8)descData[enumPos] <= 126) {
            char c = descData[enumPos];
            if (QChar(c).isLetterOrNumber() || c == ' ' || c == '.' ||
                c == '-' || c == '_') {
              enumValue += c;
            }
            enumPos++;
          }

          enumValue = enumValue.trimmed();
          QString fullEnum =
              enumValue.isEmpty() ? enumType : enumType + "." + enumValue;
          results.append({key, "enum", fullEnum});

          int nextPos = L;
          for (const auto &nm : markers) {
            int found = descData.indexOf(nm.sig, enumPos);
            if (found != -1)
              nextPos = qMin(nextPos, found);
          }
          pos = nextPos;
          foundMarker = true;
          break;
        }
      } else if (marker.name == "Objc") {
        int objPos = pos + 4;
        bool classFound = false;
        while (objPos < qMin(L - 4, pos + 100)) {
          if ((quint8)descData[objPos] >= 97 &&
              (quint8)descData[objPos] <= 122) {
            QString className;
            int tempPos = objPos;
            while (tempPos < L) {
              quint8 ch = (quint8)descData[tempPos];
              if ((ch >= 97 && ch <= 122) || (ch >= 65 && ch <= 90) ||
                  (ch >= 48 && ch <= 57) || ch == 95) {
                className += (char)ch;
                tempPos++;
              } else {
                break;
              }
            }
            if (className.size() > 2) {
              results.append({key, "Objc", className});
              pos = tempPos;
              classFound = true;
              break;
            }
          }
          objPos++;
        }
        if (!classFound) {
          results.append({key, "Objc", "unknown"});
          pos += 4;
        }
        foundMarker = true;
        break;
      } else if (marker.name == "VlLs") {
        int nextPos = L;
        for (const auto &nm : markers) {
          int found = descData.indexOf(nm.sig, pos + 4);
          if (found != -1)
            nextPos = qMin(nextPos, found);
        }
        results.append({key, "VlLs", "list"});
        pos = nextPos;
        foundMarker = true;
        break;
      }
    }

    if (!foundMarker) {
      pos++;
    }
  }

  return results;
}

QList<QMap<QString, QVariant>>
AbrImporter::splitParamsIntoBrushes(const QList<DescParam> &params) {
  QList<QMap<QString, QVariant>> brushes;
  QMap<QString, QVariant> current;
  bool hasActive = false;

  static QMap<QString, QString> keyMap = {
      {"Nm  ", "name"},           {"Dmtr", "diameter"},
      {"Hrdn", "hardness"},       {"Angl", "angle"},
      {"Rndn", "roundness"},      {"Spcn", "spacing"},
      {"FlwR", "flow"},           {"Opct", "opacity"},
      {"Wtns", "wetness"},        {"szJt", "size_jitter"},
      {"opJt", "opacity_jitter"}, {"Sctr", "scatter"},
      {"mnmS", "minimum_size"},   {"mnmO", "minimum_opacity"},
      {"Cnt ", "count"},          {"Sftn", "softness"},
      {"MdID", "md_id"},          {"SmpI", "sampled_index"},
  };

  for (const auto &p : params) {
    if (p.key.endsWith("Nm  ") && p.type == "TEXT") {
      if (hasActive) {
        brushes.append(current);
      }
      current.clear();
      current["name"] = p.value;
      hasActive = true;
      continue;
    }

    if (!hasActive)
      continue;

    QString shortKey = p.key.right(4).trimmed();

    if (keyMap.contains(shortKey)) {
      QString mappedKey = keyMap[shortKey];
      if (mappedKey != "name") {
        current[mappedKey] = p.value;
      }
    }

    current["_raw_" + p.key] = p.value;
  }

  if (hasActive) {
    brushes.append(current);
  }

  return brushes;
}

// ============================================================================
//  METADATA - TEXTURE CORRELATION
// ============================================================================

void AbrImporter::applyMetadataToBrushes(
    QList<ExtractedBrush> &brushes,
    const QList<QMap<QString, QVariant>> &metadata) {

  qDebug() << "[ABR] Correlating" << brushes.size() << "textures with"
           << metadata.size() << "metadata entries";

  if (brushes.size() == metadata.size()) {
    for (int i = 0; i < brushes.size(); ++i) {
      applyMetadataToSingleBrush(brushes[i], metadata[i]);
    }
    return;
  }

  // More metadata than textures: filter out computed brushes
  if (metadata.size() > brushes.size()) {
    QList<int> sampledMetaIndices;
    for (int i = 0; i < metadata.size(); ++i) {
      QString name = metadata[i].value("name").toString();
      bool looksComputed = name.startsWith("Hard Round") ||
                           name.startsWith("Soft Round") ||
                           name.startsWith("Hard Elliptical") ||
                           name.startsWith("Soft Elliptical");
      if (!looksComputed) {
        sampledMetaIndices.append(i);
      }
    }

    if (sampledMetaIndices.size() == brushes.size()) {
      qDebug() << "[ABR] Filtered correlation:" << sampledMetaIndices.size()
               << "sampled <->" << brushes.size() << "textures";
      for (int i = 0; i < brushes.size(); ++i) {
        applyMetadataToSingleBrush(brushes[i], metadata[sampledMetaIndices[i]]);
      }
      return;
    }
  }

  // Partial sequential correlation
  int n = qMin(brushes.size(), metadata.size());
  qDebug() << "[ABR] Partial correlation:" << n;
  for (int i = 0; i < n; ++i) {
    applyMetadataToSingleBrush(brushes[i], metadata[i]);
  }
}

void AbrImporter::applyMetadataToSingleBrush(
    ExtractedBrush &brush, const QMap<QString, QVariant> &md) {
  brush.hasMetadata = true;

  if (md.contains("name"))
    brush.name = md["name"].toString();
  if (md.contains("diameter"))
    brush.diameter = md["diameter"].toFloat();
  if (md.contains("spacing"))
    brush.spacing = md["spacing"].toFloat();
  if (md.contains("hardness"))
    brush.hardness = md["hardness"].toFloat();
  if (md.contains("angle"))
    brush.angle = md["angle"].toFloat();
  if (md.contains("roundness"))
    brush.roundness = md["roundness"].toFloat();
  if (md.contains("flow"))
    brush.flow = md["flow"].toFloat();
  if (md.contains("opacity"))
    brush.opacity = md["opacity"].toFloat();
  if (md.contains("scatter"))
    brush.scatter = md["scatter"].toFloat();
  if (md.contains("wetness"))
    brush.wetness = md["wetness"].toFloat();
  if (md.contains("size_jitter"))
    brush.sizeJitter = md["size_jitter"].toFloat();
  if (md.contains("opacity_jitter"))
    brush.opacityJitter = md["opacity_jitter"].toFloat();
  if (md.contains("minimum_size"))
    brush.minimumSize = md["minimum_size"].toFloat();
  if (md.contains("minimum_opacity"))
    brush.minimumOpacity = md["minimum_opacity"].toFloat();
}

// ============================================================================
//  TEXTURE EXTRACTION: V1 (Legacy)
// ============================================================================

bool AbrImporter::readAbrV1(const QByteArray &data, QDataStream &in,
                            QList<ExtractedBrush> &brushes) {
  Q_UNUSED(data);
  qint16 count;
  in >> count;

  for (int i = 0; i < count; i++) {
    if (in.atEnd())
      break;

    qint16 type;
    in >> type;
    quint32 size;
    in >> size;

    qint64 nextBrushPos = in.device()->pos() + size;

    if (type == 2) {
      quint32 miscSize;
      in >> miscSize;
      in.skipRawData(miscSize);

      qint16 spacing;
      in >> spacing;
      qint16 diameter;
      in >> diameter;

      quint32 height;
      in >> height;
      quint32 width;
      in >> width;

      in.skipRawData(4);

      if (width > 0 && height > 0 && width <= 4096 && height <= 4096) {
        QImage img(width, height, QImage::Format_Grayscale8);
        for (int y = 0; y < (int)height; y++) {
          if (in.atEnd())
            break;
          in.readRawData((char *)img.scanLine(y), width);
        }
        img.invertPixels();
        ExtractedBrush b;
        b.image = img;
        b.spacing = spacing;
        b.diameter = diameter;
        brushes.append(b);
      }
    }

    in.device()->seek(nextBrushPos);
  }
  return true;
}

// ============================================================================
//  TEXTURE EXTRACTION: Image block scanner (samp/IDNA)
//  Scans for \x00\x00\x00\x08 depth marker followed by valid image rect
// ============================================================================

bool AbrImporter::readImageBlock(const QByteArray &blockData,
                                 QList<ExtractedBrush> &brushes) {
  const QByteArray depthMarker = QByteArrayLiteral("\x00\x00\x00\x08");
  int pos = 0;
  int found = 0;

  while (pos < blockData.size() - 23) {
    int markerIdx = blockData.indexOf(depthMarker, pos);
    if (markerIdx == -1)
      break;

    // After marker: rect (16B: T,L,B,R) + depth (2B) + comp (1B)
    int rectStart = markerIdx + 4;
    if (rectStart + 19 > blockData.size()) {
      pos = markerIdx + 4;
      continue;
    }

    QDataStream rs(blockData.mid(rectStart, 16));
    rs.setByteOrder(QDataStream::BigEndian);
    qint32 t, l, b, r;
    rs >> t >> l >> b >> r;

    int w = r - l;
    int h = b - t;

    if (w <= 0 || h <= 0 || w > 8192 || h > 8192) {
      pos = markerIdx + 4;
      continue;
    }

    quint16 depth;
    QDataStream ds(blockData.mid(rectStart + 16, 2));
    ds.setByteOrder(QDataStream::BigEndian);
    ds >> depth;

    if (depth != 8 && depth != 1 && depth != 16) {
      pos = markerIdx + 4;
      continue;
    }

    quint8 comp = (quint8)blockData[rectStart + 18];
    if (comp != 0 && comp != 1) {
      pos = markerIdx + 4;
      continue;
    }

    int pixelDataStart = rectStart + 19;

    ExtractedBrush bBrush;
    bBrush.spacing = 25;
    bool success = false;

    if (comp == 0) {
      // RAW pixels
      int rawSize = w * h;
      if (pixelDataStart + rawSize <= blockData.size()) {
        QImage img(w, h, QImage::Format_Grayscale8);
        int srcOff = pixelDataStart;
        for (int y = 0; y < h; ++y) {
          memcpy(img.scanLine(y), blockData.constData() + srcOff, w);
          srcOff += w;
        }
        img.invertPixels();
        bBrush.image = img;
        success = true;
        pos = pixelDataStart + rawSize;
      } else {
        pos = markerIdx + 4;
        continue;
      }
    } else if (comp == 1) {
      // RLE compressed
      if (pixelDataStart + 2 * h > blockData.size()) {
        pos = markerIdx + 4;
        continue;
      }

      // Read per-row byte counts
      QVector<quint16> rowLengths(h);
      int totalRLE = 0;
      {
        QDataStream rlStream(blockData.mid(pixelDataStart, 2 * h));
        rlStream.setByteOrder(QDataStream::BigEndian);
        for (int y = 0; y < h; ++y) {
          quint16 rl;
          rlStream >> rl;
          rowLengths[y] = rl;
          totalRLE += rl;
        }
      }

      int rleDataStart = pixelDataStart + 2 * h;
      if (rleDataStart + totalRLE > blockData.size()) {
        totalRLE = blockData.size() - rleDataStart;
        if (totalRLE <= 0) {
          pos = markerIdx + 4;
          continue;
        }
      }

      QDataStream rleDataStream(blockData.mid(rleDataStart, totalRLE));
      rleDataStream.setByteOrder(QDataStream::BigEndian);

      QImage img = decodeRLEImage(rleDataStream, w, h);
      if (!img.isNull()) {
        img.invertPixels();
        bBrush.image = img;
        success = true;
      }

      pos = rleDataStart + totalRLE;
    }

    if (success) {
      found++;
      brushes.append(bBrush);
    } else {
      pos = markerIdx + 4;
    }
  }

  qDebug() << "[ABR] readImageBlock: found" << found << "textures in"
           << blockData.size() << "bytes";
  return found > 0;
}

// ============================================================================
//  TEXTURE EXTRACTION: V6/V10 (legacy wrapper)
// ============================================================================

bool AbrImporter::readAbrV6(const QByteArray &data, QDataStream &in,
                            QList<ExtractedBrush> &brushes, int version) {
  Q_UNUSED(in);
  Q_UNUSED(version);
  int sampIdx = data.indexOf("8BIMsamp");
  if (sampIdx == -1) {
    qWarning() << "[ABR] No 'samp' block found.";
    return false;
  }

  int next8BIM = data.indexOf("8BIM", sampIdx + 8);
  int dataStart = sampIdx + 12;
  int dataSize =
      (next8BIM != -1) ? (next8BIM - dataStart) : (data.size() - dataStart);

  QByteArray sampData = data.mid(dataStart, dataSize);
  return readImageBlock(sampData, brushes);
}

// ============================================================================
//  TEXTURE EXTRACTION: PNG Mining (Modern)
// ============================================================================

bool AbrImporter::readModernPNG(const QByteArray &data,
                                QList<ExtractedBrush> &brushes) {
  const QByteArray pngSig = QByteArrayLiteral("\x89PNG\r\n\x1a\n");
  const QByteArray iendSig = QByteArrayLiteral("IEND");

  int offset = 0;
  while (true) {
    int start = data.indexOf(pngSig, offset);
    if (start == -1)
      break;

    int iend = data.indexOf(iendSig, start);
    if (iend == -1)
      break;

    int end = iend + 8;

    QByteArray pngData = data.mid(start, end - start);
    QImage img;
    if (img.loadFromData(pngData, "PNG")) {
      QImage composed(img.size(), QImage::Format_ARGB32_Premultiplied);
      composed.fill(Qt::white);
      QPainter p(&composed);
      p.drawImage(0, 0, img);
      p.end();

      QImage finalImg = composed.convertToFormat(QImage::Format_Grayscale8);
      finalImg.invertPixels();

      ExtractedBrush b;
      b.image = finalImg;
      b.spacing = 25;

      // Try to find nearby name from descriptor
      int searchStart = qMax(0, start - 500);
      QByteArray vicinity = data.mid(searchStart, start - searchStart);
      int textIdx = vicinity.lastIndexOf("TEXT");
      if (textIdx != -1 && textIdx + 8 < vicinity.size()) {
        QDataStream ts(vicinity.mid(textIdx + 4, 4));
        ts.setByteOrder(QDataStream::BigEndian);
        quint32 textLen;
        ts >> textLen;
        if (textLen > 0 && textLen < 200) {
          int tStart = textIdx + 8;
          int tEnd = qMin(tStart + (int)textLen * 2, vicinity.size());
          QByteArray textBytes = vicinity.mid(tStart, tEnd - tStart);
          QString name;
          for (int i = 0; i + 1 < textBytes.size(); i += 2) {
            quint16 ch = ((quint8)textBytes[i] << 8) | (quint8)textBytes[i + 1];
            if (ch == 0)
              break;
            name.append(QChar(ch));
          }
          if (name.length() > 1) {
            b.name = name;
          }
        }
      }

      brushes.append(b);
    }
    offset = end;
  }

  qDebug() << "[ABR] PNG brushes extracted:" << brushes.size();
  return !brushes.isEmpty();
}

// ============================================================================
//  RLE DECODING (PackBits)
// ============================================================================

QImage AbrImporter::decodeRLEImage(QDataStream &in, int width, int height) {
  QImage img(width, height, QImage::Format_Grayscale8);
  img.fill(255);

  for (int y = 0; y < height; ++y) {
    uchar *scanline = img.scanLine(y);
    int x = 0;

    while (x < width) {
      if (in.atEnd())
        break;
      qint8 n;
      in >> n;

      if (n >= 0) {
        int count = n + 1;
        for (int i = 0; i < count; ++i) {
          if (in.atEnd())
            break;
          qint8 val;
          in >> val;
          if (x < width)
            scanline[x++] = (uchar)val;
        }
      } else if (n >= -127 && n <= -1) {
        if (in.atEnd())
          break;
        qint8 val;
        in >> val;
        int count = -n + 1;
        for (int i = 0; i < count; ++i) {
          if (x < width)
            scanline[x++] = (uchar)val;
        }
      }
    }
  }
  return img;
}

} // namespace artflow
