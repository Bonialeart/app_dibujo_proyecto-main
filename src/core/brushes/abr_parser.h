/**
 * ArtFlow Studio — ABR Parser
 *
 * Supports ABR v1/v2 (legacy) and v6/sub2 (modern Photoshop CS3–CC 2024).
 *
 * v6/sub2 format uses a single "8BIMsamp" resource block that contains all
 * brushes.  Each brush is identified by a null-terminated UUID string and has
 * a fixed-size binary header at confirmed byte offsets.
 */

#pragma once

#include <QString>
#include <QByteArray>
#include <QImage>
#include <QJsonObject>
#include <vector>
#include <map>
#include <functional>

// ── Parsed brush tip ─────────────────────────────────────────────────────────
struct ABRBrush {
    QString  name;
    int      diameter      = 0;
    float    spacing       = 0.25f;
    float    angle         = 0.0f;
    float    roundness     = 1.0f;
    float    hardness      = 0.8f;
    int      patternWidth  = 0;
    int      patternHeight = 0;

    // Pixel data (already stripped of row-offset table)
    QByteArray compressedData;
    int        rawDepth   = 8;    // bits per channel
    bool       compressed = true; // true=PackBits, false=raw
    int        brushType  = 2;    // 1=computed/round, 2=sampled/bitmap

    // Decoded alpha mask — empty until decodeTip() is called
    QVector<float> alphaMask; // row-major [0..1], patternWidth×patternHeight

    QString cachePath;

    bool   decodeTip();
    QImage toImage();
    QJsonObject toJson() const;
    QByteArray  getPattern() const;
};

// ── Container ────────────────────────────────────────────────────────────────
struct ABRFile {
    int                   version = 0;
    std::vector<ABRBrush> brushes;
};

// ── Parser ───────────────────────────────────────────────────────────────────
class ABRParser {
public:
    static ABRFile parse(const QString &path);
    static bool    isValidABR(const QString &path);

    static int  exportToCache(ABRFile &file,
                               const QString &cacheDir,
                               std::function<void(int,int)> progressCb = nullptr);
    static void loadFromCache(ABRFile &file, const QString &cacheDir);

    // Public: used by ABRBrush::decodeTip()
    static QByteArray unpackBits(const QByteArray &packed, int expectedBytes);

    // Public: parses the "8BIMsamp" block (v6/sub2 modern format)
    static std::vector<ABRBrush> parseSampBlock(const QByteArray &data,
                                                 int sampStart, int sampEnd,
                                                 const std::map<QString, QString> &uuidNames = {});

private:
    // v1/v2 legacy block parsers
    static ABRBrush parseComputedBlock(const QByteArray &data, int &offset,
                                       int blockEnd, int version, int subVersion);
    static ABRBrush parseSampledBlock (const QByteArray &data, int &offset,
                                       int blockEnd, int version, int subVersion);

    static QByteArray readPascalString(const QByteArray &data, int &offset,
                                       int padTo = 2);
    static QString    readUnicodeString(const QByteArray &data, int &offset);
    static int16_t    readInt16BE (const QByteArray &data, int offset);
    static int32_t    readInt32BE (const QByteArray &data, int offset);
    static uint32_t   readUInt32BE(const QByteArray &data, int offset);
};
