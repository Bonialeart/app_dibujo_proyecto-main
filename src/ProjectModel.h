#ifndef PROJECTMODEL_H
#define PROJECTMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <QString>
#include <QDateTime>
#include <QVariantList>

// Escaneo central de proyectos para la pantalla de inicio/galería. Combina los
// proyectos de Documentos/KromoStudioProjects con los proyectos/carpetas
// recientes ubicados FUERA de esa carpeta (registrados en QSettings). No depende
// de ninguna instancia de canvas, por lo que funciona aunque no haya proyecto
// abierto. Devuelve una lista de mapas con: name, path, type, date, preview
// (data URL base64), thumbnails.
QVariantList scanKromoProjects();

// Registra un proyecto/carpeta reciente (QSettings) para que aparezca en Inicio
// aunque esté fuera de KromoStudioProjects. Acepta archivos y directorios.
void recordRecentProject(const QString &path);

// Fusiona dos elementos (proyectos o carpeta de grupo) según el caso, moviendo
// directorios de forma segura. Devuelve true si la operación tuvo éxito.
// No emite señales: el llamador debe refrescar la vista.
bool mergeKromoProjects(const QString &sourcePath, const QString &targetPath);

struct ProjectEntry {
    QString name;
    QString path;
    QString preview;
    QString type; // "drawing" or "folder"
    QDateTime date;
    QStringList thumbnails;
};

class ProjectModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ProjectRoles {
        NameRole = Qt::UserRole + 1,
        PathRole,
        PreviewRole,
        TypeRole,
        DateRole,
        ThumbnailsRole
    };

    explicit ProjectModel(QObject *parent = nullptr);

    // Métodos obligatorios de QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Acción para escanear archivos
    Q_INVOKABLE void refresh(const QString &dirPath);

    // Devuelve la lista de proyectos para Inicio/Galería (siempre disponible,
    // sin necesidad de un canvas activo). Misma forma que CanvasItem::get_project_list.
    Q_INVOKABLE QVariantList getProjectsList() const { return scanKromoProjects(); }

    // Fusión drag&drop disponible sin canvas activo (Inicio/Galería).
    Q_INVOKABLE bool create_folder_from_merge(const QString &sourcePath,
                                              const QString &targetPath) {
        return mergeKromoProjects(sourcePath, targetPath);
    }

    // Carpeta de biblioteca por defecto (Documentos/KromoStudioProjects) como URL file:///.
    Q_INVOKABLE QString getDefaultProjectsFolderUrl() const;

private:
    QVector<ProjectEntry> m_projects;
};

#endif // PROJECTMODEL_H
