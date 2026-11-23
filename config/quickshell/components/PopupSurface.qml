import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../services"

PanelWindow {
    id: root

    property string popupId: ""
    property int cardWidth: 360
    property int cardMaxHeight: 540
    // "top-right" | "top-center" | "center"
    property string alignment: "top-right"
    property int topOffset: 50
    property int rightOffset: 12
    // Permite foco de teclado inmediato (ej. lanzador de aplicaciones)
    property bool exclusiveKeyboard: false

    default property alias content: contentContainer.data

    readonly property bool isOpen: PopupState.activePopup === popupId

    signal opened()
    signal popupClosed()

    visible: isOpen || closeTimer.running
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen
        ? (exclusiveKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onIsOpenChanged: {
        if (isOpen) {
            closeTimer.stop()
            card.forceActiveFocus()
            root.opened()
        } else {
            closeTimer.restart()
            root.popupClosed()
        }
    }

    Timer {
        id: closeTimer
        interval: 190
        repeat: false
    }

    // Backdrop transparente para cerrar con clic fuera de la tarjeta
    MouseArea {
        anchors.fill: parent
        onClicked: PopupState.close()
    }

    Rectangle {
        id: card
        focus: root.isOpen
        width: root.cardWidth
        height: Math.min(root.cardMaxHeight, contentContainer.implicitHeight + 32)
        radius: 22

        color: Qt.rgba(
            ThemeColors.surfaceContainer.r,
            ThemeColors.surfaceContainer.g,
            ThemeColors.surfaceContainer.b,
            0.94
        )
        border.width: 1
        border.color: Qt.rgba(
            ThemeColors.outlineVariant.r,
            ThemeColors.outlineVariant.g,
            ThemeColors.outlineVariant.b,
            0.65
        )

        // Posicionamiento según alineación
        anchors.top: root.alignment !== "center" ? parent.top : undefined
        anchors.topMargin: root.alignment !== "center" ? root.topOffset : 0
        anchors.right: root.alignment === "top-right" ? parent.right : undefined
        anchors.rightMargin: root.alignment === "top-right" ? root.rightOffset : 0
        anchors.horizontalCenter: root.alignment === "top-center" ? parent.horizontalCenter : undefined
        anchors.centerIn: root.alignment === "center" ? parent : undefined

        opacity: root.isOpen ? 1.0 : 0.0
        scale: root.isOpen ? 1.0 : 0.94
        transformOrigin: root.alignment === "top-right" ? Item.TopRight
                       : root.alignment === "top-center" ? Item.Top
                       : Item.Center

        Behavior on opacity {
            NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 190; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
        }

        Keys.onEscapePressed: function(event) {
            PopupState.close()
            event.accepted = true
        }

        // Evita que los clics dentro del popup propaguen al backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true }
        }

        Item {
            id: contentContainer
            anchors.fill: parent
            anchors.margins: 16
            implicitHeight: childrenRect.height
        }
    }
}
