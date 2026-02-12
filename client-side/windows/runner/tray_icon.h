#ifndef RUNNER_TRAY_ICON_H_
#define RUNNER_TRAY_ICON_H_

#include <windows.h>

namespace tray {

    void Create(HWND hwnd, HINSTANCE instance);

    void Destroy();

    void Show();

    void Hide();

    bool IsVisible();

    UINT GetTrayMessageId();

}  // namespace tray

#endif  // RUNNER_TRAY_ICON_H_
