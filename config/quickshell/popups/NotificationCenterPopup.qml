import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "notifications"
    cardWidth: 380
    cardMaxHeight: 560
    alignment: "top-right"

    // Refrescar etiquetas de tiempo relativo al abrir
    property int _timeTick: 0
    onOpened: _timeTick += 1

    Timer {
        interval: 30000
        running: root.isOpen && NotificationService.unreadCount > 0
        repeat: true
        onTriggered: root._timeTick += 1
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        // Cabecera: título + contador + DND + Limpiar todo
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MaterialIcon {
                icon: NotificationService.dnd ? "notifications_off" : "notifications"
                size: 19
                filled: NotificationService.unreadCount > 0
                color: NotificationService.dnd ? ThemeColors.colorOnSurfaceVariant : ThemeColors.primary
            }

            Text {
                text: "Notificaciones"
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurface
            }

            Rectangle {
                visible: NotificationService.unreadCount > 0
                implicitHeight: 20
                implicitWidth: Math.max(20, countLbl.implicitWidth + 10)
                radius: 10
                color: NotificationService.hasCritical ? ThemeColors.errorContainer : ThemeColors.primaryContainer

                Text {
                    id: countLbl
                    anchors.centerIn: parent
                    text: NotificationService.unreadCount
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: NotificationService.hasCritical
                        ? ThemeColors.colorOnErrorContainer
                        : ThemeColors.colorOnPrimaryContainer
                }
            }

            Item { Layout.fillWidth: true }

            // Botón No molestar (DND)
            PillButton {
                icon: NotificationService.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                iconSize: 15
                label: "DND"
                active: NotificationService.dnd
                onClicked: NotificationService.toggleDnd()
            }

            // Botón Limpiar todo
            PillButton {
                visible: NotificationService.unreadCount > 0
                icon: "clear_all"
                iconSize: 16
                onClicked: NotificationService.clearAll()
            }
        }

        // Lista scrollable del historial de notificaciones
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: NotificationService.unreadCount > 0
                ? Math.min(460, Math.max(140, notifList.contentHeight))
                : 150

            ListView {
                id: notifList
                visible: NotificationService.unreadCount > 0
                anchors.fill: parent
                clip: true
                spacing: 8
                model: NotificationService.history
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: histCard
                    required property var modelData
                    readonly property string iconSource: NotificationService.resolveIconSource(modelData)

                    width: notifList.width
                    implicitHeight: histCol.implicitHeight + 20
                    height: implicitHeight
                    radius: 16
                    color: modelData.isCritical
                        ? Qt.rgba(ThemeColors.errorContainer.r, ThemeColors.errorContainer.g, ThemeColors.errorContainer.b, 0.35)
                        : ThemeColors.surfaceContainerLow
                    border.width: 1
                    border.color: modelData.isCritical
                        ? ThemeColors.error
                        : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.4)

                    ColumnLayout {
                        id: histCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ClippingRectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignTop
                                radius: 10
                                color: histCard.modelData.isCritical
                                    ? ThemeColors.errorContainer
                                    : ThemeColors.primaryContainer

                                Image {
                                    id: histImg
                                    visible: histCard.iconSource !== "" && status === Image.Ready
                                    anchors.fill: parent
                                    source: histCard.iconSource
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                MaterialIcon {
                                    visible: !histImg.visible
                                    anchors.centerIn: parent
                                    icon: histCard.modelData.isCritical ? "priority_high" : "notifications"
                                    size: 18
                                    filled: true
                                    color: histCard.modelData.isCritical
                                        ? ThemeColors.colorOnErrorContainer
                                        : ThemeColors.colorOnPrimaryContainer
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true
                                        text: histCard.modelData.appName
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: histCard.modelData.isCritical ? ThemeColors.error : ThemeColors.primary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: {
                                            void(root._timeTick)
                                            return NotificationService.formatTimeLabel(histCard.modelData.timestamp)
                                        }
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: ThemeColors.colorOnSurfaceVariant
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: delHover.containsMouse ? ThemeColors.surfaceContainerHighest : "transparent"

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            icon: "close"
                                            size: 13
                                            color: ThemeColors.colorOnSurfaceVariant
                                        }

                                        MouseArea {
                                            id: delHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.removeFromHistory(histCard.modelData.id)
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: histCard.modelData.summary
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: ThemeColors.colorOnSurface
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: text !== ""
                                    Layout.fillWidth: true
                                    text: histCard.modelData.body
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    color: ThemeColors.colorOnSurfaceVariant
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Acciones pendientes si existen
                        RowLayout {
                            visible: histCard.modelData.actions && histCard.modelData.actions.length > 0
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: histCard.modelData.actions || []

                                delegate: Rectangle {
                                    id: histActBtn
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 26
                                    radius: 9
                                    color: histActHover.containsMouse
                                        ? ThemeColors.primaryContainer
                                        : ThemeColors.surfaceContainerHigh

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 10
                                        horizontalAlignment: Text.AlignHCenter
                                        text: histActBtn.modelData.text
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: histActHover.containsMouse
                                            ? ThemeColors.colorOnPrimaryContainer
                                            : ThemeColors.colorOnSurface
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: histActHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.invokeAction(histCard.modelData.notif, histActBtn.modelData.actionObj)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Estado vacío elegante
            ColumnLayout {
                visible: NotificationService.unreadCount === 0
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: NotificationService.dnd ? "notifications_off" : "notifications_none"
                    size: 34
                    color: ThemeColors.colorOnSurfaceVariant
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Sin notificaciones"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: ThemeColors.colorOnSurface
                }

                Text {
                    visible: NotificationService.dnd
                    Layout.alignment: Qt.AlignHCenter
                    text: "Modo No molestar activo"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: ThemeColors.primary
                }
            }
        }
    }
}
