pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var recentIds: []
    readonly property int maxRecent: 6

    Component.onCompleted: reload()

    function reload() {
        if (!readProc.running)
            readProc.running = true
    }

    function recordLaunch(appId) {
        const cleanId = String(appId || "").trim()
        if (cleanId === "")
            return

        const next = [cleanId]
        for (let i = 0; i < recentIds.length; i++) {
            const existing = String(recentIds[i] || "").trim()
            if (existing !== "" && existing !== cleanId && next.length < maxRecent)
                next.push(existing)
        }
        recentIds = next
        _persist(next)
    }

    function clear() {
        recentIds = []
        _persist([])
    }

    function _persist(list) {
        const payload = JSON.stringify(list)
        Quickshell.execDetached([
            "sh", "-c",
            "dir=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell\"; " +
            "mkdir -p \"$dir\" && printf '%s\\n' \"$1\" > \"$dir/recent_apps.json.tmp\" && " +
            "mv -f \"$dir/recent_apps.json.tmp\" \"$dir/recent_apps.json\"",
            "_", payload
        ])
    }

    Process {
        id: readProc
        command: [
            "sh", "-c",
            "f=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/recent_apps.json\"; " +
            "[ -r \"$f\" ] && cat \"$f\" || printf '[]\\n'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text || "[]").trim() || "[]")
                    if (!Array.isArray(parsed))
                        return
                    const seen = {}
                    const clean = []
                    for (let i = 0; i < parsed.length; i++) {
                        const id = String(parsed[i] || "").trim()
                        if (id !== "" && !seen[id] && clean.length < root.maxRecent) {
                            seen[id] = true
                            clean.push(id)
                        }
                    }
                    root.recentIds = clean
                } catch (e) {
                    root.recentIds = []
                }
            }
        }
    }
}
