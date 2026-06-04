#include "WintabManager.h"
#include <QDebug>
#include <QGuiApplication>
#include <QWindow>
#include <QScreen>
#include <QDateTime>

// Estructura AXIS de Wintab para obtener los rangos
typedef struct tagAXIS {
    LONG axMin;
    LONG axMax;
    UINT axUnits;
    LONG axResolution;
} AXIS;

#define WTI_DEVICES 100
#define DVC_NPRESSURE 15
#define DVC_ORIENTATION 17
#define DVC_X 12
#define DVC_Y 13

WintabManager* WintabManager::instance() {
    static WintabManager inst;
    return &inst;
}

WintabManager::WintabManager(QObject* parent) : QObject(parent), m_wintabLib(nullptr), m_hCtx(nullptr), m_maxPressure(1024), m_sysWidth(1920), m_sysHeight(1080) {
}

WintabManager::~WintabManager() {
    cleanup();
}

bool WintabManager::init(HWND hwnd) {
    qDebug() << "WintabManager::init called with HWND:" << hwnd;
    if (m_wintabLib) return true; // Ya inicializado

    m_wintabLib = LoadLibraryA("wintab32.dll");
    if (!m_wintabLib) {
        qDebug() << "Wintab: wintab32.dll no encontrado en el sistema. Windows Ink será la única opción.";
        return false;
    }

    m_ptrWTInfoA = (WTINFOA)GetProcAddress(m_wintabLib, "WTInfoA");
    m_ptrWTOpenA = (WTOPENA)GetProcAddress(m_wintabLib, "WTOpenA");
    m_ptrWTClose = (WTCLOSE)GetProcAddress(m_wintabLib, "WTClose");
    m_ptrWTPacket = (WTPACKET)GetProcAddress(m_wintabLib, "WTPacket");

    if (!m_ptrWTInfoA || !m_ptrWTOpenA || !m_ptrWTPacket) {
        qDebug() << "Wintab: Funciones requeridas no encontradas en wintab32.dll";
        cleanup();
        return false;
    }

    // Verificar si el driver de Wintab está activo y obtener versión
    if (m_ptrWTInfoA(0, 0, nullptr) == 0) {
        qDebug() << "Wintab: Driver de tableta no está enviando respuesta activa.";
        cleanup();
        return false;
    }

    // Obtener rangos de presión
    AXIS pressureAxis = { 0, 0, 0, 0 };
    if (m_ptrWTInfoA(WTI_DEVICES, DVC_NPRESSURE, &pressureAxis)) {
        m_maxPressure = pressureAxis.axMax;
    } else {
        m_maxPressure = 1024; // fallback standard
    }
    if (m_maxPressure <= 0) {
        m_maxPressure = 1024;
    }
    
    // Obtener dimensiones de tableta física (resolución nativa Wintab)
    AXIS xAxis = { 0, 0, 0, 0 };
    AXIS yAxis = { 0, 0, 0, 0 };
    if (m_ptrWTInfoA(WTI_DEVICES, DVC_X, &xAxis)) {
        m_tabletExtX = xAxis.axMax;
    } else {
        m_tabletExtX = 1;
    }
    if (m_ptrWTInfoA(WTI_DEVICES, DVC_Y, &yAxis)) {
        m_tabletExtY = yAxis.axMax;
    } else {
        m_tabletExtY = 1;
    }

    // Obtener dimensiones del sistema / pantalla (usamos Qt para esto)
    if (QGuiApplication::primaryScreen()) {
        m_sysWidth = QGuiApplication::primaryScreen()->size().width();
        m_sysHeight = QGuiApplication::primaryScreen()->size().height();
    }

    // Configurar contexto de lectura
    LOGCONTEXTA lc;
    if (!m_ptrWTInfoA(WTI_DEFSYSCTX, 0, &lc)) {
        qDebug() << "Wintab: Fallo al obtener el Default System Context.";
        cleanup();
        return false;
    }

    lc.lcOptions |= 2; // CXO_MESSAGES - queremos que nos envíen mensajes de windows (WM_PACKET)
    lc.lcPktData = PK_BUTTONS | PK_X | PK_Y | PK_NORMAL_PRESSURE | PK_ORIENTATION;
    lc.lcPktMode = 0; // Absolute mode

    m_hCtx = m_ptrWTOpenA(hwnd, &lc, TRUE);
    if (!m_hCtx) {
        qDebug() << "Wintab: No se pudo abrir el contexto de tableta para la ventana proveída.";
        cleanup();
        return false;
    }

    qDebug() << "Wintab: Inicializado correctamente. Max Presión:" << m_maxPressure;
    
    // Instalar filtro de eventos nativos para escuchar a Windows
    QCoreApplication::instance()->installNativeEventFilter(this);

    return true;
}

void WintabManager::cleanup() {
    if (m_hCtx && m_ptrWTClose) {
        m_ptrWTClose(m_hCtx);
        m_hCtx = nullptr;
    }
    if (m_wintabLib) {
        FreeLibrary(m_wintabLib);
        m_wintabLib = nullptr;
    }
}

bool WintabManager::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) {
    if (eventType != "windows_generic_MSG") return false;
    
    MSG* msg = static_cast<MSG*>(message);
    if (!m_hCtx || !m_ptrWTPacket) return false;

    if (msg->message == WT_PACKET) {
        MY_WINTAB_PACKET pkt;
        // WTPacket retorna no-zero si es exitoso
        if (m_ptrWTPacket((HANDLE)msg->lParam, msg->wParam, &pkt)) {
            // Mapeamos los datos raw a valores manejables:
            
            // X e Y están en resolución de tableta o en resolución de pantalla dependiendo de la configuración.
            // Para el modo absoluto del sistema que usamos (WTI_DEFSYSCTX), generalmente X e Y 
            // ya coinciden bastante bien con las coordenadas de pantalla, pero las normalizamos a Qt.
            // Nota: En pantallas HDPI, Qt usa coordenadas lógicas, Wintab puede dar píxeles reales.
            // Wintab envía las posiciones relativas a la pantalla entera:
            
            // Si el driver está en Absolute Mode, X e Y suelen mapear a la resolución total del Desktop.
            // Si esto falla o está desfasado, dependeremos del evento del mouse de Qt para XY 
            // y del evento de Wintab *sólo* para la presión/inclinación, que es el patrón clásico:
            
            float pressure = (float)pkt.pkNormalPressure / (float)m_maxPressure;
            if (pressure < 0.0f) pressure = 0.0f;
            if (pressure > 1.0f) pressure = 1.0f;

            static qint64 lastLogTime = 0;
            qint64 now = QDateTime::currentMSecsSinceEpoch();
            if (pressure > 0.0f && now - lastLogTime > 200) {
                qDebug() << "[Wintab Info] Raw Pressure:" << pkt.pkNormalPressure
                         << "Max:" << m_maxPressure
                         << "Normalized:" << pressure;
                lastLogTime = now;
            }

            // Inclinación (tilt)
            // orAzimuth: 0 a 3600 (0.1 grados)
            // orAltitude: 0 a 900 (0.1 grados)
            float tiltX = 0.0f;
            float tiltY = 0.0f;
            
            // Conversión de Acimut/Altitud a TiltX/TiltY (-60 a 60 grados aprox)
            // Esta matemática simplificada:
            float az = pkt.pkOrientation.orAzimuth / 10.0f;
            float alt = pkt.pkOrientation.orAltitude / 10.0f;
            float azRad = az * 3.14159265f / 180.0f;
            
            // Inclinación radial (90 - altitud)
            float radialTilt = 90.0f - alt; 
            tiltX = sin(azRad) * radialTilt; // Grados X
            tiltY = cos(azRad) * radialTilt; // Grados Y

            // Notificar a Qt
            emit wintabEvent((float)pkt.pkX, (float)pkt.pkY, pressure, tiltX, tiltY);
        }
        return false; // Permitimos que Qt continúe su proceso por si acaso (ej: mover el cursor nativo)
    }

    return false;
}
