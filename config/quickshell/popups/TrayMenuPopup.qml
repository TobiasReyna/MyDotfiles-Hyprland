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

    popupId: "traymenu"
    cardWidth: 270
    cardMaxHeight: 480
    alignment: "top-right"
    rightOffset: PopupState.trayMenuRightOffset

    // Pila de submenús: [{ title, handle }]
    property var menuStack: []

    readonly property var currentLevel: menuStack.length > 0 ? menuStack[menuStack.length - 1] : null
    readonly property var currentHandle: currentLevel ? currentLevel.handle : null
    readonly property string currentTitle: currentLevel ? currentLevel.title : PopupState.trayMenuTitle

    function resetToRoot() {
        if (PopupState.trayMenuHandle) {
            menuStack = [{
                title: PopupState.trayMenuTitle || "Menú",
                handle: PopupState.trayMenuHandle
            }]
        } else {
            menuStack = []
        }
    }

    function pushSubmenu(entry) {
        if (!entry)
            return
        const next = menuStack.slice()
        next.push({
            title: String(entry.text || "Submenú").replace(/&/g, ""),
            handle: entry
        })
        menuStack = next
    }

    function popSubmenu() {
        if (menuStack.length > 1) {
            menuStack = menuStack.slice(0, menuStack.length - 1)
        } else {
            PopupState.close()
        }
    }

    onOpened: resetToRoot()

    Connections {
        target: PopupState
        function onTrayMenuHandleChanged() {
            if (root.isOpen)
                root.resetToRoot()
        }
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.isOpen ? root.currentHandle : null
    }

    readonly property var menuItems: {
        const raw = (menuOpener.children && menuOpener.children.values) ? menuOpener.children.values : []
        const result = []
        for (let i = 0; i < raw.length; i++) {
            const entry = raw[i]
            if (!entry)
                continue
            // Evitar separadores duplicados al inicio o consecutivos
            if (entry.isSeparator && (result.length === 0 || result[result.length - 1].isSeparator))
                continue
            result.push(entry)
        }
        // Quitar separador suelto al final
        while (result.length > 0 && result[result.length - 1].isSeparator)
            result.pop()
        return result
    }

    ColumnLayout {
        width: parent.width
        spacing: 8

        // Cabecera con título de la app o botón Volver para submenús
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                visible: root.menuStack.length > 1
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                color: backMouse.containsMouse ? ThemeColors.surfaceContainerHigh : ThemeColors.surfaceContainerLow

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: "arrow_back"
                    size: 16
                    color: ThemeColors.primary
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.popSubmenu()
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.currentTitle
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurface
                elide: Text.ElideRight
            }
        }

        // Divisor sutil bajo la cabecera
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.5)
        }

        // Lista scrollable de opciones del menú DBusMenu
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(390, Math.max(44, menuList.contentHeight))
            clip: true

            ListView {
                id: menuList
                width: parent.width
                spacing: 2
                model: root.menuItems
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: itemWrap
                    required property var modelData
                    readonly property bool isSep: Boolean(modelData.isSeparator)
                    readonly property bool isEnabled: modelData.enabled !== false
                    readonly property bool hasSub: Boolean(modelData.hasChildren)
                    readonly property string cleanText: String(modelData.text || "").replace(/&/g, "")
                    readonly property string iconSource: modelData.icon ? String(modelData.icon) : ""

                    width: menuList.width
                    height: isSep ? 10 : 34

                    // Separador
                    Rectangle {
                        visible: itemWrap.isSep
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        height: 1
                        color: Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.55)
                    }

                    // Ítem clicable
                    Rectangle {
                        visible: !itemWrap.isSep
                        anchors.fill: parent
                        radius: 10
                        color: (itemWrap.isEnabled && itemMouse.containsMouse)
                            ? ThemeColors.surfaceContainerHigh
                            : "transparent"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            opacity: itemWrap.isEnabled ? 1.0 : 0.45

                            // Indicador CheckBox / RadioButton si aplica
                            MaterialIcon {
                                visible: itemWrap.modelData.buttonType === QsMenuButtonType.CheckBox
                                      || itemWrap.modelData.buttonType === QsMenuButtonType.RadioButton
                                size: 16
                                filled: itemWrap.modelData.checkState === Qt.Checked
                                icon: {
                                    if (itemWrap.modelData.buttonType === QsMenuButtonType.RadioButton)
                                        return itemWrap.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked"
                                    return itemWrap.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank"
                                }
                                color: itemWrap.modelData.checkState === Qt.Checked ? ThemeColors.primary : ThemeColors.colorOnSurfaceVariant
                            }

                            // Ícono propio del ítem DBusMenu
                            IconImage {
                                visible: itemWrap.iconSource !== ""
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                source: itemWrap.iconSource
                                asynchronous: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: itemWrap.cleanText
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Normal
                                color: ThemeColors.colorOnSurface
                                elide: Text.ElideRight
                            }

                            MaterialIcon {
                                visible: itemWrap.hasSub
                                icon: "chevron_right"
                                size: 16
                                color: ThemeColors.colorOnSurfaceVariant
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: itemWrap.isEnabled && !itemWrap.isSep
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (itemWrap.hasSub) {
                                    root.pushSubmenu(itemWrap.modelData)
                                } else {
                                    itemWrap.modelData.triggered()
                                    PopupState.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.menuItems.length === 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "Sin opciones disponibles"
            font.family: "Inter"
            font.pixelSize: 12
            color: ThemeColors.colorOnSurfaceVariant
        }
    }
}
