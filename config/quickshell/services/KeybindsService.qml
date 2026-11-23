pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Lista plana de atajos: [{ category, combo, keys: [...], description }]
    property var items: []
    // Agrupados en orden lógico: [{ name, icon, items: [...] }]
    property var categories: []
    property bool loading: false

    readonly property var _categoryOrder: [
        "Aplicaciones",
        "Shell y Sistema",
        "Ventanas",
        "Workspaces",
        "Capturas de pantalla",
        "Multimedia y Brillo"
    ]

    readonly property var _categoryIcons: ({
        "Aplicaciones": "apps",
        "Shell y Sistema": "tune",
        "Ventanas": "web_asset",
        "Workspaces": "workspaces",
        "Capturas de pantalla": "screenshot_region",
        "Multimedia y Brillo": "music_note"
    })

    Component.onCompleted: reload()

    function reload() {
        if (readProc.running)
            return
        loading = true
        readProc.running = true
    }

    function _parseContent(raw) {
        const parsed = []
        const lines = String(raw || "").split("\n")

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line.startsWith("-- @bind"))
                continue
            const payload = line.slice(8).trim()
            const parts = payload.split("|")
            if (parts.length < 3)
                continue

            const category = parts[0].trim()
            const combo = parts[1].trim()
            const description = parts.slice(2).join("|").trim()
            if (!category || !combo || !description)
                continue

            const keys = combo.split("+").map(function(k) { return k.trim() }).filter(function(k) { return k.length > 0 })
            parsed.push({
                category: category,
                combo: combo,
                keys: keys,
                description: description
            })
        }

        items = parsed

        // Agrupar por categoría respetando el orden preferido
        const byCat = {}
        const catNames = []
        for (let i = 0; i < _categoryOrder.length; i++)
            byCat[_categoryOrder[i]] = []

        for (let i = 0; i < parsed.length; i++) {
            const it = parsed[i]
            if (!byCat[it.category]) {
                byCat[it.category] = []
                catNames.push(it.category)
            }
            byCat[it.category].push(it)
        }

        const orderedNames = _categoryOrder.concat(catNames)
        const grouped = []
        for (let i = 0; i < orderedNames.length; i++) {
            const name = orderedNames[i]
            const list = byCat[name]
            if (list && list.length > 0) {
                grouped.push({
                    name: name,
                    icon: _categoryIcons[name] || "keyboard",
                    items: list
                })
            }
        }
        categories = grouped
        loading = false
    }

    Process {
        id: readProc
        command: [
            "sh", "-c",
            "f=\"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/lua/keybinds.lua\"; " +
            "[ -r \"$f\" ] || f=\"$HOME/dotfiles/config/hypr/lua/keybinds.lua\"; " +
            "[ -r \"$f\" ] && cat \"$f\""
        ]
        stdout: StdioCollector {
            onStreamFinished: root._parseContent(text)
        }
        onExited: root.loading = false
    }
}
