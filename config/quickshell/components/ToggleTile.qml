import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool busy: false

    signal clicked()

    implicitHeight: 54
    radius: 16
    color: {
        if (active)
            return mouseArea.containsMouse ? Qt.lighter(ThemeColors.primaryContainer, 1.08) : ThemeColors.primaryContainer
        return mouseArea.containsMouse ? ThemeColors.surfaceContainerHighest : ThemeColors.surfaceContainerHigh
    }
    border.width: 1
    border.color: active
        ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.55)
        : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.35)

    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 16
            color: root.active
                ? ThemeColors.primary
                : Qt.rgba(ThemeColors.surfaceContainerLowest.r, ThemeColors.surfaceContainerLowest.g, ThemeColors.surfaceContainerLowest.b, 0.55)

            MaterialIcon {
                anchors.centerIn: parent
                icon: root.icon
                size: 18
                filled: root.active
                color: root.active ? ThemeColors.colorOnPrimary : ThemeColors.colorOnSurfaceVariant
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.active ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                elide: Text.ElideRight
            }

            Text {
                visible: root.subtitle !== ""
                Layout.fillWidth: true
                text: root.busy ? "Actualizando..." : root.subtitle
                font.family: "Inter"
                font.pixelSize: 11
                color: root.active
                    ? Qt.rgba(ThemeColors.colorOnPrimaryContainer.r, ThemeColors.colorOnPrimaryContainer.g, ThemeColors.colorOnPrimaryContainer.b, 0.8)
                    : ThemeColors.colorOnSurfaceVariant
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
