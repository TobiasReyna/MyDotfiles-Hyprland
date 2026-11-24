import QtQuick
import ".."

// Slider interactivo MD3 con clic directo en cualquier punto, arrastre continuo y rueda del mouse
Item {
    id: sliderRoot

    property real value: 0.0
    property bool muted: false
    property color accentColor: ThemeColors.primary
    property color handleBorderColor: ThemeColors.colorOnPrimary
    property real stepSize: 0.05

    readonly property bool dragging: sliderMouse.pressed
    property real _dragValue: 0.0
    property bool _settling: false
    property bool _hasPending: false
    property real _pendingValue: 0.0

    readonly property real visualValue: (dragging || _settling)
        ? _dragValue
        : Math.max(0.0, Math.min(1.0, value))

    readonly property real _handleRadius: 8

    signal valueEdited(real newValue)

    implicitWidth: 200
    implicitHeight: 24

    function _valueForX(mouseX) {
        const span = Math.max(1, width - _handleRadius * 2)
        const ratio = (mouseX - _handleRadius) / span
        return Math.max(0.0, Math.min(1.0, ratio))
    }

    function _queueEmit(v) {
        _pendingValue = v
        _hasPending = true
        if (!throttleTimer.running) {
            _hasPending = false
            valueEdited(v)
            throttleTimer.restart()
        }
    }

    Timer {
        id: throttleTimer
        interval: 35
        repeat: false
        onTriggered: {
            if (sliderRoot._hasPending) {
                sliderRoot._hasPending = false
                sliderRoot.valueEdited(sliderRoot._pendingValue)
                restart()
            }
        }
    }

    // Evita rebotes visuales mientras PipeWire/wpctl confirma el valor tras soltar
    Timer {
        id: settleTimer
        interval: 120
        repeat: false
        onTriggered: sliderRoot._settling = false
    }

    // Pista de fondo
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: sliderRoot._handleRadius
        anchors.rightMargin: sliderRoot._handleRadius
        height: 6
        radius: 3
        color: ThemeColors.surfaceContainerHighest

        // Progreso activo
        Rectangle {
            width: Math.max(0, Math.min(parent.width, sliderRoot.visualValue * parent.width))
            height: parent.height
            radius: 3
            color: (sliderRoot.muted && !sliderRoot.dragging) ? ThemeColors.outline : sliderRoot.accentColor
        }
    }

    // Halo sutil MD3 al hacer hover o arrastrar
    Rectangle {
        readonly property real centerX: sliderRoot._handleRadius + sliderRoot.visualValue * Math.max(0, sliderRoot.width - sliderRoot._handleRadius * 2)
        x: centerX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: sliderRoot.dragging ? 26 : (sliderMouse.containsMouse ? 22 : 0)
        height: width
        radius: width / 2
        color: Qt.rgba(sliderRoot.accentColor.r, sliderRoot.accentColor.g, sliderRoot.accentColor.b, sliderRoot.dragging ? 0.22 : 0.14)
        visible: width > 0

        Behavior on width {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }
    }

    // Perilla (handle)
    Rectangle {
        readonly property real centerX: sliderRoot._handleRadius + sliderRoot.visualValue * Math.max(0, sliderRoot.width - sliderRoot._handleRadius * 2)
        x: centerX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: sliderRoot.dragging ? 18 : 16
        height: width
        radius: width / 2
        color: (sliderRoot.muted && !sliderRoot.dragging) ? ThemeColors.outline : sliderRoot.accentColor
        border.width: 2
        border.color: sliderRoot.handleBorderColor

        Behavior on width {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: sliderMouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onPressed: function(mouse) {
            settleTimer.stop()
            sliderRoot._settling = false
            const next = sliderRoot._valueForX(mouse.x)
            sliderRoot._dragValue = next
            sliderRoot._hasPending = false
            throttleTimer.restart()
            sliderRoot.valueEdited(next)
            mouse.accepted = true
        }

        onPositionChanged: function(mouse) {
            if (!pressed)
                return
            const next = sliderRoot._valueForX(mouse.x)
            sliderRoot._dragValue = next
            sliderRoot._queueEmit(next)
            mouse.accepted = true
        }

        onReleased: function(mouse) {
            throttleTimer.stop()
            sliderRoot._hasPending = false
            const finalVal = sliderRoot._valueForX(mouse.x)
            sliderRoot._dragValue = finalVal
            sliderRoot._settling = true
            settleTimer.restart()
            sliderRoot.valueEdited(finalVal)
            mouse.accepted = true
        }

        onCanceled: {
            throttleTimer.stop()
            sliderRoot._hasPending = false
            sliderRoot._settling = false
        }

        onWheel: function(wheel) {
            if (wheel.angleDelta.y === 0)
                return
            const delta = wheel.angleDelta.y > 0 ? sliderRoot.stepSize : -sliderRoot.stepSize
            const base = (sliderRoot.dragging || sliderRoot._settling) ? sliderRoot._dragValue : sliderRoot.value
            const next = Math.max(0.0, Math.min(1.0, Math.round((base + delta) * 100) / 100))
            sliderRoot._dragValue = next
            sliderRoot._settling = true
            settleTimer.restart()
            sliderRoot.valueEdited(next)
            wheel.accepted = true
        }
    }
}
