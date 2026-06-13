#include "ProjectModel.h"
#include <QDir>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QSettings>
#include <QSet>
#include <QVariantMap>
#include <QUrl>
#include <QDateTime>
#include <QFile>
#include <algorithm>

namespace {
bool hasProjectExtension(const QString &name) {
    const QString n = name.toLower();
    return n.endsWith(".kromo") || n.endsWith(".kstudio") || n.endsWith(".stxf") ||
           n.endsWith(".aflow") || n.endsWith(".artflow");
}

// Lee la miniatura base64 embebida de un archivo de proyecto y la devuelve como data URL.
QString readProjectThumbnail(const QString &filePath) {
    QFile f(filePath);
    if (f.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        f.close();
        if (!doc.isNull() && doc.object().contains("thumbnail")) {
            const QString b64 = doc.object()["thumbnail"].toString();
            if (!b64.isEmpty())
                return "data:image/png;base64," + b64;
        }
    }
    return QString();
}

// Construye un item de carpeta (con hasta 3 miniaturas internas) para la galería.
QVariantMap makeFolderItem(const QFileInfo &info) {
    QVariantMap item;
    item["name"] = info.fileName();
    item["path"] = info.absoluteFilePath();
    item["type"] = "folder";
    item["date"] = info.lastModified().toString("dd MMM yyyy");

    QDir subDir(info.absoluteFilePath());
    const QFileInfoList subEntries = subDir.entryInfoList(
        QStringList() << "*.kromo" << "*.kstudio" << "*.stxf" << "*.aflow" << "*.artflow",
        QDir::Files, QDir::Time);
    QVariantList thumbs;
    for (int i = 0; i < qMin((int)subEntries.size(), 3); ++i) {
        const QString th = readProjectThumbnail(subEntries[i].absoluteFilePath());
        if (!th.isEmpty())
            thumbs.append(th);
    }
    item["thumbnails"] = thumbs;
    if (!thumbs.isEmpty())
        item["preview"] = thumbs[0];
    return item;
}

bool isGroupFolder(const QFileInfo &info) {
    // Directorio contenedor (no es un proyecto-directorio)
    return info.isDir() && !hasProjectExtension(info.fileName());
}

// Copia recursiva de un directorio (fallback para mover entre volúmenes).
bool copyDirRecursive(const QString &srcPath, const QString &dstPath) {
    QDir srcDir(srcPath);
    if (!srcDir.exists())
        return false;
    if (!QDir().mkpath(dstPath))
        return false;
    const QFileInfoList entries = srcDir.entryInfoList(
        QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden |
        QDir::System);
    for (const QFileInfo &fi : entries) {
        const QString target = dstPath + "/" + fi.fileName();
        if (fi.isDir()) {
            if (!copyDirRecursive(fi.absoluteFilePath(), target))
                return false;
        } else {
            if (QFile::exists(target))
                QFile::remove(target);
            if (!QFile::copy(fi.absoluteFilePath(), target))
                return false;
        }
    }
    return true;
}

// Mueve un archivo o directorio completo de forma fiable: rename atómico y, si
// falla, copia recursiva + borrado. QFile::rename() no mueve directorios; esto sí.
bool moveEntry(const QString &src, const QString &dst) {
    if (src.isEmpty() || dst.isEmpty())
        return false;
    if (QFile::exists(dst))
        return false; // No sobrescribir
    if (QDir().rename(src, dst))
        return true; // Atómico (archivos y directorios, mismo volumen)

    QFileInfo si(src);
    if (si.isDir()) {
        if (copyDirRecursive(src, dst)) {
            QDir(src).removeRecursively();
            return true;
        }
        QDir(dst).removeRecursively();
        return false;
    }
    if (QFile::copy(src, dst)) {
        QFile::remove(src);
        return true;
    }
    return false;
}
} // namespace

QVariantList scanKromoProjects() {
    QVariantList results;

    const QString baseDir =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
        "/KromoStudioProjects";
    if (!QFileInfo(baseDir).isDir())
        QDir().mkpath(baseDir);

    // ── Contenido de la biblioteca central ──────────────────────────────────
    QDir dir(baseDir);
    const QFileInfoList entries = dir.entryInfoList(
        QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot, QDir::Time);

    QSet<QString> listed;
    for (const QFileInfo &info : entries) {
        const QString fn = info.fileName();
        if (fn.endsWith(".png") || fn.endsWith(".jpg") || fn.endsWith(".json"))
            continue;
        // Ocultar la carpeta interna de autoguardado
        if (info.isDir() && (fn == ".autosave" || fn.startsWith(".")))
            continue;

        if (info.isFile() && hasProjectExtension(fn)) {
            QVariantMap item;
            item["name"] = info.completeBaseName();
            item["path"] = info.absoluteFilePath();
            item["type"] = "drawing";
            item["date"] = info.lastModified().toString("dd MMM yyyy");
            const QString th = readProjectThumbnail(info.absoluteFilePath());
            if (!th.isEmpty())
                item["preview"] = th;
            listed.insert(info.absoluteFilePath().toLower());
            results.append(item);
        } else if (info.isDir()) {
            listed.insert(info.absoluteFilePath().toLower());
            results.append(makeFolderItem(info));
        }
    }

    // ── Proyectos/carpetas recientes ubicados FUERA de KromoStudioProjects ───
    QSettings settings;
    const QStringList recents = settings.value("recentProjects").toStringList();
    for (const QString &rp : recents) {
        QFileInfo info(rp);
        if (!info.exists())
            continue;
        const QString key = info.absoluteFilePath().toLower();
        if (listed.contains(key))
            continue;

        if (info.isFile() && hasProjectExtension(info.fileName())) {
            QVariantMap item;
            item["name"] = info.completeBaseName();
            item["path"] = info.absoluteFilePath();
            item["type"] = "drawing";
            item["date"] = info.lastModified().toString("dd MMM yyyy");
            const QString th = readProjectThumbnail(info.absoluteFilePath());
            if (!th.isEmpty())
                item["preview"] = th;
            listed.insert(key);
            results.append(item);
        } else if (info.isDir() && !hasProjectExtension(info.fileName())) {
            // Carpeta de grupo externa (p.ej. una creada al fusionar en el Escritorio)
            listed.insert(key);
            results.append(makeFolderItem(info));
        }
    }

    return results;
}

static const int kMaxRecentProjects = 60;

void recordRecentProject(const QString &path) {
    if (path.isEmpty())
        return;
    QString p = path;
    if (p.startsWith("file:", Qt::CaseInsensitive))
        p = QUrl(p).toLocalFile();
    const QString canonical = QFileInfo(p).absoluteFilePath();
    if (canonical.isEmpty())
        return;
    QSettings settings;
    QStringList list = settings.value("recentProjects").toStringList();
    for (int i = list.size() - 1; i >= 0; --i) {
        if (QString::compare(list[i], canonical, Qt::CaseInsensitive) == 0)
            list.removeAt(i);
    }
    list.prepend(canonical);
    while (list.size() > kMaxRecentProjects)
        list.removeLast();
    settings.setValue("recentProjects", list);
}

bool mergeKromoProjects(const QString &sourcePath, const QString &targetPath) {
    // Resolver posibles URLs file:/// a rutas locales nativas
    QString srcPath = sourcePath;
    QString tgtPath = targetPath;
    if (srcPath.startsWith("file:", Qt::CaseInsensitive))
        srcPath = QUrl(srcPath).toLocalFile();
    if (tgtPath.startsWith("file:", Qt::CaseInsensitive))
        tgtPath = QUrl(tgtPath).toLocalFile();

    if (srcPath.isEmpty() || tgtPath.isEmpty() || srcPath == tgtPath)
        return false;

    QFileInfo srcInfo(srcPath);
    QFileInfo tgtInfo(tgtPath);
    if (!srcInfo.exists() || !tgtInfo.exists())
        return false;

    QDir parentDir = srcInfo.dir();

    // Caso 1: destino = Carpeta de Grupo real → mover el proyecto origen dentro.
    if (isGroupFolder(tgtInfo)) {
        const QString newPath = tgtInfo.absoluteFilePath() + "/" + srcInfo.fileName();
        const bool ok = moveEntry(srcPath, newPath);
        if (ok)
            recordRecentProject(tgtInfo.absoluteFilePath());
        return ok;
    }

    // Caso 2: origen = Carpeta de Grupo, destino = proyecto → mover destino dentro.
    if (isGroupFolder(srcInfo)) {
        const QString newPath = srcInfo.absoluteFilePath() + "/" + tgtInfo.fileName();
        const bool ok = moveEntry(tgtPath, newPath);
        if (ok)
            recordRecentProject(srcInfo.absoluteFilePath());
        return ok;
    }

    // Caso 3: AMBOS son PROYECTOS → crear una nueva Carpeta de Grupo y mover
    // AMBOS dentro. (Corrige el bug de mover un proyecto-directorio dentro de otro.)
    const QString folderName =
        "Group_" + QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
    const QString newDirPath = parentDir.absolutePath() + "/" + folderName;
    if (!QDir().mkpath(newDirPath))
        return false;

    const QString srcDest = newDirPath + "/" + srcInfo.fileName();
    const QString tgtDest = newDirPath + "/" + tgtInfo.fileName();
    const bool ok1 = moveEntry(srcPath, srcDest);
    const bool ok2 = moveEntry(tgtPath, tgtDest);

    if (ok1 && ok2) {
        recordRecentProject(newDirPath);
        return true;
    }

    // Rollback para no dejar proyectos a medias si solo uno se movió.
    if (ok1 && !ok2)
        moveEntry(srcDest, srcPath);
    if (ok2 && !ok1)
        moveEntry(tgtDest, tgtPath);
    QDir(newDirPath).removeRecursively();
    return false;
}

ProjectModel::ProjectModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ProjectModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_projects.size();
}

QVariant ProjectModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_projects.size())
        return QVariant();

    const auto &project = m_projects[index.row()];

    switch (role) {
    case NameRole: return project.name;
    case PathRole: return project.path;
    case PreviewRole: return project.preview;
    case TypeRole: return project.type;
    case DateRole: return project.date;
    case ThumbnailsRole: return project.thumbnails;
    default: return QVariant();
    }
}

QHash<int, QByteArray> ProjectModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PathRole] = "path";
    roles[PreviewRole] = "preview";
    roles[TypeRole] = "type";
    roles[DateRole] = "date";
    roles[ThumbnailsRole] = "thumbnails";
    return roles;
}

QString ProjectModel::getDefaultProjectsFolderUrl() const
{
    const QString dir =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
        "/KromoStudioProjects";
    QDir().mkpath(dir);
    return QUrl::fromLocalFile(dir).toString();
}

void ProjectModel::refresh(const QString &dirPath)
{
    QString targetPath = dirPath;
    if (targetPath.isEmpty()) {
        targetPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/KromoStudioProjects";
    }

    QDir dir(targetPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    beginResetModel();
    m_projects.clear();

    QFileInfoList entries = dir.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot, QDir::Time);

    for (const QFileInfo &info : entries) {
        if (info.fileName().endsWith(".json") && info.isFile()) continue;

        ProjectEntry entry;
        entry.name = info.fileName();
        entry.path = info.absoluteFilePath();
        entry.date = info.lastModified();
        entry.type = info.isDir() ? "folder" : "drawing";
        entry.preview = "";

        if (info.isDir()) {
            // Check for meta.json
            QFile metaFile(info.absoluteFilePath() + "/meta.json");
            if (metaFile.open(QIODevice::ReadOnly)) {
                QJsonDocument doc = QJsonDocument::fromJson(metaFile.readAll());
                if (doc.isObject()) {
                    QJsonObject obj = doc.object();
                    if (obj.contains("type")) entry.type = obj["type"].toString();
                    if (obj.contains("title")) entry.name = obj["title"].toString();
                }
            }

            // Scan for thumbnails
            QDir subDir(info.absoluteFilePath());
            QStringList filters;
            filters << "*.png" << "*.jpg" << "*.jpeg" << "*.kromo" << "*.kstudio" << "*.aflow" << "*.artflow" << "*.stxf";
            QFileInfoList subFiles = subDir.entryInfoList(filters, QDir::Files, QDir::Time);
            
            for (int i = 0; i < qMin(3, (int)subFiles.size()); ++i) {
                QString path = subFiles[i].absoluteFilePath();
                if (path.endsWith(".kromo") || path.endsWith(".kstudio") || path.endsWith(".aflow") || path.endsWith(".artflow") || path.endsWith(".stxf")) {
                    // Extract preview path (assuming system extractor works as before)
                    QString tempPath = QDir::tempPath() + "/KromoStudioPreviews/" + subFiles[i].fileName() + ".png";
                    entry.thumbnails << "file:///" + tempPath;
                } else {
                    entry.thumbnails << "file:///" + path;
                }
            }
            if (!entry.thumbnails.isEmpty()) entry.preview = entry.thumbnails[0];
        } else {
            // It's a file
            if (info.fileName().endsWith(".kromo") || info.fileName().endsWith(".kstudio") || info.fileName().endsWith(".aflow") || info.fileName().endsWith(".artflow") || info.fileName().endsWith(".stxf")) {
                QString tempPath = QDir::tempPath() + "/KromoStudioPreviews/" + info.fileName() + ".png";
                entry.preview = "file:///" + tempPath;
            } else if (info.fileName().endsWith(".png") || info.fileName().endsWith(".jpg")) {
                entry.preview = "file:///" + info.absoluteFilePath();
            }
        }

        m_projects.append(entry);
    }

    // ── Combinar con proyectos externos recientes (fuera de KromoStudioProjects) ──
    // Solo al refrescar el directorio por defecto: los archivos guardados/abiertos
    // en cualquier otra carpeta del sistema (p.ej. el Escritorio) deben aparecer
    // igualmente en la galería, sin moverlos de su ubicación original.
    const QString defaultDir =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
        "/KromoStudioProjects";
    const bool scanningDefault =
        QDir::cleanPath(QFileInfo(targetPath).absoluteFilePath()) ==
        QDir::cleanPath(QFileInfo(defaultDir).absoluteFilePath());

    if (scanningDefault) {
        QSet<QString> listed;
        for (const ProjectEntry &e : m_projects)
            listed.insert(QFileInfo(e.path).absoluteFilePath().toLower());

        QSettings settings;
        const QStringList recents = settings.value("recentProjects").toStringList();
        for (const QString &rp : recents) {
            QFileInfo info(rp);
            if (!info.exists())
                continue;
            const QString key = info.absoluteFilePath().toLower();
            if (listed.contains(key))
                continue;
            if (!hasProjectExtension(info.fileName()))
                continue;

            ProjectEntry entry;
            entry.name = info.completeBaseName();
            entry.path = info.absoluteFilePath();
            entry.date = info.lastModified();
            entry.type = "drawing";
            const QString tempPath = QDir::tempPath() +
                "/KromoStudioPreviews/" + info.fileName() + ".png";
            entry.preview = "file:///" + tempPath;

            listed.insert(key);
            m_projects.append(entry);
        }

        // Ordenar por fecha (más reciente primero) para una galería coherente.
        std::sort(m_projects.begin(), m_projects.end(),
                  [](const ProjectEntry &a, const ProjectEntry &b) {
                      return a.date > b.date;
                  });
    }

    endResetModel();
}
