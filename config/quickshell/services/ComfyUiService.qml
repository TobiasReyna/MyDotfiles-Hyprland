pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool running: false
    readonly property string iconPath: "file://" + Quickshell.env("HOME") + "/.local/share/icons/comfyui.svg"

    function check() {
        if (!checkProc.running && !stopProc.running)
            checkProc.running = true
    }

    function openUi() {
        Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8188"])
    }

    function stopServer() {
        if (stopProc.running)
            return
        // Ocultar el indicador de inmediato y confirmar el estado 1s después
        running = false
        stopProc.running = true
        recheckTimer.restart()
    }

    // Polling ligero cada 3 segundos sin solapar ejecuciones
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    // Re-verificación rápida tras detener el servidor
    Timer {
        id: recheckTimer
        interval: 1000
        repeat: false
        onTriggered: root.check()
    }

    Process {
        id: checkProc
        command: ["sh", "-c", "ss -tln | grep -q ':8188'"]
        onExited: function(exitCode) {
            root.running = (exitCode === 0)
        }
    }

    Process {
        id: stopProc
        command: [
            "sh", "-c",
            "(pkill -f 'main.py --reserve-vram' || fuser -k 8188/tcp) >/dev/null 2>&1 || true; " +
            "notify-send -i \"$HOME/.local/share/icons/comfyui.svg\" 'ComfyUI' 'Servidor detenido y VRAM liberada'"
        ]
    }
}
