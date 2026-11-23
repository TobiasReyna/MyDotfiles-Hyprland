import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "stats"
    cardWidth: 320
    cardMaxHeight: 340
    alignment: "top-right"

    ColumnLayout {
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            MaterialIcon {
                icon: "monitoring"
                size: 18
                color: ThemeColors.primary
            }
            Text {
                text: "Monitor del sistema"
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurface
            }
        }

        // CPU
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 62
            radius: 14
            color: SysStats.cpuHigh ? ThemeColors.errorContainer : ThemeColors.surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    MaterialIcon { icon: "memory"; size: 16; color: SysStats.cpuHigh ? ThemeColors.error : ThemeColors.primary }
                    Text {
                        Layout.fillWidth: true
                        text: "Procesador (CPU)"
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: ThemeColors.colorOnSurface
                    }
                    Text {
                        text: SysStats.cpuUsage + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: SysStats.cpuHigh ? ThemeColors.error : ThemeColors.primary
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
        }

        // RAM
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 62
            radius: 14
            color: SysStats.ramHigh ? ThemeColors.errorContainer : ThemeColors.surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    MaterialIcon { icon: "straighten"; size: 16; color: SysStats.ramHigh ? ThemeColors.error : ThemeColors.secondary }
                    Text {
                        Layout.fillWidth: true
                        text: "Memoria RAM"
                        font.family: "Inter"
                        font.pixelSize: 12
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

        // Temperatura CPU
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 62
            radius: 14
            color: SysStats.tempHigh ? ThemeColors.errorContainer : ThemeColors.surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    MaterialIcon { icon: "device_thermostat"; size: 16; color: SysStats.tempHigh ? ThemeColors.error : ThemeColors.tertiary }
                    Text {
                        Layout.fillWidth: true
                        text: "Temperatura" + (SysStats.tempSource !== "" ? " (" + SysStats.tempSource + ")" : "")
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: ThemeColors.colorOnSurface
                    }
                    Text {
                        text: SysStats.cpuTemp + " °C"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: SysStats.tempHigh ? ThemeColors.error : ThemeColors.tertiary
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: ThemeColors.surfaceContainerHighest
                    Rectangle {
                        width: parent.width * Math.min(1.0, SysStats.cpuTemp / 100.0)
                        height: parent.height
                        radius: 3
                        color: SysStats.tempHigh ? ThemeColors.error : ThemeColors.tertiary
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}
