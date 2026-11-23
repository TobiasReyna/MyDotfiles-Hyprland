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
    cardWidth: 620
    cardMaxHeight: 600
    alignment: "center"
    exclusiveKeyboard: true

    property string query: ""
    property string activeCategory: "Todo"

    readonly property var _categoryDefs: [
        { name: "Internet",   icon: "language",       tags: ["network", "webbrowser", "email", "instantmessaging", "chat", "filetransfer"] },
        { name: "Desarrollo", icon: "code",           tags: ["development", "ide", "revisioncontrol", "webdevelopment", "debugger"] },
        { name: "Juegos",     icon: "sports_esports", tags: ["game", "emulator"] },
        { name: "Multimedia", icon: "play_circle",    tags: ["audiovideo", "audio", "video", "music", "player", "recorder"] },
        { name: "Gráficos",   icon: "palette",        tags: ["graphics", "2dgraphics", "3dgraphics", "rastergraphics", "vectorgraphics", "photography", "viewer"] },
        { name: "Oficina",    icon: "description",    tags: ["office", "wordprocessor", "spreadsheet", "presentation", "calendar", "publishing"] },
        { name: "Sistema",    icon: "settings",       tags: ["system", "settings", "desktopsettings", "hardwaresettings", "monitor", "packagemanager", "terminalemulator", "filemanager"] },
        { name: "Utilidades", icon: "build",          tags: ["utility", "accessories", "archiving", "compression", "calculator", "texteditor", "clock"] },
        { name: "Otros",      icon: "category",       tags: [] }
    ]

    // Convierte strings, arrays JS y QStringList de Qt6 a string plano sin errores
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

    // Convierte QStringList / string / array en lista de tokens en minúsculas
    function _toTokenList(val) {
        const out = []
        if (val === null || val === undefined)
            return out
        if (typeof val === "string") {
            const split = val.split(/[;,\s]+/)
            for (let i = 0; i < split.length; i++) {
                const t = split[i].trim().toLowerCase()
                if (t !== "")
                    out.push(t)
            }
            return out
        }
        if (typeof val.length === "number") {
            for (let i = 0; i < val.length; i++) {
                const t = String(val[i] || "").trim().toLowerCase()
                if (t !== "")
                    out.push(t)
            }
        }
        return out
    }

    function _resolveCategory(rawCategories) {
        const tokens = _toTokenList(rawCategories)
        for (let c = 0; c < _categoryDefs.length; c++) {
            const def = _categoryDefs[c]
            for (let t = 0; t < def.tags.length; t++) {
                if (tokens.indexOf(def.tags[t]) !== -1)
                    return def.name
            }
        }
        return "Otros"
    }

    // Catálogo normalizado y ordenado alfabéticamente de apps visibles
    readonly property var allApps: {
        const entries = DesktopEntries.applications ? DesktopEntries.applications.values : []
        const list = []

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
            const iconName = root._toSafeString(entry.icon).trim()
            const catName = root._resolveCategory(entry.categories)

            list.push({
                entry: entry,
                id: entryId,
                name: name,
                generic: generic,
                comment: comment,
                keywords: keywords,
                subtitle: comment !== "" ? comment : generic,
                iconPath: iconName !== "" ? Quickshell.iconPath(iconName, true) : "",
                category: catName
            })
        }

        list.sort(function(a, b) {
            return a.name.localeCompare(b.name)
        })

        return list
    }

    // Categorías visibles (solo las que tienen al menos 1 app instalada)
    readonly property var availableCategories: {
        const counts = {}
        for (let i = 0; i < allApps.length; i++) {
            const c = allApps[i].category
            counts[c] = (counts[c] || 0) + 1
        }

        const tabs = [{ name: "Todo", icon: "apps", count: allApps.length }]
        for (let i = 0; i < _categoryDefs.length; i++) {
            const def = _categoryDefs[i]
            if ((counts[def.name] || 0) > 0)
                tabs.push({ name: def.name, icon: def.icon, count: counts[def.name] })
        }
        return tabs
    }

    // Recientes resueltos contra DesktopEntries en orden de uso más reciente
    readonly property var recentApps: {
        const ids = RecentAppsService.recentIds || []
        if (ids.length === 0 || allApps.length === 0)
            return []

        const byId = {}
        for (let i = 0; i < allApps.length; i++) {
            if (allApps[i].id !== "")
                byId[allApps[i].id] = allApps[i]
        }

        const resolved = []
        for (let i = 0; i < ids.length; i++) {
            const found = byId[ids[i]]
            if (found)
                resolved.push(found)
        }
        return resolved
    }

    readonly property bool showRecentsBlock: activeCategory === "Todo" && query.trim() === "" && recentApps.length > 0

    // Lista filtrada por categoría activa y texto de búsqueda
    readonly property var filteredApps: {
        const q = root._toSafeString(root.query).trim().toLowerCase()
        const catFilter = root.activeCategory
        const matches = []

        for (let i = 0; i < allApps.length; i++) {
            const app = allApps[i]
            if (catFilter !== "Todo" && app.category !== catFilter)
                continue

            if (q === "") {
                matches.push({ app: app, score: 1 })
                continue
            }

            const nameLow = app.name.toLowerCase()
            const genericLow = app.generic.toLowerCase()
            const commentLow = app.comment.toLowerCase()
            const idLow = app.id.toLowerCase()
            const kwLow = app.keywords.toLowerCase()
            const catLow = app.category.toLowerCase()

            let score = 0
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
            else if (catLow.indexOf(q) !== -1)
                score = 15

            if (score > 0)
                matches.push({ app: app, score: score })
        }

        if (q !== "") {
            matches.sort(function(a, b) {
                if (a.score !== b.score)
                    return b.score - a.score
                return a.app.name.localeCompare(b.app.name)
            })
        }

        return matches.map(function(m) { return m.app })
    }

    onQueryChanged: _resetSelection()
    onActiveCategoryChanged: _resetSelection()

    function _resetSelection() {
        appList.currentIndex = 0
        if (appList.count > 0)
            appList.positionViewAtBeginning()
    }

    onOpened: {
        activeCategory = "Todo"
        searchInput.text = ""
        root.query = ""
        appList.currentIndex = 0
        catList.positionViewAtBeginning()
        Qt.callLater(function() {
            searchInput.forceActiveFocus()
        })
    }

    function cycleCategory(delta) {
        const tabs = availableCategories
        if (tabs.length <= 1)
            return
        let idx = 0
        for (let i = 0; i < tabs.length; i++) {
            if (tabs[i].name === activeCategory) {
                idx = i
                break
            }
        }
        const nextIdx = (idx + delta + tabs.length) % tabs.length
        activeCategory = tabs[nextIdx].name
        catList.positionViewAtIndex(nextIdx, ListView.Contain)
    }

    function launchApp(appItem) {
        if (!appItem || !appItem.entry)
            return
        RecentAppsService.recordLaunch(appItem.id)
        PopupState.close()
        appItem.entry.execute()
    }

    function launchIndex(idx) {
        if (idx < 0 || idx >= filteredApps.length)
            return
        launchApp(filteredApps[idx])
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
        spacing: 10

        // =====================================================================
        // 1. Campo de búsqueda con foco automático y navegación por teclado
        // =====================================================================
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
                    placeholderText: root.activeCategory === "Todo"
                        ? "Buscar aplicaciones... (←/→ o Tab para categorías)"
                        : ("Buscar en " + root.activeCategory + "...")
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

                    Keys.onLeftPressed: function(event) {
                        if (searchInput.text.length === 0 || (event.modifiers & Qt.AltModifier)) {
                            root.cycleCategory(-1)
                            event.accepted = true
                        }
                    }
                    Keys.onRightPressed: function(event) {
                        if (searchInput.text.length === 0 || (event.modifiers & Qt.AltModifier)) {
                            root.cycleCategory(1)
                            event.accepted = true
                        }
                    }
                    Keys.onTabPressed: function(event) {
                        root.cycleCategory(1)
                        event.accepted = true
                    }
                    Keys.onBacktabPressed: function(event) {
                        root.cycleCategory(-1)
                        event.accepted = true
                    }
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

        // =====================================================================
        // 2. Barra horizontal de categorías (chips/píldoras Material 3)
        // =====================================================================
        ListView {
            id: catList
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.availableCategories

            delegate: Rectangle {
                id: catChip
                required property var modelData
                readonly property bool isCurrent: root.activeCategory === modelData.name

                implicitHeight: 30
                implicitWidth: chipRow.implicitWidth + 18
                radius: 15
                color: isCurrent
                    ? ThemeColors.primaryContainer
                    : (chipMouse.containsMouse ? ThemeColors.surfaceContainerHigh : ThemeColors.surfaceContainerLow)
                border.width: 1
                border.color: isCurrent
                    ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.6)
                    : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.35)

                Behavior on color { ColorAnimation { duration: 130 } }

                RowLayout {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialIcon {
                        icon: catChip.modelData.icon
                        size: 14
                        filled: catChip.isCurrent
                        color: catChip.isCurrent ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                    }

                    Text {
                        text: catChip.modelData.name
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: catChip.isCurrent ? Font.DemiBold : Font.Medium
                        color: catChip.isCurrent ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                    }
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.activeCategory = catChip.modelData.name
                        searchInput.forceActiveFocus()
                    }
                }
            }
        }

        // =====================================================================
        // 3. Bloque "Recientes" (solo en "Todo" con buscador vacío y recientes > 0)
        // =====================================================================
        ColumnLayout {
            visible: root.showRecentsBlock
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                MaterialIcon {
                    icon: "history"
                    size: 15
                    color: ThemeColors.primary
                }

                Text {
                    Layout.fillWidth: true
                    text: "Recientes"
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: ThemeColors.colorOnSurfaceVariant
                }

                Rectangle {
                    implicitWidth: clearRecText.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: clearRecMouse.containsMouse ? ThemeColors.surfaceContainerHighest : "transparent"

                    Text {
                        id: clearRecText
                        anchors.centerIn: parent
                        text: "Limpiar"
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: ThemeColors.colorOnSurfaceVariant
                    }

                    MouseArea {
                        id: clearRecMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: RecentAppsService.clear()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: root.recentApps

                    delegate: Rectangle {
                        id: recCard
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 12
                        color: recMouse.containsMouse ? ThemeColors.surfaceContainerHigh : ThemeColors.surfaceContainerLow
                        border.width: 1
                        border.color: recMouse.containsMouse
                            ? Qt.rgba(ThemeColors.primary.r, ThemeColors.primary.g, ThemeColors.primary.b, 0.45)
                            : Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.35)

                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            IconImage {
                                visible: recCard.modelData.iconPath !== ""
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                source: recCard.modelData.iconPath
                                asynchronous: true
                            }

                            MaterialIcon {
                                visible: recCard.modelData.iconPath === ""
                                icon: "apps"
                                size: 18
                                color: ThemeColors.primary
                            }

                            Text {
                                Layout.fillWidth: true
                                text: recCard.modelData.name
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: ThemeColors.colorOnSurface
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: recMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launchApp(recCard.modelData)
                        }
                    }
                }
            }

            // Encabezado separador antes de "Todas las aplicaciones"
            Text {
                Layout.topMargin: 2
                text: "Todas las aplicaciones"
                font.family: "Inter"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurfaceVariant
            }
        }

        // =====================================================================
        // 4. Lista scrollable de aplicaciones filtradas
        // =====================================================================
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.showRecentsBlock
                ? (root.recentApps.length > 3 ? 320 : 368)
                : 454

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

                        // Badge discreto de categoría cuando se muestra "Todo"
                        Rectangle {
                            visible: root.activeCategory === "Todo" && !appRow.isSelected
                            implicitHeight: 20
                            implicitWidth: rowCatText.implicitWidth + 12
                            radius: 10
                            color: ThemeColors.surfaceContainerLow

                            Text {
                                id: rowCatText
                                anchors.centerIn: parent
                                text: appRow.modelData.category
                                font.family: "Inter"
                                font.pixelSize: 10
                                color: ThemeColors.colorOnSurfaceVariant
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

            // Estado vacío
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
