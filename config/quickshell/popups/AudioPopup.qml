import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "audio"
    cardWidth: 360
    cardMaxHeight: 480
    alignment: "top-right"

    ColumnLayout {
        width: parent.width
        spacing: 14

        // Título
        RowLayout {
            Layout.fillWidth: true
            MaterialIcon {
                icon: "tune"
                size: 18
                color: ThemeColors.primary
            }
            Text {
                text: "Audio y dispositivos"
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurface
            }
        }

        // Slider de volumen principal
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: volCardCol.implicitHeight + 20
            radius: 16
            color: ThemeColors.surfaceContainerLow

            ColumnLayout {
                id: volCardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    PillButton {
                        icon: AudioService.volumeIcon
                        active: !AudioService.muted
                        onClicked: AudioService.toggleMute()
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Salida principal"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: ThemeColors.colorOnSurface
                    }

                    Text {
                        text: (AudioService.muted && !volSlider.dragging)
                            ? "Silenciado"
                            : (Math.round(volSlider.visualValue * 100) + "%")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: ThemeColors.primary
                    }
                }

                VolumeSlider {
                    id: volSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    value: AudioService.volume
                    muted: AudioService.muted
                    accentColor: ThemeColors.primary
                    handleBorderColor: ThemeColors.colorOnPrimary
                    onValueEdited: function(newValue) {
                        AudioService.setVolume(newValue)
                    }
                }
            }
        }

        // Slider de micrófono
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: micCardCol.implicitHeight + 20
            radius: 16
            color: ThemeColors.surfaceContainerLow

            ColumnLayout {
                id: micCardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    PillButton {
                        icon: AudioService.micIcon
                        active: !AudioService.micMuted
                        onClicked: AudioService.toggleMicMute()
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Micrófono"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: ThemeColors.colorOnSurface
                    }

                    Text {
                        text: (AudioService.micMuted && !micSlider.dragging)
                            ? "Silenciado"
                            : (Math.round(micSlider.visualValue * 100) + "%")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: ThemeColors.secondary
                    }
                }

                VolumeSlider {
                    id: micSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    value: AudioService.micVolume
                    muted: AudioService.micMuted
                    accentColor: ThemeColors.secondary
                    handleBorderColor: ThemeColors.colorOnSecondary
                    onValueEdited: function(newValue) {
                        AudioService.setMicVolume(newValue)
                    }
                }
            }
        }

        // Lista de dispositivos de salida (sinks)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Dispositivos de salida"
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurfaceVariant
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(180, Math.max(44, AudioService.outputSinks.length * 44))
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ListView {
                    model: AudioService.outputSinks
                    spacing: 4

                    delegate: Rectangle {
                        id: sinkDelegate
                        required property var modelData
                        readonly property bool isSelected: AudioService.defaultSink && modelData.id === AudioService.defaultSink.id

                        width: ListView.view.width
                        height: 40
                        radius: 12
                        color: sinkDelegate.isSelected
                            ? ThemeColors.primaryContainer
                            : (sinkMouse.containsMouse ? ThemeColors.surfaceContainerHigh : ThemeColors.surfaceContainerLow)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            MaterialIcon {
                                icon: sinkDelegate.isSelected ? "check_circle" : "speaker"
                                size: 17
                                filled: sinkDelegate.isSelected
                                color: sinkDelegate.isSelected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                            }

                            Text {
                                Layout.fillWidth: true
                                text: sinkDelegate.modelData.description || sinkDelegate.modelData.nickname || sinkDelegate.modelData.name || "Salida de audio"
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: sinkDelegate.isSelected ? Font.DemiBold : Font.Normal
                                color: sinkDelegate.isSelected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.setDefaultSink(sinkDelegate.modelData)
                        }
                    }
                }
            }
        }
    }
}
