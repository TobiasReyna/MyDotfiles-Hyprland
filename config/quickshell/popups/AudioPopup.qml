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
            implicitHeight: 68
            radius: 16
            color: ThemeColors.surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

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
                        text: AudioService.muted ? "Silenciado" : (AudioService.volumePercent + "%")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: ThemeColors.primary
                    }
                }

                Slider {
                    id: volSlider
                    Layout.fillWidth: true
                    from: 0.0
                    to: 1.0
                    value: AudioService.volume
                    onMoved: AudioService.setVolume(value)

                    background: Rectangle {
                        x: volSlider.leftPadding
                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        width: volSlider.availableWidth
                        height: 6
                        radius: 3
                        color: ThemeColors.surfaceContainerHighest

                        Rectangle {
                            width: volSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 3
                            color: AudioService.muted ? ThemeColors.outline : ThemeColors.primary
                        }
                    }

                    handle: Rectangle {
                        x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: ThemeColors.primary
                        border.width: 2
                        border.color: ThemeColors.colorOnPrimary
                    }
                }
            }
        }

        // Slider de micrófono
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 68
            radius: 16
            color: ThemeColors.surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

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
                        text: AudioService.micMuted ? "Silenciado" : (AudioService.micPercent + "%")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: ThemeColors.secondary
                    }
                }

                Slider {
                    id: micSlider
                    Layout.fillWidth: true
                    from: 0.0
                    to: 1.0
                    value: AudioService.micVolume
                    onMoved: AudioService.setMicVolume(value)

                    background: Rectangle {
                        x: micSlider.leftPadding
                        y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                        width: micSlider.availableWidth
                        height: 6
                        radius: 3
                        color: ThemeColors.surfaceContainerHighest

                        Rectangle {
                            width: micSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 3
                            color: AudioService.micMuted ? ThemeColors.outline : ThemeColors.secondary
                        }
                    }

                    handle: Rectangle {
                        x: micSlider.leftPadding + micSlider.visualPosition * (micSlider.availableWidth - width)
                        y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: ThemeColors.secondary
                        border.width: 2
                        border.color: ThemeColors.colorOnSecondary
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

                ListView {
                    model: AudioService.outputSinks
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelected: AudioService.defaultSink && modelData.id === AudioService.defaultSink.id

                        width: ListView.view.width
                        height: 40
                        radius: 12
                        color: isSelected
                            ? ThemeColors.primaryContainer
                            : (sinkMouse.containsMouse ? ThemeColors.surfaceContainerHigh : ThemeColors.surfaceContainerLow)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            MaterialIcon {
                                icon: isSelected ? "check_circle" : "speaker"
                                size: 17
                                filled: isSelected
                                color: isSelected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.description || modelData.nickname || modelData.name || "Salida de audio"
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: isSelected ? Font.DemiBold : Font.Normal
                                color: isSelected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.setDefaultSink(modelData)
                        }
                    }
                }
            }
        }
    }
}
