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

    popupId: "launcher"
    cardWidth: 560
    cardMaxHeight: 520
    alignment: "center"
    exclusiveKeyboard: true

    property string query: ""

    // Convierte de forma segura strings, arrays JS y QStringList de Qt6 a string plano
    function _toSafeString(val) {
        if (val === null || val === undefined)
            return ""
        if (typeof val === "string")
            return val
        if (typeof val.length === "number") {
            const parts = []
            for (let i = 0; i < val.length; i++)
                parts.push(String(val[i] || ""))
            return parts.join(" ")
        }
        return String(val)
    }

    // Lista filtrada reactiva a `query` y a `DesktopEntries.applications.values`
    readonly property var filteredApps: {
        const entries = DesktopEntries.applications ? DesktopEntries.applications.values : []
        const q = root._toSafeString(root.query).trim().toLowerCase()
        const matches = []

        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i]
            if (!entry || entry.noDisplay)
                continue

            const name = root._toSafeString(entry.name).trim()
            if (name === "")
                continue

            const generic = root._toSafeString(entry.genericName).trim()
            const comment = root._toSafeString(entry.comment).trim()
            const entryId = root._toSafeString(entry.id).trim()
            const keywords = root._toSafeString(entry.keywords).trim()

            let score = 0
            if (q === "") {
                score = 1
            } else {
                const nameLow = name.toLowerCase()
                const genericLow = generic.toLowerCase()
                const commentLow = comment.toLowerCase()
                const idLow = entryId.toLowerCase()
                const kwLow = keywords.toLowerCase()

                if (nameLow === q)
                    score = 100
                else if (nameLow.startsWith(q))
                    score = 80
                else if (nameLow.indexOf(q) !== -1)
                    score = 60
                else if (idLow.startsWith(q))
                    score = 50
                else if (genericLow.indexOf(q) !== -1)
                    score = 40
                else if (kwLow.indexOf(q) !== -1)
                    score = 30
                else if (commentLow.indexOf(q) !== -1 || idLow.indexOf(q) !== -1)
                    score = 20
            }

            if (score > 0) {
                const iconName = root._toSafeString(entry.icon).trim()
                matches.push({
                    entry: entry,
                    name: name,
                    subtitle: comment !== "" ? comment : generic,
                    iconPath: iconName !== "" ? Quickshell.iconPath(iconName, true) : "",
                    score: score
                })
            }
        }

        matches.sort(function(a, b) {
            if (a.score !== b.score)
                return b.score - a.score
            return a.name.localeCompare(b.name)
        })

        return matches
    }

    onQueryChanged: {
        appList.currentIndex = 0
        if (appList.count > 0)
            appList.positionViewAtBeginning()
    }

    onOpened: {
        searchInput.text = ""
        root.query = ""
        appList.currentIndex = 0
        Qt.callLater(function() {
            searchInput.forceActiveFocus()
        })
    }

    function launchIndex(idx) {
        if (idx < 0 || idx >= filteredApps.length)
            return
        const item = filteredApps[idx]
        if (item && item.entry) {
            PopupState.close()
            item.entry.execute()
        }
    }

    function moveSelection(delta) {
        const count = filteredApps.length
        if (count === 0)
            return
        const base = appList.currentIndex < 0 ? 0 : appList.currentIndex
        appList.currentIndex = (base + delta + count) % count
        appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        // Campo de búsqueda con foco automático al abrir
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 16
            color: ThemeColors.surfaceContainerLow
            border.width: 1
            border.color: searchInput.activeFocus ? ThemeColors.primary : ThemeColors.outlineVariant

            Behavior on border.color { ColorAnimation { duration: 140 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 10

                MaterialIcon {
                    icon: "search"
                    size: 20
                    color: ThemeColors.primary
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Buscar aplicaciones..."
                    color: ThemeColors.colorOnSurface
                    placeholderTextColor: ThemeColors.colorOnSurfaceVariant
                    selectionColor: ThemeColors.primaryContainer
                    selectedTextColor: ThemeColors.colorOnPrimaryContainer
                    font.family: "Inter"
                    font.pixelSize: 14
                    background: Item {}
                    leftPadding: 0
                    rightPadding: 0

                    onTextChanged: root.query = text

                    Keys.onDownPressed: function(event) {
                        root.moveSelection(1)
                        event.accepted = true
                    }
                    Keys.onUpPressed: function(event) {
                        root.moveSelection(-1)
                        event.accepted = true
                    }
                    Keys.onReturnPressed: function(event) {
                        root.launchIndex(appList.currentIndex >= 0 ? appList.currentIndex : 0)
                        event.accepted = true
                    }
                    Keys.onEnterPressed: function(event) {
                        root.launchIndex(appList.currentIndex >= 0 ? appList.currentIndex : 0)
                        event.accepted = true
                    }
                    Keys.onEscapePressed: function(event) {
                        PopupState.close()
                        event.accepted = true
                    }
                }

                Text {
                    visible: root.filteredApps.length > 0
                    text: root.filteredApps.length
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: ThemeColors.colorOnSurfaceVariant
                }
            }
        }

        // Lista scrollable de aplicaciones
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 410

            ListView {
                id: appList
                anchors.fill: parent
                clip: true
                spacing: 4
                model: root.filteredApps
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: appRow
                    required property int index
                    required property var modelData
                    readonly property bool isSelected: index === appList.currentIndex

                    width: appList.width
                    height: 52
                    radius: 14
                    color: isSelected
                        ? ThemeColors.primaryContainer
                        : (rowMouse.containsMouse ? ThemeColors.surfaceContainerHigh : "transparent")

                    Behavior on color { ColorAnimation { duration: 110 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 12

                        // Ícono real de la aplicación o fallback Material Symbol
                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 10
                            color: appRow.isSelected
                                ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.22)
                                : ThemeColors.surfaceContainerLow

                            IconImage {
                                visible: appRow.modelData.iconPath !== ""
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                source: appRow.modelData.iconPath
                                asynchronous: true
                            }

                            MaterialIcon {
                                visible: appRow.modelData.iconPath === ""
                                anchors.centerIn: parent
                                icon: "apps"
                                size: 20
                                color: appRow.isSelected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.primary
                            }
                        }

                        // Nombre y descripción breve
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: appRow.modelData.name
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: appRow.isSelected ? Font.DemiBold : Font.Medium
                                color: appRow.isSelected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: appRow.modelData.subtitle !== ""
                                Layout.fillWidth: true
                                text: appRow.modelData.subtitle
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: appRow.isSelected
                                    ? Qt.rgba(ThemeColors.colorOnPrimaryContainer.r, ThemeColors.colorOnPrimaryContainer.g, ThemeColors.colorOnPrimaryContainer.b, 0.8)
                                    : ThemeColors.colorOnSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        MaterialIcon {
                            visible: appRow.isSelected
                            icon: "subdirectory_arrow_left"
                            size: 16
                            color: ThemeColors.colorOnPrimaryContainer
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: appList.currentIndex = appRow.index
                        onClicked: root.launchIndex(appRow.index)
                    }
                }
            }

            // Estado vacío cuando no hay coincidencias
            ColumnLayout {
                visible: root.filteredApps.length === 0
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "search_off"
                    size: 32
                    color: ThemeColors.colorOnSurfaceVariant
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Sin resultados"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: ThemeColors.colorOnSurfaceVariant
                }
            }
        }
    }
}
