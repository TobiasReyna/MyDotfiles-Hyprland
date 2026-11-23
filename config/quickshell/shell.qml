// =============================================================================
// Quickshell 0.3+ — Punto de entrada principal (Material Design 3 / Caelestia)
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import "bar"
import "popups"
import "osd"
import "services"

ShellRoot {
    id: root

    // Barra superior en cada monitor conectado
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Popups interactivos (cierre con Escape o clic fuera)
    LauncherPopup {}
    KeybindsPopup {}
    TrayMenuPopup {}
    MediaPopup {}
    NotificationCenterPopup {}
    NetworkBluetoothPopup {}
    AudioPopup {}
    PowerPopup {}
    WallpaperPopup {}
    CalendarPopup {}
    SysStatsPopup {}

    // OSD flotante (volumen/brillo) y toasts de notificaciones
    Osd {
        id: osdOverlay
    }
    NotificationPopups {}

    // =========================================================================
    // Manejadores IPC (`qs ipc call <target> <funcion>`)
    // =========================================================================
    IpcHandler {
        target: "launcher"
        function toggle(): void { PopupState.toggle("launcher") }
        function open(): void { PopupState.open("launcher") }
        function close(): void { PopupState.close() }
    }

    IpcHandler {
        target: "keybinds"
        function toggle(): void { PopupState.toggle("keybinds") }
        function open(): void { PopupState.open("keybinds") }
        function close(): void { PopupState.close() }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { PopupState.toggle("wallpaper") }
        function open(): void { PopupState.open("wallpaper") }
        function close(): void { PopupState.close() }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { PopupState.toggle("power") }
    }

    IpcHandler {
        target: "caffeine"
        function toggle(): void { CaffeineService.toggle() }
        function enableIndefinite(): void { CaffeineService.enableIndefinite() }
        function enableMinutes(minutes: int): void { CaffeineService.enableForMinutes(minutes) }
        function disable(): void { CaffeineService.disable() }
    }

    IpcHandler {
        target: "network"
        function toggle(): void { PopupState.toggle("network") }
    }

    IpcHandler {
        target: "audio"
        function toggle(): void { PopupState.toggle("audio") }
    }

    IpcHandler {
        target: "media"
        function toggle(): void { PopupState.toggle("media") }
        function open(): void { PopupState.open("media") }
        function close(): void { PopupState.close() }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { PopupState.toggle("notifications") }
        function toggleDnd(): void { NotificationService.toggleDnd() }
        function clearAll(): void { NotificationService.clearAll() }
    }

    IpcHandler {
        target: "osd"
        function showVolume(): void { osdOverlay.triggerVolume() }
        function showBrightness(): void { osdOverlay.triggerBrightness() }
    }

    IpcHandler {
        target: "shell"
        function closeAll(): void { PopupState.close() }
    }
}
