import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "power"
    cardWidth: 340
    cardMaxHeight: 600
    alignment: "top-right"

    onOpened: PowerService.refreshProfile()

    function runSessionAction(cmd) {
        PopupState.close()
        Quickshell.execDetached(cmd)
    }

    function logoutSession() {
        PopupState.close()
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.exit()")
        else
            Hyprland.dispatch("exit")
    }

    ColumnLayout {
        width: parent.width
        spacing: 14

        // Resumen de batería
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 74
            radius: 16
            color: PowerService.lowBattery ? ThemeColors.errorContainer : ThemeColors.surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    MaterialIcon {
                        icon: PowerService.batteryIcon
                        size: 24
                        filled: PowerService.charging
                        color: PowerService.lowBattery ? ThemeColors.colorOnErrorContainer : ThemeColors.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: PowerService.hasBattery
                                ? ("Batería · " + PowerService.percentage + "%")
                                : "Energía del sistema"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: PowerService.lowBattery ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurface
                        }

                        Text {
                            text: PowerService.timeRemaining
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: PowerService.lowBattery ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurfaceVariant
                        }
                    }
                }

                // Barra de nivel de batería
                Rectangle {
                    visible: PowerService.hasBattery
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: ThemeColors.surfaceContainerHighest

                    Rectangle {
                        width: parent.width * Math.max(0.02, Math.min(1.0, PowerService.percentage / 100.0))
                        height: parent.height
                        radius: 3
                        color: PowerService.lowBattery ? ThemeColors.error : ThemeColors.primary
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // Selector de perfil de energía (powerprofilesctl)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Perfil de energía"
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurfaceVariant
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { id: "power-saver", label: "Ahorro",      icon: "eco" },
                        { id: "balanced",    label: "Equilibrado", icon: "balance" },
                        { id: "performance", label: "Rendimiento", icon: "bolt" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isCurrent: PowerService.currentProfile === modelData.id
                        readonly property bool isAvailable: modelData.id !== "performance" || PowerService.hasPerformanceProfile

                        visible: isAvailable
                        Layout.fillWidth: true
                        implicitHeight: 54
                        radius: 14
                        color: isCurrent
                            ? ThemeColors.primaryContainer
                            : (profMouse.containsMouse ? ThemeColors.surfaceContainerHigh : ThemeColors.surfaceContainerLow)
                        border.width: 1
                        border.color: isCurrent ? ThemeColors.primary : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 3

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                icon: modelData.icon
                                size: 18
                                filled: isCurrent
                                color: isCurrent ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: isCurrent ? Font.DemiBold : Font.Medium
                                color: isCurrent ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                            }
                        }

                        MouseArea {
                            id: profMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerService.setProfile(modelData.id)
                        }
                    }
                }
            }
        }

        // Mantener encendida (inhibidor de suspensión y apagado de pantalla)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Mantener encendida"
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurfaceVariant
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: caffeineCol.implicitHeight + 20
                radius: 16
                color: CaffeineService.active
                    ? Qt.rgba(ThemeColors.primaryContainer.r, ThemeColors.primaryContainer.g, ThemeColors.primaryContainer.b, 0.45)
                    : ThemeColors.surfaceContainerLow
                border.width: 1
                border.color: CaffeineService.active
                    ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.55)
                    : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                ColumnLayout {
                    id: caffeineCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // Fila superior: ícono + estado en vivo + switch rápido
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialIcon {
                            icon: "coffee"
                            size: 20
                            filled: CaffeineService.active
                            color: CaffeineService.active ? ThemeColors.primary : ThemeColors.colorOnSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: CaffeineService.active ? "Suspensión inhibida" : "Desactivado"
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: ThemeColors.colorOnSurface
                            }

                            Text {
                                text: CaffeineService.active
                                    ? CaffeineService.formattedRemaining
                                    : "Permite apagar pantalla y suspender"
                                font.family: CaffeineService.mode === "timed" ? "JetBrainsMono Nerd Font" : "Inter"
                                font.pixelSize: 11
                                color: CaffeineService.active ? ThemeColors.primary : ThemeColors.colorOnSurfaceVariant
                            }
                        }

                        // Switch estilo Material 3
                        Rectangle {
                            id: caffeineSwitch
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 24
                            radius: 12
                            color: CaffeineService.active ? ThemeColors.primary : ThemeColors.surfaceContainerHighest
                            border.width: 1
                            border.color: CaffeineService.active ? ThemeColors.primary : ThemeColors.outline

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: CaffeineService.active ? parent.width - width - 3 : 3
                                color: CaffeineService.active ? ThemeColors.colorOnPrimary : ThemeColors.outline

                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CaffeineService.toggle()
                            }
                        }
                    }

                    // Fila inferior: píldoras rápidas de duración
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Repeater {
                            model: [
                                { label: "15m", minutes: 15 },
                                { label: "30m", minutes: 30 },
                                { label: "1h",  minutes: 60 },
                                { label: "2h",  minutes: 120 },
                                { label: "∞",   minutes: -1 }
                            ]

                            delegate: Rectangle {
                                id: durPill
                                required property var modelData
                                readonly property bool isSelected: CaffeineService.active && CaffeineService.selectedMinutes === modelData.minutes

                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                radius: 14
                                color: isSelected
                                    ? ThemeColors.primaryContainer
                                    : (durMouse.containsMouse ? ThemeColors.surfaceContainerHighest : ThemeColors.surfaceContainerHigh)
                                border.width: 1
                                border.color: isSelected ? ThemeColors.primary : "transparent"

                                Behavior on color { ColorAnimation { duration: 130 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: durPill.modelData.label
                                    font.family: durPill.modelData.minutes === -1 ? "Inter" : "JetBrainsMono Nerd Font"
                                    font.pixelSize: durPill.modelData.minutes === -1 ? 15 : 11
                                    font.weight: durPill.isSelected ? Font.Bold : Font.Medium
                                    color: durPill.isSelected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                                }

                                MouseArea {
                                    id: durMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (durPill.modelData.minutes === -1)
                                            CaffeineService.enableIndefinite()
                                        else
                                            CaffeineService.enableForMinutes(durPill.modelData.minutes)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Acciones de sesión
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Sesión"
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurfaceVariant
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: [
                        { id: "lock",      label: "Bloquear",      icon: "lock",              danger: false },
                        { id: "suspend",   label: "Suspender",     icon: "bedtime",           danger: false },
                        { id: "logout",    label: "Cerrar sesión", icon: "logout",            danger: false },
                        { id: "reboot",    label: "Reiniciar",     icon: "restart_alt",       danger: false },
                        { id: "poweroff",  label: "Apagar",        icon: "power_settings_new", danger: true }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.columnSpan: modelData.id === "poweroff" ? 2 : 1
                        implicitHeight: 42
                        radius: 13

                        color: modelData.danger
                            ? (actMouse.containsMouse ? Qt.lighter(ThemeColors.errorContainer, 1.1) : ThemeColors.errorContainer)
                            : (actMouse.containsMouse ? ThemeColors.surfaceContainerHighest : ThemeColors.surfaceContainerLow)

                        Behavior on color { ColorAnimation { duration: 140 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            MaterialIcon {
                                icon: modelData.icon
                                size: 17
                                color: modelData.danger ? ThemeColors.colorOnErrorContainer : ThemeColors.primary
                            }

                            Text {
                                text: modelData.label
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: modelData.danger ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurface
                            }
                        }

                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.id === "lock")
                                    root.runSessionAction(["hyprlock"])
                                else if (modelData.id === "suspend")
                                    root.runSessionAction(["systemctl", "suspend"])
                                else if (modelData.id === "logout")
                                    root.logoutSession()
                                else if (modelData.id === "reboot")
                                    root.runSessionAction(["systemctl", "reboot"])
                                else if (modelData.id === "poweroff")
                                    root.runSessionAction(["systemctl", "poweroff"])
                            }
                        }
                    }
                }
            }
        }
    }
}
