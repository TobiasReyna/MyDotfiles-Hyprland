import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

Rectangle {
    id: root

    visible: ComfyUiService.running
    Layout.preferredWidth: 32
    Layout.preferredHeight: 28
    radius: 14

    color: mouseArea.pressed
        ? ThemeColors.surfaceContainerHighest
        : (mouseArea.containsMouse
            ? ThemeColors.surfaceContainerHigh
            : Qt.rgba(ThemeColors.surfaceContainer.r, ThemeColors.surfaceContainer.g, ThemeColors.surfaceContainer.b, 0.78))

    border.width: 1
    border.color: mouseArea.containsMouse
        ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.65)
        : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.45)

    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Image {
        id: comfyIcon
        anchors.centerIn: parent
        width: 17
        height: 17
        sourceSize.width: 34
        sourceSize.height: 34
        source: ComfyUiService.iconPath
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
    }

    MaterialIcon {
        visible: comfyIcon.status !== Image.Ready
        anchors.fill: parent
        icon: "neurology"
        size: 17
        renderType: Text.QtRendering
        color: ThemeColors.primary
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
                ComfyUiService.stopServer()
            else
                ComfyUiService.openUi()
        }
    }
}
