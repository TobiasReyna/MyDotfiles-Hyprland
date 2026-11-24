import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "stats"
    cardWidth: 368
    cardMaxHeight: 680
    alignment: "top-right"

    property bool cpuExpanded: false

    // Activa el monitoreo detallado (núcleos, GPU/VRAM, disco) solo mientras el popup está abierto
    Binding {
        target: SysStats
        property: "detailedActive"
        value: root.isOpen
    }

    onPopupClosed: cpuExpanded = false

    ColumnLayout {
        width: parent.width
        spacing: 10

        // Cabecera
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialIcon {
                icon: "monitoring"
                size: 18
                color: ThemeColors.primary
            }

            Text {
                Layout.fillWidth: true
                text: "Monitor del sistema"
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurface
            }

            Text {
                visible: SysStats.coreUsages.length > 0
                text: SysStats.coreUsages.length + " hilos"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: ThemeColors.colorOnSurfaceVariant
            }
        }

        // =====================================================================
        // 1. Procesador (CPU) — Tarjeta expandible con grilla de núcleos/hilos
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cpuCardCol.implicitHeight + 20
            radius: 14
            color: (SysStats.cpuHigh || SysStats.tempHigh)
                ? Qt.rgba(ThemeColors.errorContainer.r, ThemeColors.errorContainer.g, ThemeColors.errorContainer.b, 0.55)
                : ThemeColors.surfaceContainerLow
            border.width: 1
            border.color: (SysStats.cpuHigh || SysStats.tempHigh)
                ? ThemeColors.error
                : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.35)

            Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: cpuCardCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Encabezado clickeable para expandir/colapsar núcleos
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: cpuHeaderCol.implicitHeight

                    ColumnLayout {
                        id: cpuHeaderCol
                        anchors.fill: parent
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            MaterialIcon {
                                icon: "memory"
                                size: 16
                                color: SysStats.cpuHigh ? ThemeColors.error : ThemeColors.primary
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Procesador (CPU)"
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: ThemeColors.colorOnSurface
                            }

                            // Badge de temperatura CPU
                            Rectangle {
                                visible: SysStats.cpuTemp > 0
                                implicitHeight: 20
                                implicitWidth: cpuTempRow.implicitWidth + 10
                                radius: 10
                                color: SysStats.tempHigh ? ThemeColors.errorContainer : ThemeColors.surfaceContainerHigh

                                RowLayout {
                                    id: cpuTempRow
                                    anchors.centerIn: parent
                                    spacing: 2

                                    MaterialIcon {
                                        icon: "device_thermostat"
                                        size: 12
                                        color: SysStats.tempHigh ? ThemeColors.colorOnErrorContainer : ThemeColors.tertiary
                                    }

                                    Text {
                                        text: SysStats.cpuTemp + "°C"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: SysStats.tempHigh ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurface
                                    }
                                }
                            }

                            Text {
                                text: SysStats.cpuUsage + "%"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: SysStats.cpuHigh ? ThemeColors.error : ThemeColors.primary
                            }

                            MaterialIcon {
                                icon: root.cpuExpanded ? "expand_less" : "expand_more"
                                size: 18
                                color: ThemeColors.colorOnSurfaceVariant
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: ThemeColors.surfaceContainerHighest

                            Rectangle {
                                width: parent.width * Math.min(1.0, SysStats.cpuUsage / 100.0)
                                height: parent.height
                                radius: 3
                                color: SysStats.cpuHigh ? ThemeColors.error : ThemeColors.primary
                                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cpuExpanded = !root.cpuExpanded
                    }
                }

                // Grilla expandible de núcleos/hilos (4 columnas con scroll acotado a 200px)
                Item {
                    visible: root.cpuExpanded || height > 0
                    clip: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.cpuExpanded
                        ? Math.min(200, Math.max(44, Math.ceil(SysStats.coreUsages.length / 4) * 38))
                        : 0

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                    }

                    Flickable {
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: coreGrid.implicitHeight + 4
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        GridLayout {
                            id: coreGrid
                            width: parent.width
                            columns: 4
                            columnSpacing: 6
                            rowSpacing: 6

                            Repeater {
                                model: SysStats.coreUsages

                                delegate: Rectangle {
                                    id: coreCell
                                    required property var modelData
                                    readonly property bool high: modelData.percent >= 90

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: high
                                        ? Qt.rgba(ThemeColors.errorContainer.r, ThemeColors.errorContainer.g, ThemeColors.errorContainer.b, 0.7)
                                        : ThemeColors.surfaceContainerHigh

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        spacing: 3

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: coreCell.modelData.label
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 9
                                                font.weight: Font.DemiBold
                                                color: coreCell.high ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurfaceVariant
                                            }

                                            Item { Layout.fillWidth: true }

                                            Text {
                                                text: coreCell.modelData.percent + "%"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 9
                                                font.weight: Font.DemiBold
                                                color: coreCell.high ? ThemeColors.error : ThemeColors.colorOnSurface
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 3
                                            radius: 1.5
                                            color: ThemeColors.surfaceContainerHighest

                                            Rectangle {
                                                width: parent.width * Math.min(1.0, coreCell.modelData.percent / 100.0)
                                                height: parent.height
                                                radius: 1.5
                                                color: coreCell.high ? ThemeColors.error : ThemeColors.primary
                                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 2. Memoria RAM
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 14
            color: SysStats.ramHigh ? ThemeColors.errorContainer : ThemeColors.surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialIcon {
                        icon: "straighten"
                        size: 16
                        color: SysStats.ramHigh ? ThemeColors.error : ThemeColors.secondary
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Memoria RAM"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: ThemeColors.colorOnSurface
                    }

                    Text {
                        text: SysStats.ramUsedGb.toFixed(1) + " / " + SysStats.ramTotalGb.toFixed(1) + " GB (" + SysStats.ramPercent + "%)"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: SysStats.ramHigh ? ThemeColors.error : ThemeColors.secondary
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: ThemeColors.surfaceContainerHighest

                    Rectangle {
                        width: parent.width * Math.min(1.0, SysStats.ramPercent / 100.0)
                        height: parent.height
                        radius: 3
                        color: SysStats.ramHigh ? ThemeColors.error : ThemeColors.secondary
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // =====================================================================
        // 3. GPU Dedicada NVIDIA + VRAM (visible cuando nvidia-smi responde)
        // =====================================================================
        Rectangle {
            visible: SysStats.gpuAvailable
            Layout.fillWidth: true
            implicitHeight: gpuCol.implicitHeight + 20
            radius: 14
            color: SysStats.gpuTempHigh
                ? Qt.rgba(ThemeColors.errorContainer.r, ThemeColors.errorContainer.g, ThemeColors.errorContainer.b, 0.5)
                : ThemeColors.surfaceContainerLow
            border.width: 1
            border.color: SysStats.gpuTempHigh
                ? ThemeColors.error
                : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.35)

            ColumnLayout {
                id: gpuCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Cabecera GPU: ícono + nombre corto + temperatura
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialIcon {
                        icon: "developer_board"
                        size: 16
                        color: SysStats.gpuTempHigh ? ThemeColors.error : ThemeColors.tertiary
                    }

                    Text {
                        Layout.fillWidth: true
                        text: SysStats.gpuShortName
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: ThemeColors.colorOnSurface
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: SysStats.gpuTemp > 0
                        implicitHeight: 20
                        implicitWidth: gpuTempRow.implicitWidth + 10
                        radius: 10
                        color: SysStats.gpuTempHigh ? ThemeColors.errorContainer : ThemeColors.surfaceContainerHigh

                        RowLayout {
                            id: gpuTempRow
                            anchors.centerIn: parent
                            spacing: 2

                            MaterialIcon {
                                icon: "device_thermostat"
                                size: 12
                                color: SysStats.gpuTempHigh ? ThemeColors.colorOnErrorContainer : ThemeColors.tertiary
                            }

                            Text {
                                text: SysStats.gpuTemp + "°C"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: SysStats.gpuTempHigh ? ThemeColors.colorOnErrorContainer : ThemeColors.colorOnSurface
                            }
                        }
                    }
                }

                // Uso de GPU (%)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "Uso GPU"
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: ThemeColors.colorOnSurfaceVariant
                        }

                        Text {
                            text: SysStats.gpuUsage + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: SysStats.gpuUsage >= 90 ? ThemeColors.error : ThemeColors.tertiary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: ThemeColors.surfaceContainerHighest

                        Rectangle {
                            width: parent.width * Math.min(1.0, SysStats.gpuUsage / 100.0)
                            height: parent.height
                            radius: 3
                            color: SysStats.gpuUsage >= 90 ? ThemeColors.error : ThemeColors.tertiary
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Memoria VRAM (usado / total + %)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "VRAM"
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: ThemeColors.colorOnSurfaceVariant
                        }

                        Text {
                            text: SysStats.vramFormatted + " (" + SysStats.vramPercent + "%)"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: SysStats.vramPercent >= 90 ? ThemeColors.error : ThemeColors.primary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: ThemeColors.surfaceContainerHighest

                        Rectangle {
                            width: parent.width * Math.min(1.0, SysStats.vramPercent / 100.0)
                            height: parent.height
                            radius: 3
                            color: SysStats.vramPercent >= 90 ? ThemeColors.error : ThemeColors.primary
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 4. Almacenamiento (Disco)
        // =====================================================================
        Repeater {
            model: SysStats.disks.length > 0
                ? SysStats.disks
                : [{ mount: SysStats.diskMount, usedGb: SysStats.diskUsedGb, totalGb: SysStats.diskTotalGb, percent: SysStats.diskPercent }]

            delegate: Rectangle {
                id: diskCard
                required property var modelData
                readonly property bool isHigh: modelData.percent >= 90

                Layout.fillWidth: true
                implicitHeight: 58
                radius: 14
                color: isHigh ? ThemeColors.errorContainer : ThemeColors.surfaceContainerLow

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        MaterialIcon {
                            icon: "hard_drive"
                            size: 16
                            color: diskCard.isHigh ? ThemeColors.error : ThemeColors.primary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Disco (" + diskCard.modelData.mount + ")"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: ThemeColors.colorOnSurface
                        }

                        Text {
                            text: diskCard.modelData.usedGb.toFixed(1) + " / " + diskCard.modelData.totalGb.toFixed(1) + " GB (" + diskCard.modelData.percent + "%)"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: diskCard.isHigh ? ThemeColors.error : ThemeColors.primary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: ThemeColors.surfaceContainerHighest

                        Rectangle {
                            width: parent.width * Math.min(1.0, diskCard.modelData.percent / 100.0)
                            height: parent.height
                            radius: 3
                            color: diskCard.isHigh ? ThemeColors.error : ThemeColors.primary
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
