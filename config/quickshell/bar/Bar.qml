import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Widgets
import ".."
import "../components"
import "../services"

PanelWindow {
    id: barWindow

    implicitHeight: 40
    color: "transparent"

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top

    // Inhibidor nativo Wayland (zwp_idle_inhibit_manager_v1) para hypridle
    IdleInhibitor {
        enabled: CaffeineService.active
        window: barWindow
    }

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 6
        left: 10
        right: 10
        bottom: 0
    }

    // Reloj reactivo en español
    property string clockText: ""
    readonly property var _daysEs: ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"]
    readonly property var _monthsEs: ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]

    function _updateClock() {
        const now = new Date()
        const hh = String(now.getHours()).padStart(2, "0")
        const mm = String(now.getMinutes()).padStart(2, "0")
        clockText = hh + ":" + mm + " · " + _daysEs[now.getDay()] + " " + now.getDate() + " " + _monthsEs[now.getMonth()]
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: barWindow._updateClock()
    }

    function dispatchWorkspace(wsId) {
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })")
        else
            Hyprland.dispatch("workspace " + wsId)
    }

    function dispatchRelativeWorkspace(step) {
        const target = step > 0 ? "e+1" : "e-1"
        if (Hyprland.usingLua)
            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + target + '" })')
        else
            Hyprland.dispatch("workspace " + target)
    }

    function workspaceHasWindows(wsId) {
        const list = Hyprland.workspaces ? Hyprland.workspaces.values : []
        for (let i = 0; i < list.length; i++) {
            const ws = list[i]
            if (ws && ws.id === wsId)
                return true
        }
        return false
    }

    readonly property int focusedWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // Reproductor MPRIS activo (prioriza uno reproduciendo)
    readonly property var activePlayer: {
        const players = Mpris.players ? Mpris.players.values : []
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].playbackState === MprisPlaybackState.Playing)
                return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    // Ítems del SystemTray excluyendo explícitamente nm-applet / NetworkManager
    readonly property var filteredTrayItems: {
        const items = SystemTray.items ? SystemTray.items.values : []
        const result = []
        for (let i = 0; i < items.length; i++) {
            const item = items[i]
            if (!item)
                continue
            const haystack = (
                (item.id || "") + " " +
                (item.title || "") + " " +
                (item.tooltipTitle || "")
            ).toLowerCase()
            if (haystack.indexOf("nm-applet") !== -1 || haystack.indexOf("networkmanager") !== -1)
                continue
            result.push(item)
        }
        return result
    }

    // Superficie principal estilo Caelestia con transparencia para el blur de Hyprland
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(
            ThemeColors.surfaceContainer.r,
            ThemeColors.surfaceContainer.g,
            ThemeColors.surfaceContainer.b,
            0.84
        )
        border.width: 1
        border.color: Qt.rgba(
            ThemeColors.outlineVariant.r,
            ThemeColors.outlineVariant.g,
            ThemeColors.outlineVariant.b,
            0.55
        )

        // =====================================================================
        // IZQUIERDA: Logo Arch Linux (Lanzador) + Workspaces + ventana activa
        // =====================================================================
        RowLayout {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Botón con logo de Arch Linux -> abre/cierra el lanzador de aplicaciones
            Rectangle {
                id: archButton
                readonly property bool isOpen: PopupState.activePopup === "launcher"
                implicitWidth: 32
                implicitHeight: 28
                radius: 14
                color: isOpen
                    ? ThemeColors.primaryContainer
                    : (archMouse.pressed ? ThemeColors.surfaceContainerHighest
                    : (archMouse.containsMouse ? ThemeColors.surfaceContainerHigh
                    : Qt.rgba(ThemeColors.surfaceContainerLowest.r, ThemeColors.surfaceContainerLowest.g, ThemeColors.surfaceContainerLowest.b, 0.55)))
                border.width: 1
                border.color: isOpen
                    ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.65)
                    : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.4)

                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Text {
                    anchors.fill: parent
                    text: ""
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.QtRendering
                    color: archButton.isOpen ? ThemeColors.colorOnPrimaryContainer : ThemeColors.primary
                }

                MouseArea {
                    id: archMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PopupState.toggle("launcher")
                }
            }

            // Píldora de Workspaces interactivos (clic y rueda)
            Rectangle {
                id: wsContainer
                implicitHeight: 28
                implicitWidth: wsRow.implicitWidth + 14
                radius: 14
                color: Qt.rgba(
                    ThemeColors.surfaceContainerLowest.r,
                    ThemeColors.surfaceContainerLowest.g,
                    ThemeColors.surfaceContainerLowest.b,
                    0.55
                )

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: function(wheel) {
                        barWindow.dispatchRelativeWorkspace(wheel.angleDelta.y > 0 ? -1 : 1)
                    }
                }

                RowLayout {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: 9

                        delegate: Rectangle {
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool isActive: barWindow.focusedWsId === wsId
                            readonly property bool isOccupied: barWindow.workspaceHasWindows(wsId)

                            visible: wsId <= 5 || isActive || isOccupied
                            implicitWidth: isActive ? 24 : (isOccupied ? 16 : 8)
                            implicitHeight: isActive ? 14 : (isOccupied ? 10 : 8)
                            radius: height / 2

                            color: isActive ? ThemeColors.primary
                                 : isOccupied ? ThemeColors.secondary
                                 : Qt.rgba(ThemeColors.outline.r, ThemeColors.outline.g, ThemeColors.outline.b, 0.45)

                            Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 160 } }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: barWindow.dispatchWorkspace(parent.wsId)
                            }
                        }
                    }
                }
            }

            // Título truncado de la ventana activa
            Text {
                visible: text !== ""
                Layout.maximumWidth: 260
                text: (Hyprland.activeToplevel && Hyprland.activeToplevel.title) ? Hyprland.activeToplevel.title : ""
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: ThemeColors.colorOnSurfaceVariant
                elide: Text.ElideRight
            }
        }

        // =====================================================================
        // CENTRO: Reloj/fecha en español + mini indicador MPRIS
        // =====================================================================
        RowLayout {
            id: centerSection
            anchors.centerIn: parent
            spacing: 8

            PillButton {
                icon: "calendar_today"
                iconSize: 15
                label: barWindow.clockText
                active: PopupState.activePopup === "calendar"
                onClicked: PopupState.toggle("calendar")
            }

            // Mini indicador multimedia (MPRIS) -> clic izquierdo abre MediaPopup, clic derecho pausa/reproduce
            PillButton {
                visible: barWindow.activePlayer !== null && (barWindow.activePlayer.trackTitle || "") !== ""
                icon: (barWindow.activePlayer && barWindow.activePlayer.playbackState === MprisPlaybackState.Playing)
                    ? "graphic_eq" : "music_note"
                iconFilled: true
                iconSize: 16
                active: PopupState.activePopup === "media"
                     || (barWindow.activePlayer !== null && barWindow.activePlayer.playbackState === MprisPlaybackState.Playing)
                label: {
                    if (!barWindow.activePlayer)
                        return ""
                    const t = barWindow.activePlayer.trackTitle || ""
                    return t.length > 24 ? t.slice(0, 23) + "…" : t
                }
                onClicked: PopupState.toggle("media")
                onRightClicked: {
                    if (barWindow.activePlayer)
                        barWindow.activePlayer.togglePlaying()
                }
            }
        }

        // =====================================================================
        // DERECHA: SysStats + SystemTray + Grupo de Control (Red/BT, Audio, Energía)
        // =====================================================================
        RowLayout {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // 1. Estadísticas del sistema (CPU %, RAM %, Temp °C)
            Rectangle {
                id: statsPill
                implicitHeight: 28
                implicitWidth: statsRow.implicitWidth + 18
                radius: 14
                color: SysStats.anyAlert
                    ? ThemeColors.errorContainer
                    : (PopupState.activePopup === "stats" ? ThemeColors.primaryContainer
                    : (statsMouse.containsMouse ? ThemeColors.surfaceContainerHigh
                    : Qt.rgba(ThemeColors.surfaceContainerLowest.r, ThemeColors.surfaceContainerLowest.g, ThemeColors.surfaceContainerLowest.b, 0.55)))
                border.width: 1
                border.color: SysStats.anyAlert
                    ? ThemeColors.error
                    : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.4)

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: statsRow
                    anchors.centerIn: parent
                    spacing: 9

                    // CPU
                    RowLayout {
                        spacing: 3
                        MaterialIcon {
                            icon: "memory"
                            size: 15
                            color: SysStats.cpuHigh ? ThemeColors.error : ThemeColors.primary
                        }
                        Text {
                            text: SysStats.cpuUsage + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: SysStats.cpuHigh ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurface
                        }
                    }

                    // RAM
                    RowLayout {
                        spacing: 3
                        MaterialIcon {
                            icon: "straighten"
                            size: 15
                            color: SysStats.ramHigh ? ThemeColors.error : ThemeColors.secondary
                        }
                        Text {
                            text: SysStats.ramPercent + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: SysStats.ramHigh ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurface
                        }
                    }

                    // Temperatura CPU
                    RowLayout {
                        visible: SysStats.cpuTemp > 0
                        spacing: 2
                        MaterialIcon {
                            icon: "device_thermostat"
                            size: 15
                            color: SysStats.tempHigh ? ThemeColors.error : ThemeColors.tertiary
                        }
                        Text {
                            text: SysStats.cpuTemp + "°"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: SysStats.tempHigh ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurface
                        }
                    }
                }

                MouseArea {
                    id: statsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PopupState.toggle("stats")
                }
            }

            // 2. System Tray (Steam, Discord, Spotify, etc. — excluye nm-applet)
            Rectangle {
                visible: barWindow.filteredTrayItems.length > 0
                implicitHeight: 28
                implicitWidth: trayRow.implicitWidth + 14
                radius: 14
                color: Qt.rgba(
                    ThemeColors.surfaceContainerLowest.r,
                    ThemeColors.surfaceContainerLowest.g,
                    ThemeColors.surfaceContainerLowest.b,
                    0.55
                )

                RowLayout {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: barWindow.filteredTrayItems

                        delegate: Rectangle {
                            id: trayDelegate
                            required property var modelData
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: trayMouse.containsMouse
                                ? ThemeColors.surfaceContainerHigh
                                : "transparent"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            IconImage {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                source: trayDelegate.modelData.icon || ""
                                asynchronous: true
                            }

                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    const item = trayDelegate.modelData
                                    const pos = trayDelegate.mapToItem(null, 0, 0)
                                    const rightOff = Math.max(12, Math.min(barWindow.width - 282, barWindow.width - pos.x - trayDelegate.width))
                                    const label = item.title || item.tooltipTitle || item.id || "Menú"

                                    if (mouse.button === Qt.RightButton) {
                                        if (item.hasMenu && item.menu)
                                            PopupState.openTrayMenu(item.menu, label, rightOff)
                                    } else if (mouse.button === Qt.LeftButton) {
                                        if (item.onlyMenu && item.hasMenu && item.menu)
                                            PopupState.openTrayMenu(item.menu, label, rightOff)
                                        else
                                            item.activate()
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        item.secondaryActivate()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. Grupo de control (Accesibilidad tipo Caelestia)
            // Red + Bluetooth
            PillButton {
                icon: NetworkService.barIcon
                label: BluetoothService.powered && BluetoothService.connectedCount > 0 ? String(BluetoothService.connectedCount) : ""
                active: PopupState.activePopup === "network"
                onClicked: PopupState.toggle("network")
            }

            // Audio / Volumen
            PillButton {
                icon: AudioService.volumeIcon
                label: AudioService.muted ? "Mute" : (AudioService.volumePercent + "%")
                active: PopupState.activePopup === "audio"
                onClicked: PopupState.toggle("audio")
                onRightClicked: AudioService.toggleMute()
                onWheelScrolled: function(delta) {
                    AudioService.setVolume(AudioService.volume + (delta > 0 ? 0.05 : -0.05))
                }
            }

            // Notificaciones (entre Sonido y Energía; clic derecho alterna DND)
            Rectangle {
                id: notifBellBtn
                readonly property bool isOpen: PopupState.activePopup === "notifications"
                Layout.preferredWidth: 32
                Layout.preferredHeight: 28
                radius: 14
                color: isOpen
                    ? ThemeColors.primaryContainer
                    : (notifMouse.pressed ? ThemeColors.surfaceContainerHighest
                    : (notifMouse.containsMouse ? ThemeColors.surfaceContainerHigh
                    : Qt.rgba(ThemeColors.surfaceContainer.r, ThemeColors.surfaceContainer.g, ThemeColors.surfaceContainer.b, 0.78)))
                border.width: 1
                border.color: isOpen
                    ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.65)
                    : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.45)

                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                MaterialIcon {
                    anchors.fill: parent
                    icon: NotificationService.dnd ? "notifications_off" : "notifications"
                    size: 18
                    filled: notifBellBtn.isOpen || NotificationService.unreadCount > 0
                    renderType: Text.QtRendering
                    color: notifBellBtn.isOpen
                        ? ThemeColors.colorOnPrimaryContainer
                        : (NotificationService.dnd ? ThemeColors.colorOnSurfaceVariant : ThemeColors.colorOnSurface)
                }

                // Badge/punto discreto cuando hay notificaciones en el historial
                Rectangle {
                    visible: NotificationService.unreadCount > 0
                    width: 6
                    height: 6
                    radius: 3
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 3
                    anchors.rightMargin: 4
                    color: NotificationService.hasCritical ? ThemeColors.error : ThemeColors.primary
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton)
                            NotificationService.toggleDnd()
                        else
                            PopupState.toggle("notifications")
                    }
                }
            }

            // Indicador discreto de modo "Mantener encendida" (Caffeine)
            PillButton {
                visible: CaffeineService.active
                icon: "coffee"
                iconSize: 15
                iconFilled: true
                label: CaffeineService.mode === "timed" ? CaffeineService.formattedRemaining : ""
                active: true
                onClicked: PopupState.toggle("power")
                onRightClicked: CaffeineService.disable()
            }

            // Energía / Batería
            PillButton {
                icon: PowerService.batteryIcon
                label: PowerService.hasBattery ? (PowerService.percentage + "%") : ""
                active: PopupState.activePopup === "power"
                alert: PowerService.lowBattery
                onClicked: PopupState.toggle("power")
            }
        }
    }
}
