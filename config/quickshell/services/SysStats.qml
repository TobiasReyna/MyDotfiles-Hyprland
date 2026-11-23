pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpuUsage: 0
    property real ramUsedGb: 0.0
    property real ramTotalGb: 0.0
    property int ramPercent: 0
    property int cpuTemp: 0
    property string tempSource: ""

    readonly property bool cpuHigh: cpuUsage >= 90
    readonly property bool ramHigh: ramPercent >= 90
    readonly property bool tempHigh: cpuTemp >= 85
    readonly property bool anyAlert: cpuHigh || ramHigh || tempHigh

    property real _prevIdle: 0
    property real _prevTotal: 0

    // Lectura eficiente de /proc/stat, /proc/meminfo y temperatura cada 2.5s
    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statsProc.running)
                statsProc.running = true
        }
    }

    Process {
        id: statsProc
        command: [
            "sh", "-c",
            "head -n 1 /proc/stat; " +
            "awk '/^(MemTotal|MemAvailable):/ { print $1, $2 }' /proc/meminfo; " +
            "temp=''; src=''; " +
            "for f in /sys/class/hwmon/hwmon*/name; do " +
            "  [ -r \"$f\" ] || continue; n=$(cat \"$f\"); dir=$(dirname \"$f\"); " +
            "  case \"$n\" in coretemp|k10temp|zenpower|amdgpu|acpitz) " +
            "    if [ -r \"$dir/temp1_input\" ]; then temp=$(cat \"$dir/temp1_input\"); src=\"$n\"; break; fi ;; " +
            "  esac; " +
            "done; " +
            "if [ -z \"$temp\" ]; then " +
            "  for z in /sys/class/thermal/thermal_zone*/temp; do " +
            "    [ -r \"$z\" ] || continue; t=$(cat \"$z\" 2>/dev/null); " +
            "    if [ -n \"$t\" ] && [ \"$t\" -gt 10000 ] 2>/dev/null; then temp=\"$t\"; src=$(basename \"$(dirname \"$z\")\"); break; fi; " +
            "  done; " +
            "fi; " +
            "printf 'TEMP %s %s\\n' \"${temp:-0}\" \"${src:-n/a}\""
        ]

        stdout: StdioCollector {
            onStreamFinished: root._parseOutput(text)
        }
    }

    function _parseOutput(raw) {
        if (!raw)
            return

        let memTotalKb = 0
        let memAvailKb = 0

        const lines = raw.trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (line.startsWith("cpu ")) {
                const parts = line.split(/\s+/).slice(1).map(Number)
                if (parts.length >= 4) {
                    const idle = (parts[3] || 0) + (parts[4] || 0)
                    let total = 0
                    for (let j = 0; j < parts.length; j++)
                        total += (parts[j] || 0)

                    if (_prevTotal > 0 && total > _prevTotal) {
                        const diffTotal = total - _prevTotal
                        const diffIdle = idle - _prevIdle
                        cpuUsage = Math.max(0, Math.min(100, Math.round((1.0 - diffIdle / diffTotal) * 100)))
                    }
                    _prevTotal = total
                    _prevIdle = idle
                }
            } else if (line.startsWith("MemTotal:")) {
                memTotalKb = Number(line.split(/\s+/)[1]) || 0
            } else if (line.startsWith("MemAvailable:")) {
                memAvailKb = Number(line.split(/\s+/)[1]) || 0
            } else if (line.startsWith("TEMP ")) {
                const parts = line.split(/\s+/)
                const milliC = Number(parts[1]) || 0
                cpuTemp = milliC > 1000 ? Math.round(milliC / 1000) : Math.round(milliC)
                tempSource = parts[2] || ""
            }
        }

        if (memTotalKb > 0) {
            const usedKb = Math.max(0, memTotalKb - memAvailKb)
            ramTotalGb = Math.round((memTotalKb / 1048576.0) * 10) / 10
            ramUsedGb = Math.round((usedKb / 1048576.0) * 10) / 10
            ramPercent = Math.max(0, Math.min(100, Math.round((usedKb / memTotalKb) * 100)))
        }
    }
}
