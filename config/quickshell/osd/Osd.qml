import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../services"

PanelWindow {
    id: root

    property bool active: false
    property string osdIcon: "volume_up"
    property int osdPercent: 0
    property bool osdMuted: false
    property bool _ready: false

    visible: active || fadeOutTimer.running
    implicitWidth: 260
    implicitHeight: 54
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        bottom: true
    }

    margins {
        bottom: 42
    }

    // Evita disparar el OSD al arrancar Quickshell antes de estabilizar PipeWire
    Timer {
        interval: 1200
        running: true
        repeat: false
        onTriggered: root._ready = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        repeat: false
        onTriggered: {
            root.active = false
            fadeOutTimer.restart()
        }
    }

    Timer {
        id: fadeOutTimer
        interval: 190
        repeat: false
    }

    function show(icon, percent, muted) {
        osdIcon = icon
        osdPercent = Math.max(0, Math.min(100, percent))
        osdMuted = muted
        fadeOutTimer.stop()
        active = true
        hideTimer.restart()
    }

    function triggerVolume() {
        show(AudioService.volumeIcon, AudioService.volumePercent, AudioService.muted)
    }

    function triggerBrightness() {
        BrightnessService.refresh()
        show("brightness_6", BrightnessService.percent, false)
    }

    // Reacción automática ante cambios de volumen / mute en PipeWire
    Connections {
        target: AudioService
        function onVolumePercentChanged() {
            if (root._ready)
                root.triggerVolume()
        }
        function onMutedChanged() {
            if (root._ready)
                root.triggerVolume()
        }
    }

    // Reacción automática ante cambios de brillo
    Connections {
        target: BrightnessService
        function onBrightnessChangedExternal(newPercent) {
            root.show("brightness_6", newPercent, false)
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 244
        height: 46
        radius: 23
        color: Qt.rgba(
            ThemeColors.surfaceContainer.r,
            ThemeColors.surfaceContainer.g,
            ThemeColors.surfaceContainer.b,
            0.92
        )
        border.width: 1
        border.color: Qt.rgba(
            ThemeColors.outlineVariant.r,
            ThemeColors.outlineVariant.g,
            ThemeColors.outlineVariant.b,
            0.65
        )

        opacity: root.active ? 1.0 : 0.0
        scale: root.active ? 1.0 : 0.92

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            MaterialIcon {
                icon: root.osdIcon
                size: 20
                filled: true
                color: root.osdMuted ? ThemeColors.outline : ThemeColors.primary
            }

            // Barra de progreso animada
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 7
                radius: 3.5
                color: ThemeColors.surfaceContainerHighest

                Rectangle {
                    width: parent.width * (root.osdMuted ? 0 : (root.osdPercent / 100.0))
                    height: parent.height
                    radius: 3.5
                    color: root.osdMuted ? ThemeColors.outline : ThemeColors.primary
                    Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: root.osdMuted ? "—" : (root.osdPercent + "%")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurface
            }
        }
    }
}
