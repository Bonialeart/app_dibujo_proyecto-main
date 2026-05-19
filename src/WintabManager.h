#pragma once

#include <QObject>
#include <QAbstractNativeEventFilter>
#include <windows.h>

// --- Definiciones básicas de WinTab ---
#define WT_DEFBASE 0x7FF0
#define WT_PACKET (WT_DEFBASE + 0)
#define WT_CTXOPEN (WT_DEFBASE + 1)
#define WT_CTXCLOSE (WT_DEFBASE + 2)
#define WT_CTXUPDATE (WT_DEFBASE + 3)

#define WTI_INTERFACE 1
#define WTI_DEFSYSCTX 4
#define WTI_DEFCONTEXT 3

#define CX_SYSMX 16
#define CX_SYSMY 17

#define PK_BUTTONS 0x0040
#define PK_X 0x0080
#define PK_Y 0x0100
#define PK_NORMAL_PRESSURE 0x0400
#define PK_ORIENTATION 0x1000

typedef struct tagORIENTATION {
    int orAzimuth;
    int orAltitude;
    int orTwist;
} WINTAB_ORIENTATION;

typedef struct tagLOGCONTEXTA {
    char lcName[40];
    UINT lcOptions;
    UINT lcStatus;
    UINT lcLocks;
    UINT lcMsgBase;
    UINT lcDevice;
    UINT lcPktRate;
    DWORD lcPktData;
    DWORD lcPktMode;
    DWORD lcMoveMask;
    DWORD lcBtnDnMask;
    DWORD lcBtnUpMask;
    LONG lcInOrgX;
    LONG lcInOrgY;
    LONG lcInOrgZ;
    LONG lcInExtX;
    LONG lcInExtY;
    LONG lcInExtZ;
    LONG lcOutOrgX;
    LONG lcOutOrgY;
    LONG lcOutOrgZ;
    LONG lcOutExtX;
    LONG lcOutExtY;
    LONG lcOutExtZ;
    LONG lcSensX;
    LONG lcSensY;
    LONG lcSensZ;
    BOOL lcSysMode;
    int lcSysOrgX;
    int lcSysOrgY;
    int lcSysExtX;
    int lcSysExtY;
    LONG lcSysSensX;
    LONG lcSysSensY;
} LOGCONTEXTA;

// Estructura que pediremos a Wintab
typedef struct {
    DWORD pkButtons;
    LONG pkX;
    LONG pkY;
    UINT pkNormalPressure;
    WINTAB_ORIENTATION pkOrientation;
} MY_WINTAB_PACKET;

// Typedefs de las funciones de wintab32.dll
typedef UINT (WINAPI *WTINFOA)(UINT, UINT, LPVOID);
typedef HANDLE (WINAPI *WTOPENA)(HWND, LOGCONTEXTA *, BOOL);
typedef BOOL (WINAPI *WTCLOSE)(HANDLE);
typedef BOOL (WINAPI *WTPACKET)(HANDLE, UINT, LPVOID);

class WintabManager : public QObject, public QAbstractNativeEventFilter {
    Q_OBJECT
public:
    static WintabManager* instance();
    bool init(HWND hwnd);
    void cleanup();

    virtual bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;

signals:
    void wintabEvent(float x, float y, float pressure, float tiltX, float tiltY);

private:
    WintabManager(QObject* parent = nullptr);
    ~WintabManager();

    HMODULE m_wintabLib;
    HANDLE m_hCtx;

    WTINFOA m_ptrWTInfoA;
    WTOPENA m_ptrWTOpenA;
    WTCLOSE m_ptrWTClose;
    WTPACKET m_ptrWTPacket;

    int m_maxPressure;
    int m_sysWidth;
    int m_sysHeight;
    int m_tabletExtX;
    int m_tabletExtY;
};
