pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    // "off" | "timed" | "indefinite"
    property string mode: "off"
    property int remainingSeconds: 0
    // Minutos seleccionados para resaltar píldora activa: 0 (off), >0 (minutos), -1 (indefinido)
    property int selectedMinutes: 0

    readonly property string formattedRemaining: {
        if (!active || mode === "off")
            return "Desactivado"
        if (mode === "indefinite")
            return "Indefinido"

        const total = Math.max(0, remainingSeconds)
        const h = Math.floor(total / 3600)
        const m = Math.floor((total % 3600) / 60)
        const s = total % 60
        const mm = String(m).padStart(2, "0")
        const ss = String(s).padStart(2, "0")
        if (h > 0)
            return String(h).padStart(2, "0") + ":" + mm + ":" + ss
        return mm + ":" + ss
    }

    function enableIndefinite() {
        remainingSeconds = 0
        selectedMinutes = -1
        mode = "indefinite"
        active = true
    }

    function enableForMinutes(minutes) {
        const mins = Math.max(1, Math.round(Number(minutes) || 0))
        remainingSeconds = mins * 60
        selectedMinutes = mins
        mode = "timed"
        active = true
    }

    function disable() {
        active = false
        mode = "off"
        remainingSeconds = 0
        selectedMinutes = 0
    }

    function toggle() {
        if (active)
            disable()
        else
            enableIndefinite()
    }

    // Cuenta regresiva solo activa cuando hay temporizador
    Timer {
        interval: 1000
        running: root.active && root.mode === "timed"
        repeat: true
        onTriggered: {
            if (root.remainingSeconds <= 1) {
                root.disable()
            } else {
                root.remainingSeconds -= 1
            }
        }
    }

    // Inhibidor real de systemd-logind (idle + sleep) mientras `active === true`
    Process {
        id: inhibitProc
        running: root.active
        command: [
            "systemd-inhibit",
            "--what=idle:sleep",
            "--who=Quickshell",
            "--why=Mantener pantalla encendida",
            "--mode=block",
            "sleep", "infinity"
        ]
    }
}
