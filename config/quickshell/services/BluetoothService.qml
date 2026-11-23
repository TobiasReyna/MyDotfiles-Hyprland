pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool powered: false
    property bool scanning: false
    property bool busy: false
    property string statusMessage: ""
    // Lista de objetos: { mac, name, connected, paired }
    property var devices: []

    readonly property int connectedCount: {
        let count = 0
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                count++
        }
        return count
    }

    readonly property string barIcon: {
        if (!powered)
            return "bluetooth_disabled"
        if (connectedCount > 0)
            return "bluetooth_connected"
        return "bluetooth"
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (!refreshProc.running)
            refreshProc.running = true
    }

    function togglePower() {
        if (actionProc.running)
            return
        busy = true
        statusMessage = ""
        actionProc.command = ["bluetoothctl", "power", powered ? "off" : "on"]
        actionProc.running = true
    }

    function scan() {
        if (scanProc.running || !powered)
            return
        scanning = true
        statusMessage = "Escaneando dispositivos (6s)..."
        scanProc.command = ["bluetoothctl", "--timeout", "6", "scan", "on"]
        scanProc.running = true
    }

    function toggleDevice(mac, isConnected) {
        if (actionProc.running || !mac)
            return
        busy = true
        statusMessage = isConnected ? "Desconectando..." : "Conectando..."
        actionProc.command = ["bluetoothctl", isConnected ? "disconnect" : "connect", mac]
        actionProc.running = true
    }

    Process {
        id: refreshProc
        command: [
            "sh", "-c",
            "power=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}'); " +
            "printf 'POWER %s\\n' \"${power:-no}\"; " +
            "bluetoothctl devices 2>/dev/null | while read -r _ mac name; do " +
            "  [ -n \"$mac\" ] || continue; " +
            "  info=$(bluetoothctl info \"$mac\" 2>/dev/null); " +
            "  conn=$(printf '%s\\n' \"$info\" | awk '/Connected:/ {print $2; exit}'); " +
            "  paired=$(printf '%s\\n' \"$info\" | awk '/Paired:/ {print $2; exit}'); " +
            "  printf 'DEV|%s|%s|%s|%s\\n' \"$mac\" \"$name\" \"${conn:-no}\" \"${paired:-no}\"; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let isPowered = false
                const list = []
                const lines = (text || "").trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim()
                    if (l.startsWith("POWER ")) {
                        isPowered = l.indexOf("yes") !== -1
                    } else if (l.startsWith("DEV|")) {
                        const parts = l.split("|")
                        if (parts.length >= 5) {
                            list.push({
                                mac: parts[1],
                                name: parts[2] || parts[1],
                                connected: parts[3] === "yes",
                                paired: parts[4] === "yes"
                            })
                        }
                    }
                }
                list.sort(function(a, b) {
                    if (a.connected !== b.connected)
                        return a.connected ? -1 : 1
                    if (a.paired !== b.paired)
                        return a.paired ? -1 : 1
                    return a.name.localeCompare(b.name)
                })
                root.powered = isPowered
                root.devices = list
            }
        }
    }

    Process {
        id: scanProc
        onExited: {
            root.scanning = false
            root.statusMessage = ""
            root.refresh()
        }
    }

    Process {
        id: actionProc
        stderr: StdioCollector { id: btErr }
        onExited: function(exitCode) {
            root.busy = false
            root.statusMessage = exitCode !== 0 ? (btErr.text || "Error de Bluetooth").trim().split("\n")[0] : ""
            root.refresh()
        }
    }
}
