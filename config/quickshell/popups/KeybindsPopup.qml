import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "keybinds"
    cardWidth: 820
    cardMaxHeight: 600
    alignment: "center"
    exclusiveKeyboard: true

    property string query: ""

    onOpened: {
        KeybindsService.reload()
        searchInput.text = ""
        root.query = ""
        Qt.callLater(function() {
            searchInput.forceActiveFocus()
        })
    }

    // Filtra categorías y atajos por acción, categoría o tecla
    readonly property var filteredCategories: {
        const cats = KeybindsService.categories || []
        const q = String(root.query || "").trim().toLowerCase()
        if (q === "")
            return cats

        const out = []
        for (let i = 0; i < cats.length; i++) {
            const cat = cats[i]
            const catMatch = cat.name.toLowerCase().indexOf(q) !== -1
            if (catMatch) {
                out.push(cat)
                continue
            }
            const matched = []
            for (let j = 0; j < cat.items.length; j++) {
                const it = cat.items[j]
                const hay = (it.description + " " + it.combo + " " + it.category).toLowerCase()
                if (hay.indexOf(q) !== -1)
                    matched.push(it)
            }
            if (matched.length > 0) {
                out.push({
                    name: cat.name,
                    icon: cat.icon,
                    items: matched
                })
            }
        }
        return out
    }

    readonly property int totalVisibleCount: {
        let total = 0
        for (let i = 0; i < filteredCategories.length; i++)
            total += filteredCategories[i].items.length
        return total
    }

    // Distribución balanceada en 2 columnas según la cantidad de filas por categoría
    readonly property var columnsData: {
        const left = []
        const right = []
        let leftWeight = 0
        let rightWeight = 0

        for (let i = 0; i < filteredCategories.length; i++) {
            const cat = filteredCategories[i]
            const weight = cat.items.length + 2
            if (leftWeight <= rightWeight) {
                left.push(cat)
                leftWeight += weight
            } else {
                right.push(cat)
                rightWeight += weight
            }
        }
        return { left: left, right: right }
    }

    component CategoryCard: Rectangle {
        id: catCard
        property var categoryData: null

        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 24
        radius: 16
        color: ThemeColors.surfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.45)

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Título de categoría
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialIcon {
                    icon: catCard.categoryData ? catCard.categoryData.icon : "keyboard"
                    size: 17
                    color: ThemeColors.primary
                }

                Text {
                    Layout.fillWidth: true
                    text: catCard.categoryData ? catCard.categoryData.name : ""
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: ThemeColors.primary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.45)
            }

            // Filas de atajos
            Repeater {
                model: catCard.categoryData ? catCard.categoryData.items : []

                delegate: RowLayout {
                    id: bindRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: bindRow.modelData.description
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: ThemeColors.colorOnSurface
                        elide: Text.ElideRight
                    }

                    // Keycaps visuales
                    Row {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        Repeater {
                            model: bindRow.modelData.keys

                            delegate: Row {
                                id: capWrap
                                required property int index
                                required property string modelData
                                readonly property bool isMod: modelData === "SUPER" || modelData === "SHIFT" || modelData === "CTRL" || modelData === "ALT"

                                spacing: 4

                                Text {
                                    visible: capWrap.index > 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "+"
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    color: ThemeColors.colorOnSurfaceVariant
                                }

                                Rectangle {
                                    implicitWidth: capLabel.implicitWidth + 12
                                    implicitHeight: 22
                                    radius: 6
                                    color: capWrap.isMod
                                        ? ThemeColors.primaryContainer
                                        : ThemeColors.surfaceContainerLowest
                                    border.width: 1
                                    border.color: capWrap.isMod
                                        ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.55)
                                        : ThemeColors.outlineVariant

                                    Text {
                                        id: capLabel
                                        anchors.centerIn: parent
                                        text: capWrap.modelData
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: capWrap.isMod
                                            ? ThemeColors.colorOnPrimaryContainer
                                            : ThemeColors.colorOnSurface
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        // Cabecera: ícono + título + contador + buscador instantáneo
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialIcon {
                icon: "keyboard"
                size: 22
                color: ThemeColors.primary
            }

            Text {
                text: "Atajos de teclado"
                font.family: "Inter"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurface
            }

            Rectangle {
                implicitHeight: 20
                implicitWidth: Math.max(24, totalBadge.implicitWidth + 10)
                radius: 10
                color: ThemeColors.primaryContainer

                Text {
                    id: totalBadge
                    anchors.centerIn: parent
                    text: root.totalVisibleCount
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: ThemeColors.colorOnPrimaryContainer
                }
            }

            // Buscador con foco automático al abrir
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 14
                color: ThemeColors.surfaceContainerLow
                border.width: 1
                border.color: searchInput.activeFocus ? ThemeColors.primary : ThemeColors.outlineVariant

                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 8

                    MaterialIcon {
                        icon: "search"
                        size: 17
                        color: ThemeColors.primary
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: "Filtrar por acción, categoría o tecla (ej. captura, firefox, shift)..."
                        color: ThemeColors.colorOnSurface
                        placeholderTextColor: ThemeColors.colorOnSurfaceVariant
                        selectionColor: ThemeColors.primaryContainer
                        selectedTextColor: ThemeColors.colorOnPrimaryContainer
                        font.family: "Inter"
                        font.pixelSize: 12
                        background: Item {}
                        leftPadding: 0
                        rightPadding: 0

                        onTextChanged: root.query = text

                        Keys.onEscapePressed: function(event) {
                            PopupState.close()
                            event.accepted = true
                        }
                    }
                }
            }
        }

        // Cuerpo scrollable en 2 columnas balanceadas
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 506

            ScrollView {
                visible: root.filteredCategories.length > 0
                anchors.fill: parent
                clip: true
                contentWidth: availableWidth

                RowLayout {
                    width: parent.width
                    spacing: 12
                    Layout.alignment: Qt.AlignTop

                    // Columna izquierda
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 12

                        Repeater {
                            model: root.columnsData.left
                            delegate: CategoryCard {
                                required property var modelData
                                categoryData: modelData
                            }
                        }
                    }

                    // Columna derecha
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 12

                        Repeater {
                            model: root.columnsData.right
                            delegate: CategoryCard {
                                required property var modelData
                                categoryData: modelData
                            }
                        }
                    }
                }
            }

            // Estado vacío cuando el filtro no encuentra coincidencias
            ColumnLayout {
                visible: root.filteredCategories.length === 0
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
                    text: "Sin atajos coincidentes"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: ThemeColors.colorOnSurfaceVariant
                }
            }
        }
    }
}
