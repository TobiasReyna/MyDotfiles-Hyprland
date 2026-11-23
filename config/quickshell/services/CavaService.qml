pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Solo debe ponerse en `true` mientras MediaPopup esté abierto y reproduciendo
    property bool active: false
    property int barCount: 26
    property var bars: _emptyBars()
    property bool available: true

    readonly property bool running: cavaProc.running

    function _emptyBars() {
        const arr = []
        for (let i = 0; i < barCount; i++)
            arr.push(0)
        return arr
    }

    onActiveChanged: {
        if (!active)
            bars = _emptyBars()
    }

    // Verificación silenciosa al inicio para no lanzar errores si cava no está instalado
    Process {
        id: checkProc
        running: true
        command: ["sh", "-c", "command -v cava >/dev/null 2>&1"]
        onExited: function(exitCode) {
            root.available = (exitCode === 0)
        }
    }

    Process {
        id: cavaProc
        running: root.active && root.available
        command: [
            "sh", "-c",
            "cfg=\"${XDG_CONFIG_HOME:-$HOME/.config}/cava/quickshell.conf\"; " +
            "[ -f \"$cfg\" ] || cfg=\"$HOME/dotfiles/config/cava/quickshell.conf\"; " +
            "if command -v cava >/dev/null 2>&1 && [ -f \"$cfg\" ]; then exec cava -p \"$cfg\"; fi"
        ]

        stdout: SplitParser {
            onRead: function(data) {
                if (!root.active || !data)
                    return
                const parts = data.trim().split(";")
                const next = []
                for (let i = 0; i < root.barCount; i++) {
                    const v = i < parts.length ? parseInt(parts[i], 10) : 0
                    next.push(isNaN(v) ? 0 : Math.max(0, Math.min(100, v)))
                }
                root.bars = next
            }
        }

        onExited: {
            if (!root.active)
                root.bars = root._emptyBars()
        }
    }
}
