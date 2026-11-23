pragma Singleton

import QtQuick

QtObject {
    id: root

    // Identificador del popup abierto: "" | "launcher" | "keybinds" | "traymenu" | "media" | "notifications" | "network" | "audio" | "power" | "wallpaper" | "calendar" | "stats"
    property string activePopup: ""

    // Estado compartido del menú contextual del System Tray
    property var trayMenuHandle: null
    property string trayMenuTitle: ""
    property int trayMenuRightOffset: 12

    function toggle(name) {
        activePopup = (activePopup === name) ? "" : name
    }

    function open(name) {
        activePopup = name
    }

    function openTrayMenu(handle, title, rightOffset) {
        if (!handle)
            return
        if (activePopup === "traymenu" && trayMenuHandle === handle) {
            activePopup = ""
            return
        }
        trayMenuHandle = handle
        trayMenuTitle = title || "Menú"
        trayMenuRightOffset = Math.max(12, Math.round(rightOffset))
        activePopup = "traymenu"
    }

    function close() {
        activePopup = ""
    }
}
