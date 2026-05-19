/**
 * ArtFlow Studio - ABR Parser Implementation
 *
 * ABR v6/sub2 (Photoshop CS3-CC 2024) format:
 * - All brushes are inside a single "8BIMsamp" resource block
 * - Each brush is prefixed by a 4-byte size, then a UUID string + null
 * - After the UUID null, there's a metadata block (~263 bytes typical)
 * - The bitmap header is found by scanning for the pattern:
 *     top(int32), left(int32), bottom(int32), right(int32), depth(int16), comp(uint8)
 *   where height = bottom-top, width = right-left are valid dimensions
 *   and depth is 8 or 16 and comp is 0 or 1
 * - After the bitmap header (19 bytes):
 *   if comp==1: row-size table (height x uint16 BE), then PackBits data
 *   if comp==0: raw pixel data
 */

#include "abr_parser.h"

#include <QByteArray>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QJsonObject>
#include <QRegularExpression>
#include <QString>
#include <QDebug>
#include <algorithm>
#include <cmath>
#include <cstring>

// ════════════════════════════════════════════════════════════════════
//  Big-endian helpers
// ════════════════════════════════════════════════════════════════════

static inline int16_t  s16(const QByteArray &d, int o) {
    return static_cast<int16_t>((static_cast<uint8_t>(d[o]) << 8) |
                                  static_cast<uint8_t>(d[o+1]));
}
static inline uint16_t u16(const QByteArray &d, int o) {
    return static_cast<uint16_t>((static_cast<uint8_t>(d[o]) << 8) |
                                   static_cast<uint8_t>(d[o+1]));
}
static inline int32_t  s32(const QByteArray &d, int o) {
    return static_cast<int32_t>(
        (static_cast<uint8_t>(d[o    ]) << 24) |
        (static_cast<uint8_t>(d[o + 1]) << 16) |
        (static_cast<uint8_t>(d[o + 2]) <<  8) |
         static_cast<uint8_t>(d[o + 3]));
}
static inline uint32_t u32(const QByteArray &d, int o) {
    return static_cast<uint32_t>(s32(d, o));
}
static inline uint8_t  u8(const QByteArray &d, int o) {
    return static_cast<uint8_t>(d[o]);
}

// ABRParser public wrappers
int16_t  ABRParser::readInt16BE (const QByteArray &d, int o) { return s16(d, o); }
int32_t  ABRParser::readInt32BE (const QByteArray &d, int o) { return s32(d, o); }
uint32_t ABRParser::readUInt32BE(const QByteArray &d, int o) { return u32(d, o); }

// ════════════════════════════════════════════════════════════════════
//  String readers (legacy v1/v2)
// ════════════════════════════════════════════════════════════════════

QByteArray ABRParser::readPascalString(const QByteArray &data, int &offset, int padTo) {
    if (offset >= data.size()) return {};
    int len = u8(data, offset++);
    QByteArray str = data.mid(offset, len);
    offset += len;
    int total = 1 + len;
    int mod = total % padTo;
    if (mod) offset += padTo - mod;
    return str;
}

QString ABRParser::readUnicodeString(const QByteArray &data, int &offset) {
    if (offset + 4 > data.size()) return {};
    int count = s32(data, offset); offset += 4;
    if (count <= 0 || offset + count * 2 > data.size()) return {};
    QString result;
    for (int i = 0; i < count; ++i) {
        ushort ch = u16(data, offset); offset += 2;
        if (ch) result.append(QChar(ch));
    }
    return result;
}

// ════════════════════════════════════════════════════════════════════
//  PackBits RLE decompressor
// ════════════════════════════════════════════════════════════════════

QByteArray ABRParser::unpackBits(const QByteArray &packed, int expectedBytes) {
    QByteArray out;
    out.reserve(expectedBytes);
    int i = 0;
    while (i < packed.size() && out.size() < expectedBytes) {
        int8_t h = static_cast<int8_t>(packed[i++]);
        if (h >= 0) {
            int count = h + 1;
            for (int k = 0; k < count && i < packed.size(); ++k)
                out.append(packed[i++]);
        } else if (h != -128) {
            int count = -h + 1;
            if (i >= packed.size()) break;
            char byte = packed[i++];
            for (int k = 0; k < count; ++k)
                out.append(byte);
        }
    }
    while (out.size() < expectedBytes)
        out.append('\0');
    return out;
}

// ════════════════════════════════════════════════════════════════════
//  ABRBrush::decodeTip
// ════════════════════════════════════════════════════════════════════

bool ABRBrush::decodeTip() {
    if (!alphaMask.isEmpty()) return true;

    // Computed / round brush: generate procedural tip
    if (brushType == 1 || compressedData.isEmpty()) {
        int d = std::max(patternWidth, 2);
        patternWidth = patternHeight = d;
        alphaMask.resize(d * d, 0.0f);

        float cx  = (d - 1) / 2.0f;
        float r   = d / 2.0f;
        float h   = std::clamp(hardness, 0.0f, 1.0f);
        float edge = std::max(1.0f - h, 0.001f);

        for (int y = 0; y < d; ++y)
            for (int x = 0; x < d; ++x) {
                float dx = x - cx, dy = y - cx;
                float dist = std::sqrt(dx*dx + dy*dy) / r;
                float v = 0.0f;
                if (dist <= 1.0f) {
                    v = (dist < h) ? 1.0f :
                        0.5f * (1.0f + std::cos((dist - h) / edge * 3.14159265f));
                }
                // Convention: 0=background, 1=ink (will be inverted in toImage)
                alphaMask[y * d + x] = v;
            }
        return true;
    }

    // Sampled brush: decompress stored pixel data
    if (patternWidth <= 0 || patternHeight <= 0) return false;

    int totalPixels   = patternWidth * patternHeight;
    int bytesPerPixel = (rawDepth + 7) / 8;
    int expectedBytes = totalPixels * bytesPerPixel;

    QByteArray raw;
    if (!compressed) {
        raw = compressedData.left(expectedBytes);
    } else {
        raw = ABRParser::unpackBits(compressedData, expectedBytes);
    }

    alphaMask.resize(totalPixels);
    if (rawDepth == 16) {
        float scale = 1.0f / 65535.0f;
        for (int i = 0; i < totalPixels; ++i) {
            uint16_t v = static_cast<uint16_t>(
                (u8(raw, i*2) << 8) | u8(raw, i*2+1));
            alphaMask[i] = v * scale;
        }
    } else {
        // ABR grayscale: 0=black(ink), 255=white(background)
        // Store as float 0..1 matching raw byte / 255
        float scale = 1.0f / 255.0f;
        for (int i = 0; i < std::min(totalPixels, (int)raw.size()); ++i)
            alphaMask[i] = static_cast<uint8_t>(raw[i]) * scale;
    }
    return true;
}

// ════════════════════════════════════════════════════════════════════
//  ABRBrush helpers
// ════════════════════════════════════════════════════════════════════

QImage ABRBrush::toImage() {
    if (!decodeTip()) return {};
    
    // Create a perfect square image to prevent stretching in OpenGL (dab quads are square)
    int d = diameter > 0 ? diameter : std::max(patternWidth, patternHeight);
    QImage img(d, d, QImage::Format_RGBA8888);
    img.fill(QColor(0, 0, 0, 0)); // Fill with transparent background

    int offsetX = (d - patternWidth) / 2;
    int offsetY = (d - patternHeight) / 2;

    for (int y = 0; y < patternHeight; ++y) {
        int destY = y + offsetY;
        if (destY < 0 || destY >= d) continue;
        uchar *row = img.scanLine(destY);
        for (int x = 0; x < patternWidth; ++x) {
            int destX = x + offsetX;
            if (destX < 0 || destX >= d) continue;
            
            float v = alphaMask[y * patternWidth + x];
            uchar a = static_cast<uchar>(v * 255.0f);
            
            // Output White RGB + Alpha mask
            row[destX*4 + 0] = 255; // R
            row[destX*4 + 1] = 255; // G
            row[destX*4 + 2] = 255; // B
            row[destX*4 + 3] = a;   // A
        }
    }
    return img;
}

QByteArray ABRBrush::getPattern() const {
    QByteArray out;
    out.resize(alphaMask.size() * 4);
    std::memcpy(out.data(), alphaMask.constData(), out.size());
    return out;
}

QJsonObject ABRBrush::toJson() const {
    QJsonObject o;
    o["name"]          = name;
    o["diameter"]      = diameter;
    o["spacing"]       = static_cast<double>(spacing);
    o["angle"]         = static_cast<double>(angle);
    o["roundness"]     = static_cast<double>(roundness);
    o["patternWidth"]  = patternWidth;
    o["patternHeight"] = patternHeight;
    o["cachePath"]     = cachePath;
    o["brushType"]     = brushType;
    return o;
}

// ════════════════════════════════════════════════════════════════════
//  isValidABR
// ════════════════════════════════════════════════════════════════════

bool ABRParser::isValidABR(const QString &path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) return false;
    QByteArray header = f.read(4);
    f.close();
    if (header.size() < 2) return false;
    int16_t ver = s16(header, 0);
    return (ver >= 1 && ver <= 10);
}

// ════════════════════════════════════════════════════════════════════
//  findBitmapHeader — scans for valid bounds+depth+comp pattern
// ════════════════════════════════════════════════════════════════════

struct BitmapHeader {
    int offset = -1;       // absolute offset in file
    int top = 0, left = 0, bottom = 0, right = 0;
    int width = 0, height = 0;
    int depth = 8;
    int comp = 1;
};

static BitmapHeader findBitmapHeader(const QByteArray &data, int start, int end) {
    BitmapHeader hdr;
    int limit = std::min(end - 18, start + 800);
    for (int off = start; off < limit; ++off) {
        int32_t top    = s32(data, off);
        int32_t left_  = s32(data, off + 4);
        int32_t bottom = s32(data, off + 8);
        int32_t right  = s32(data, off + 12);
        int16_t depth  = s16(data, off + 16);
        uint8_t comp   = u8 (data, off + 18);

        int h = bottom - top;
        int w = right - left_;

        if (top >= 0 && top <= 500 && left_ >= 0 && left_ <= 500 &&
            h >= 1 && h <= 16384 && w >= 1 && w <= 16384 &&
            (depth == 8 || depth == 16) && comp <= 1) {
            hdr.offset = off;
            hdr.top = top; hdr.left = left_; hdr.bottom = bottom; hdr.right = right;
            hdr.width = w; hdr.height = h;
            hdr.depth = depth; hdr.comp = comp;
            return hdr;
        }
    }
    return hdr; // offset == -1 means not found
}

// ════════════════════════════════════════════════════════════════════
//  parseSampBlock — v6/sub2 modern format
// ════════════════════════════════════════════════════════════════════

std::vector<ABRBrush> ABRParser::parseSampBlock(const QByteArray &data,
                                                 int sampStart, int sampEnd,
                                                 const std::map<QString, QString> &uuidNames) {
    std::vector<ABRBrush> brushes;

    // Find all UUID markers in the samp block
    static const QRegularExpression uuidRe(
        "\\$[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
        "[0-9a-fA-F]{4}-[0-9a-fA-F]{12}");

    QString sampStr = QString::fromLatin1(data.mid(sampStart, sampEnd - sampStart));
    QRegularExpressionMatchIterator it = uuidRe.globalMatch(sampStr);

    struct UUIDMatch { int absStart; int absAfterNull; QString uuid; };
    std::vector<UUIDMatch> uuids;

    while (it.hasNext()) {
        QRegularExpressionMatch m = it.next();
        UUIDMatch um;
        um.absStart     = sampStart + m.capturedStart();
        um.absAfterNull = sampStart + m.capturedEnd() + 1; // +1 for null byte
        um.uuid         = m.captured().mid(1); // strip $
        uuids.push_back(um);
    }

    qDebug() << "[ABRParser] Found" << uuids.size() << "UUID entries in samp block";

    for (size_t idx = 0; idx < uuids.size(); ++idx) {
        const auto &um = uuids[idx];
        int after = um.absAfterNull;

        // Determine brush data end using the 4-byte size field before the UUID
        int sizeFieldOff = um.absStart - 4;
        int brushDataEnd = sampEnd;
        if (sizeFieldOff >= sampStart) {
            uint32_t brushTotalSize = u32(data, sizeFieldOff);
            if (brushTotalSize > 0 && brushTotalSize < 50000000) {
                brushDataEnd = std::min(static_cast<int>(sizeFieldOff + 4 + brushTotalSize),
                                        sampEnd);
            }
        }

        // Search for bitmap header (bounds + depth + comp)
        BitmapHeader hdr = findBitmapHeader(data, after, brushDataEnd);
        if (hdr.offset < 0) {
            qDebug() << "[ABRParser] Brush" << (idx+1) << um.uuid
                     << ": no bitmap header, skipping";
            continue;
        }

        ABRBrush brush;
        brush.brushType     = 2;
        brush.patternWidth  = hdr.width;
        brush.patternHeight = hdr.height;
        brush.rawDepth      = hdr.depth;
        brush.compressed    = (hdr.comp == 1);
        brush.diameter      = std::max(hdr.width, hdr.height);
        brush.name = (uuidNames.count(um.uuid) > 0) ? uuidNames.at(um.uuid) : 
                     QString("Brush %1 (%2x%3)").arg(idx + 1).arg(hdr.width).arg(hdr.height);
        brush.spacing       = 0.25f;

        // Pixel data starts at header + 19 bytes (4+4+4+4+2+1 = bounds+depth+comp)
        int pixelMeta = hdr.offset + 19;
        int bpp       = hdr.depth / 8;
        int expectedRaw = hdr.width * hdr.height * bpp;

        if (hdr.comp == 1) {
            int tableEnd = pixelMeta + hdr.height * 2;
            if (tableEnd > brushDataEnd) continue;

            int compTotal = 0;
            for (int r = 0; r < hdr.height; ++r)
                compTotal += u16(data, pixelMeta + r * 2);

            int pixelStart = tableEnd;
            int pixelEnd   = std::min(pixelStart + compTotal, brushDataEnd);
            brush.compressedData = data.mid(pixelStart, pixelEnd - pixelStart);
        } else {
            int pixelEnd = std::min(pixelMeta + expectedRaw, brushDataEnd);
            brush.compressedData = data.mid(pixelMeta, pixelEnd - pixelMeta);
        }

        brushes.push_back(std::move(brush));
    }

    return brushes;
}

// ════════════════════════════════════════════════════════════════════
//  v1/v2 legacy parsers
// ════════════════════════════════════════════════════════════════════

ABRBrush ABRParser::parseComputedBlock(const QByteArray &data, int &offset,
                                       int blockEnd, int, int) {
    ABRBrush brush;
    brush.brushType = 1;
    if (offset + 4 > blockEnd) return brush;
    offset += 2;
    brush.spacing = s16(data, offset) / 100.0f; offset += 2;
    QByteArray pname = readPascalString(data, offset, 2);
    brush.name = QString::fromLatin1(pname);
    if (brush.name.isEmpty()) brush.name = "Round Brush";
    if (offset + 8 <= blockEnd) {
        brush.diameter  = s16(data, offset); offset += 2;
        brush.roundness = s16(data, offset) / 100.0f; offset += 2;
        brush.angle     = static_cast<float>(s16(data, offset)); offset += 2;
        brush.hardness  = s16(data, offset) / 100.0f; offset += 2;
    }
    int d = std::max(brush.diameter, 2);
    brush.patternWidth = brush.patternHeight = d;
    return brush;
}

ABRBrush ABRParser::parseSampledBlock(const QByteArray &data, int &offset,
                                      int blockEnd, int, int) {
    ABRBrush brush;
    brush.brushType = 2;
    if (offset + 4 > blockEnd) return brush;
    offset += 2;
    brush.spacing = s16(data, offset) / 100.0f; offset += 2;
    QByteArray pname = readPascalString(data, offset, 2);
    brush.name = QString::fromLatin1(pname);
    if (offset + 9 > blockEnd) return brush;
    offset += 2; // mode
    int rows = s16(data, offset); offset += 2;
    int cols = s16(data, offset); offset += 2;
    int depth = s16(data, offset); offset += 2;
    bool comp = (u8(data, offset++) != 0);
    brush.patternHeight = rows;
    brush.patternWidth  = cols;
    brush.rawDepth      = depth;
    brush.compressed    = comp;
    brush.diameter      = std::max(rows, cols);
    if (rows <= 0 || cols <= 0) return brush;
    if (comp) {
        int tableBytes = rows * 2;
        if (offset + tableBytes <= blockEnd)
            offset += tableBytes;
    }
    int remaining = blockEnd - offset;
    if (remaining > 0)
        brush.compressedData = data.mid(offset, remaining);
    return brush;
}

// ════════════════════════════════════════════════════════════════════
//  ABRParser::parse — main entry point
// ════════════════════════════════════════════════════════════════════

ABRFile ABRParser::parse(const QString &path) {
    ABRFile result;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "[ABRParser] Cannot open:" << path;
        return result;
    }
    QByteArray data = file.readAll();
    file.close();
    if (data.size() < 4) return result;

    int16_t version    = s16(data, 0);
    int16_t subVersion = s16(data, 2);
    result.version = version;

    qDebug() << "[ABRParser] v" << version << "sub" << subVersion
             << "| size:" << data.size() << "bytes";

    if (version >= 6) {
        int sampPos = data.indexOf("8BIMsamp");
        if (sampPos >= 0) {
            uint32_t sampSize  = u32(data, sampPos + 8);
            int      sampStart = sampPos + 12;
            int      sampEnd   = static_cast<int>(
                std::min<qint64>(sampStart + sampSize, data.size()));
            qDebug() << "[ABRParser] 8BIMsamp at" << sampPos << "size" << sampSize;

            // Extract brush names from 8BIMdesc if present
            std::map<QString, QString> uuidNames;
            int descPos = data.indexOf("8BIMdesc");
            if (descPos >= 0) {
                uint32_t descSize = u32(data, descPos + 8);
                int descStart = descPos + 12;
                int descEnd = static_cast<int>(std::min<qint64>(descStart + descSize, data.size()));
                
                QString lastName;
                static const QRegularExpression uuidRe("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");
                
                for (int offset = descStart; offset < descEnd - 4; ++offset) {
                    if (data[offset] == 'T' && data[offset+1] == 'E' && data[offset+2] == 'X' && data[offset+3] == 'T') {
                        uint32_t strLen = u32(data, offset + 4);
                        if (strLen > 0 && strLen < 500 && offset + 8 + strLen * 2 <= descEnd) {
                            QString text;
                            int textOffset = offset + 8;
                            for (uint32_t i = 0; i < strLen; ++i) {
                                ushort ch = u16(data, textOffset);
                                textOffset += 2;
                                if (ch) text.append(QChar(ch));
                            }
                            
                            if (uuidRe.match(text).hasMatch()) {
                                if (!lastName.isEmpty()) {
                                    uuidNames[text] = lastName;
                                }
                            } else {
                                // Ignore common structural names, keep human-readable ones
                                if (text.length() > 2 && text != "null") {
                                    lastName = text;
                                }
                            }
                        }
                    }
                }
                qDebug() << "[ABRParser] Extracted" << uuidNames.size() << "brush names from 8BIMdesc";
            }

            result.brushes = parseSampBlock(data, sampStart, sampEnd, uuidNames);
        } else {
            qWarning() << "[ABRParser] v6 but no 8BIMsamp block found";
        }
    } else {
        int offset = 4;
        while (offset + 6 <= data.size()) {
            int16_t brushType = s16(data, offset); offset += 2;
            int32_t blockSize = s32(data, offset); offset += 4;
            int blockEnd = static_cast<int>(
                std::min<qint64>(offset + blockSize, data.size()));
            ABRBrush brush;
            if (brushType == 1)
                brush = parseComputedBlock(data, offset, blockEnd, version, subVersion);
            else if (brushType == 2)
                brush = parseSampledBlock(data, offset, blockEnd, version, subVersion);
            offset = blockEnd;
            if (brush.patternWidth > 0 && brush.patternHeight > 0)
                result.brushes.push_back(std::move(brush));
        }
    }

    qDebug() << "[ABRParser] Parsed" << result.brushes.size() << "brushes.";
    return result;
}

// ════════════════════════════════════════════════════════════════════
//  exportToCache / loadFromCache
// ════════════════════════════════════════════════════════════════════

int ABRParser::exportToCache(ABRFile &file, const QString &cacheDir,
                              std::function<void(int,int)> progressCb) {
    QDir().mkpath(cacheDir);
    int total = static_cast<int>(file.brushes.size());
    int done  = 0, cached = 0;

    for (ABRBrush &brush : file.brushes) {
        QString safeName = brush.name;
        safeName.replace(QRegularExpression("[^A-Za-z0-9_]"), "_");
        QString cachePath = cacheDir + "/" +
            QString("%1_%2x%3.png").arg(safeName)
                                   .arg(brush.patternWidth)
                                   .arg(brush.patternHeight);

        if (!QFile::exists(cachePath)) {
            QImage img = brush.toImage();
            if (!img.isNull() && img.save(cachePath, "PNG"))
                ++cached;
        } else {
            ++cached;
        }
        brush.cachePath = cachePath;
        if (progressCb) progressCb(++done, total);
    }
    return cached;
}

void ABRParser::loadFromCache(ABRFile &file, const QString &cacheDir) {
    for (ABRBrush &brush : file.brushes) {
        QString safeName = brush.name;
        safeName.replace(QRegularExpression("[^A-Za-z0-9_]"), "_");
        QString cachePath = cacheDir + "/" +
            QString("%1_%2x%3.png").arg(safeName)
                                   .arg(brush.patternWidth)
                                   .arg(brush.patternHeight);
        if (QFile::exists(cachePath))
            brush.cachePath = cachePath;
    }
}
