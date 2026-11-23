pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool ethernetConnected: false
    property string activeSsid: ""
    property int activeSignal: 0
    property bool scanning: false
    property bool busy: false
    property string statusMessage: ""
    // Lista de objetos: { ssid, signal, security, active, secured }
    property var networks: []

    readonly property bool connected: ethernetConnected || activeSsid !== ""

    readonly property string barIcon: {
        if (ethernetConnected)
            return "lan"
        if (!wifiEnabled)
            return "wifi_off"
        if (activeSsid === "")
            return "wifi_find"
        if (activeSignal >= 75)
            return "signal_wifi_4_bar"
        if (activeSignal >= 50)
            return "network_wifi_3_bar"
        if (activeSignal >= 25)
            return "network_wifi_2_bar"
        return "network_wifi_1_bar"
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }

    function refreshStatus() {
        if (!statusProc.running)
            statusProc.running = true
    }

    function scan(rescan) {
        if (scanProc.running)
            return
        scanning = true
        statusMessage = ""
        const rescanFlag = rescan ? "yes" : "no"
        scanProc.command = [
            "nmcli", "-t", "-e", "no", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "device", "wifi", "list", "--rescan", rescanFlag
        ]
        scanProc.running = true
    }

    function toggleWifi() {
        if (actionProc.running)
            return
        busy = true
        const nextState = wifiEnabled ? "off" : "on"
        actionProc.command = ["nmcli", "radio", "wifi", nextState]
        actionProc.running = true
    }

    function connect(ssid, password) {
        if (actionProc.running || !ssid)
            return
        busy = true
        statusMessage = "Conectando a " + ssid + "..."
        if (password && password.length > 0) {
            actionProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        } else {
            actionProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        }
        actionProc.running = true
    }

    function disconnect() {
        if (actionProc.running)
            return
        busy = true
        statusMessage = "Desconectando..."
        actionProc.command = [
            "sh", "-c",
            "dev=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2==\"wifi\" && $3==\"connected\" {print $1; exit}'); " +
            "[ -n \"$dev\" ] && nmcli device disconnect \"$dev\""
        ]
        actionProc.running = true
    }

    Process {
        id: statusProc
        command: [
            "sh", "-c",
            "printf 'RADIO %s\\n' \"$(nmcli -t -f WIFI general 2>/dev/null | head -n1)\"; " +
            "nmcli -t -f TYPE,STATE device 2>/dev/null | awk -F: '$1==\"ethernet\" && $2==\"connected\" {print \"ETH 1\"; exit}'; " +
            "nmcli -t -e no -f IN-USE,SSID,SIGNAL device wifi list --rescan no 2>/dev/null | awk -F: '$1==\"*\" {print \"ACTIVE:\" $2 \":\" $3; exit}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let wifiOn = false
                let eth = false
                let ssid = ""
                let sig = 0

                const lines = (text || "").trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim()
                    if (l.startsWith("RADIO ")) {
                        wifiOn = l.indexOf("enabled") !== -1
                    } else if (l === "ETH 1") {
                        eth = true
                    } else if (l.startsWith("ACTIVE:")) {
                        const rest = l.slice(7)
                        const lastColon = rest.lastIndexOf(":")
                        if (lastColon > 0) {
                            ssid = rest.slice(0, lastColon)
                            sig = parseInt(rest.slice(lastColon + 1), 10) || 0
                        }
                    }
                }
                root.wifiEnabled = wifiOn
                root.ethernetConnected = eth
                root.activeSsid = ssid
                root.activeSignal = sig
            }
        }
    }

    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                const list = []
                const lines = (text || "").trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    if (!line)
                        continue
                    // Formato: IN-USE:SSID:SIGNAL:SECURITY (SSID puede contener ':')
                    const parts = line.split(":")
                    if (parts.length < 4)
                        continue
                    const inUse = parts[0] === "*"
                    const security = parts[parts.length - 1]
                    const signal = parseInt(parts[parts.length - 2], 10) || 0
                    const ssid = parts.slice(1, parts.length - 2).join(":").trim()
                    if (!ssid)
                        continue
                    if (seen[ssid]) {
                        if (inUse)
                            seen[ssid].active = true
                        if (signal > seen[ssid].signal)
                            seen[ssid].signal = signal
                        continue
                    }
                    const entry = {
                        ssid: ssid,
                        signal: signal,
                        security: security,
                        active: inUse,
                        secured: security !== "" && security !== "--"
                    }
                    seen[ssid] = entry
                    list.push(entry)
                }

                list.sort(function(a, b) {
                    if (a.active !== b.active)
                        return a.active ? -1 : 1
                    return b.signal - a.signal
                })

                root.networks = list
                root.scanning = false
            }
        }
        onExited: root.scanning = false
    }

    Process {
        id: actionProc
        stdout: StdioCollector { id: actionOut }
        stderr: StdioCollector { id: actionErr }
        onExited: function(exitCode) {
            root.busy = false
            if (exitCode !== 0) {
                const msg = (actionErr.text || actionOut.text || "Error de conexión").trim()
                root.statusMessage = msg.split("\n")[0]
            } else {
                root.statusMessage = ""
            }
            root.refreshStatus()
            root.scan(false)
        }
    }
}
