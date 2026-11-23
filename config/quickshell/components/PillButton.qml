import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool alert: false
    property bool iconFilled: active
    property real iconSize: 17
    property real horizontalPadding: label !== "" ? 12 : 9
    property real verticalPadding: 5

    signal clicked()
    signal rightClicked()
    signal wheelScrolled(int delta)

    implicitWidth: contentRow.implicitWidth + horizontalPadding * 2
    implicitHeight: Math.max(28, contentRow.implicitHeight + verticalPadding * 2)
    radius: height / 2

    color: {
        if (alert)
            return mouseArea.containsMouse ? Qt.lighter(ThemeColors.errorContainer, 1.12) : ThemeColors.errorContainer
        if (active)
            return mouseArea.containsMouse ? Qt.lighter(ThemeColors.primaryContainer, 1.12) : ThemeColors.primaryContainer
        if (mouseArea.pressed)
            return ThemeColors.surfaceContainerHighest
        if (mouseArea.containsMouse)
            return ThemeColors.surfaceContainerHigh
        return Qt.rgba(ThemeColors.surfaceContainer.r, ThemeColors.surfaceContainer.g, ThemeColors.surfaceContainer.b, 0.78)
    }

    border.width: 1
    border.color: {
        if (alert)
            return ThemeColors.error
        if (active)
            return Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.65)
        return Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.45)
    }

    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        MaterialIcon {
            visible: root.icon !== ""
            icon: root.icon
            size: root.iconSize
            filled: root.iconFilled
            color: root.alert ? ThemeColors.colorOnErrorContainer
                 : root.active ? ThemeColors.colorOnPrimaryContainer
                 : ThemeColors.colorOnSurface
        }

        Text {
            visible: root.label !== ""
            text: root.label
            font.family: "Inter"
            font.pixelSize: 12
            font.weight: root.active ? Font.DemiBold : Font.Medium
            color: root.alert ? ThemeColors.colorOnErrorContainer
                 : root.active ? ThemeColors.colorOnPrimaryContainer
                 : ThemeColors.colorOnSurface
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
                root.rightClicked()
            else
                root.clicked()
        }

        onWheel: function(wheel) {
            root.wheelScrolled(wheel.angleDelta.y)
        }
    }
}
