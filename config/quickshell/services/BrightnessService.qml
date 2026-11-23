pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int percent: 100
    property bool available: false

    signal brightnessChangedExternal(int newPercent)

    property bool _initialized: false

    function refresh() {
        if (!readProc.running)
            readProc.running = true
    }

    function setPercent(pct) {
        const clamped = Math.max(1, Math.min(100, Math.round(pct)))
        percent = clamped
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"])
    }

    // Lectura ligera inicial + refresco bajo demanda desde IPC de teclas de brillo
    Component.onCompleted: refresh()

    Process {
        id: readProc
        command: [
            "sh", "-c",
            "cur=$(brightnessctl get 2>/dev/null); max=$(brightnessctl max 2>/dev/null); " +
            "if [ -n \"$cur\" ] && [ -n \"$max\" ] && [ \"$max\" -gt 0 ]; then " +
            "  awk -v c=\"$cur\" -v m=\"$max\" 'BEGIN { printf \"%d\\n\", int((c * 100 / m) + 0.5) }'; " +
            "else echo 'NONE'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = (text || "").trim()
                if (raw === "NONE" || raw === "") {
                    root.available = false
                    return
                }
                const val = parseInt(raw, 10)
                if (!isNaN(val)) {
                    const prev = root.percent
                    root.available = true
                    root.percent = Math.max(0, Math.min(100, val))
                    if (root._initialized && root.percent !== prev)
                        root.brightnessChangedExternal(root.percent)
                    root._initialized = true
                }
            }
        }
    }
}
