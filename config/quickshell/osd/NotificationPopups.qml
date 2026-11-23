import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import ".."
import "../components"
import "../services"

PanelWindow {
    id: root

    visible: NotificationService.popups.length > 0
    implicitWidth: 368
    implicitHeight: Math.max(1, toastColumn.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: 52
        right: 12
        bottom: 0
        left: 0
    }

    Column {
        id: toastColumn
        width: parent.width
        spacing: 8

        Repeater {
            model: NotificationService.popups

            delegate: Rectangle {
                id: toastCard
                required property var modelData
                readonly property string iconSource: NotificationService.resolveIconSource(modelData)

                width: toastColumn.width
                implicitHeight: cardContent.implicitHeight + 24
                height: implicitHeight
                radius: 18

                color: Qt.rgba(
                    ThemeColors.surfaceContainer.r,
                    ThemeColors.surfaceContainer.g,
                    ThemeColors.surfaceContainer.b,
                    0.95
                )
                border.width: modelData.isCritical ? 1.5 : 1
                border.color: modelData.isCritical
                    ? ThemeColors.error
                    : Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.45)

                // Animación suave de entrada (deslizamiento + opacidad)
                opacity: 0.0
                transform: Translate {
                    id: slideTransform
                    x: 36
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Component.onCompleted: {
                    opacity = 1.0
                    slideTransform.x = 0
                }

                // Autocierre pausado mientras el mouse está encima del toast
                Timer {
                    id: expireTimer
                    interval: toastCard.modelData.timeoutMs || 5000
                    running: !cardHover.containsMouse
                    repeat: false
                    onTriggered: NotificationService.dismissPopup(toastCard.modelData.id)
                }

                // Clic derecho en cualquier parte del toast para descartar
                MouseArea {
                    id: cardHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton
                    onClicked: NotificationService.dismissPopup(toastCard.modelData.id)
                }

                // Franja lateral sutil de urgencia crítica
                Rectangle {
                    visible: toastCard.modelData.isCritical
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    width: 3
                    radius: 1.5
                    color: ThemeColors.error
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.leftMargin: toastCard.modelData.isCritical ? 18 : 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Ícono de la app o imagen adjunta
                        ClippingRectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignTop
                            radius: 12
                            color: toastCard.modelData.isCritical
                                ? ThemeColors.errorContainer
                                : ThemeColors.primaryContainer

                            Image {
                                id: toastImg
                                visible: toastCard.iconSource !== "" && status === Image.Ready
                                anchors.fill: parent
                                source: toastCard.iconSource
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            MaterialIcon {
                                visible: !toastImg.visible
                                anchors.centerIn: parent
                                icon: toastCard.modelData.isCritical ? "priority_high" : "notifications"
                                size: 20
                                filled: true
                                color: toastCard.modelData.isCritical
                                    ? ThemeColors.colorOnErrorContainer
                                    : ThemeColors.colorOnPrimaryContainer
                            }
                        }

                        // Texto principal
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: toastCard.modelData.appName
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: toastCard.modelData.isCritical ? ThemeColors.error : ThemeColors.primary
                                    elide: Text.ElideRight
                                }

                                // Botón X para descartar toast
                                Rectangle {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    radius: 11
                                    color: closeHover.containsMouse ? ThemeColors.surfaceContainerHighest : "transparent"

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        icon: "close"
                                        size: 14
                                        color: ThemeColors.colorOnSurfaceVariant
                                    }

                                    MouseArea {
                                        id: closeHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.dismissPopup(toastCard.modelData.id)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: toastCard.modelData.summary
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: ThemeColors.colorOnSurface
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: text !== ""
                                Layout.fillWidth: true
                                text: toastCard.modelData.body
                                font.family: "Inter"
                                font.pixelSize: 12
                                color: ThemeColors.colorOnSurfaceVariant
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Botones de acción si la aplicación envió NotificationAction
                    RowLayout {
                        visible: toastCard.modelData.actions && toastCard.modelData.actions.length > 0
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: toastCard.modelData.actions || []

                            delegate: Rectangle {
                                id: actBtn
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                radius: 10
                                color: actHover.containsMouse
                                    ? ThemeColors.primaryContainer
                                    : ThemeColors.surfaceContainerHigh

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - 12
                                    horizontalAlignment: Text.AlignHCenter
                                    text: actBtn.modelData.text
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: actHover.containsMouse
                                        ? ThemeColors.colorOnPrimaryContainer
                                        : ThemeColors.colorOnSurface
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: actHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.invokeAction(toastCard.modelData.notif, actBtn.modelData.actionObj)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
