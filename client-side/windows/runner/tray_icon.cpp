#include "tray_icon.h"

#include <shellapi.h>

namespace tray {

    namespace {

        constexpr UINT
        WM_TRAYICON = WM_USER + 1;

        NOTIFYICONDATAW nid = {};
        bool visible = false;

    }  // namespace

    void Create(HWND hwnd, HINSTANCE instance) {
        nid.cbSize = sizeof(nid);
        nid.hWnd = hwnd;
        nid.uID = 1;
        nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
        nid.uCallbackMessage = WM_TRAYICON;
        nid.hIcon = LoadIcon(instance, MAKEINTRESOURCE(101));
        wcscpy_s(nid.szTip, L"Legion");
    }

    void Destroy() {
        if (visible) {
            Shell_NotifyIconW(NIM_DELETE, &nid);
            visible = false;
        }
    }

    void Show() {
        if (!visible) {
            Shell_NotifyIconW(NIM_ADD, &nid);
            visible = true;
        }
    }

    void Hide() {
        if (visible) {
            Shell_NotifyIconW(NIM_DELETE, &nid);
            visible = false;
        }
    }

    bool IsVisible() { return visible; }

    UINT GetTrayMessageId() { return WM_TRAYICON; }

}  // namespace tray
