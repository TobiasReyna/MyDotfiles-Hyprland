pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Modo detallado: activado únicamente mientras SysStatsPopup esté abierto
    // (evita despertar la dGPU con nvidia-smi y ahorra CPU/IO en segundo plano)
    property bool detailedActive: false

    // Métricas básicas (usadas por la píldora compacta de la barra)
    property int cpuUsage: 0
    property real ramUsedGb: 0.0
    property real ramTotalGb: 0.0
    property int ramPercent: 0
    property int cpuTemp: 0
    property string tempSource: ""

    // Desglose por núcleo/hilo de CPU: [{ index, label, percent }]
    property var coreUsages: []

    // Almacenamiento (disco principal `/` + particiones extra si `/home` está separado)
    property string diskMount: "/"
    property real diskUsedGb: 0.0
    property real diskTotalGb: 0.0
    property int diskPercent: 0
    property var disks: []

    // GPU dedicada NVIDIA (solo se consulta cuando detailedActive === true)
    property bool gpuAvailable: false
    property string gpuName: ""
    property int gpuUsage: 0
    property int vramUsedMb: 0
    property int vramTotalMb: 0
    property int vramPercent: 0
    property int gpuTemp: 0

    readonly property string gpuShortName: {
        let n = String(gpuName || "").trim()
        n = n.replace(/^NVIDIA\s+GeForce\s+/i, "")
        n = n.replace(/^NVIDIA\s+/i, "")
        return n || "GPU"
    }

    readonly property string vramFormatted: {
        if (vramTotalMb <= 0)
            return "—"
        const totalStr = (vramTotalMb / 1024.0).toFixed(1) + " GB"
        if (vramUsedMb < 1024)
            return vramUsedMb + " MiB / " + totalStr
        return (vramUsedMb / 1024.0).toFixed(1) + " / " + totalStr
    }

    readonly property bool cpuHigh: cpuUsage >= 90
    readonly property bool ramHigh: ramPercent >= 90
    readonly property bool tempHigh: cpuTemp >= 85
    readonly property bool diskHigh: diskPercent >= 90
    readonly property bool gpuTempHigh: gpuTemp >= 85
    readonly property bool anyAlert: cpuHigh || ramHigh || tempHigh

    property real _prevIdle: 0
    property real _prevTotal: 0
    property var _prevCores: ({})

    onDetailedActiveChanged: {
        if (detailedActive) {
            _triggerCoreStats()
            _triggerGpu()
            _triggerDisk()
            // Segunda lectura rápida (450ms) para calcular delta real de núcleos al instante
            if (Object.keys(_prevCores).length === 0)
                quickCoreTimer.restart()
        }
    }

    function _triggerCoreStats() {
        if (!statsProc.running) {
            statsProc.command = [
                "sh", "-c",
                (root.detailedActive ? "grep '^cpu' /proc/stat; " : "head -n 1 /proc/stat; ") +
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
            statsProc.running = true
        }
    }

    function _triggerGpu() {
        if (detailedActive && !gpuProc.running)
            gpuProc.running = true
    }

    function _triggerDisk() {
        if (detailedActive && !diskProc.running)
            diskProc.running = true
    }

    // Lectura base cada 2.5s (CPU global, RAM, Temp; incluye núcleos si detailedActive)
    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._triggerCoreStats()
    }

    Timer {
        id: quickCoreTimer
        interval: 450
        repeat: false
        onTriggered: {
            if (root.detailedActive)
                root._triggerCoreStats()
        }
    }

    // Lectura de GPU NVIDIA solo mientras el popup está abierto (cada 2.5s)
    Timer {
        interval: 2500
        running: root.detailedActive
        repeat: true
        onTriggered: root._triggerGpu()
    }

    // Lectura de disco solo mientras el popup está abierto (cada 12s)
    Timer {
        interval: 12000
        running: root.detailedActive
        repeat: true
        onTriggered: root._triggerDisk()
    }

    Process {
        id: statsProc
        stdout: StdioCollector {
            onStreamFinished: root._parseStatsOutput(text)
        }
    }

    Process {
        id: gpuProc
        command: [
            "sh", "-c",
            "command -v nvidia-smi >/dev/null 2>&1 && " +
            "nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n 1"
        ]
        stdout: StdioCollector {
            onStreamFinished: root._parseGpuOutput(text)
        }
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.gpuAvailable = false
        }
    }

    Process {
        id: diskProc
        command: [
            "sh", "-c",
            "LC_ALL=C df -B1 --output=source,target,used,size,pcent / /home 2>/dev/null | tail -n +2"
        ]
        stdout: StdioCollector {
            onStreamFinished: root._parseDiskOutput(text)
        }
    }

    function _parseStatsOutput(raw) {
        if (!raw)
            return

        let memTotalKb = 0
        let memAvailKb = 0
        const nextCores = []
        const prevMap = _prevCores || {}
        const updatedPrevMap = {}

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
            } else if (/^cpu\d+\s/.test(line)) {
                const tokens = line.split(/\s+/)
                const coreKey = tokens[0]
                const idx = parseInt(coreKey.slice(3), 10)
                const parts = tokens.slice(1).map(Number)
                if (!isNaN(idx) && parts.length >= 4) {
                    const idle = (parts[3] || 0) + (parts[4] || 0)
                    let total = 0
                    for (let j = 0; j < parts.length; j++)
                        total += (parts[j] || 0)

                    let pct = 0
                    const prev = prevMap[coreKey]
                    if (prev && total > prev.total) {
                        const diffTotal = total - prev.total
                        const diffIdle = idle - prev.idle
                        pct = Math.max(0, Math.min(100, Math.round((1.0 - diffIdle / diffTotal) * 100)))
                    }
                    updatedPrevMap[coreKey] = { idle: idle, total: total }
                    nextCores.push({
                        index: idx,
                        label: "C" + idx,
                        percent: pct
                    })
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

        if (nextCores.length > 0) {
            nextCores.sort(function(a, b) { return a.index - b.index })
            _prevCores = updatedPrevMap
            coreUsages = nextCores
        }

        if (memTotalKb > 0) {
            const usedKb = Math.max(0, memTotalKb - memAvailKb)
            ramTotalGb = Math.round((memTotalKb / 1048576.0) * 10) / 10
            ramUsedGb = Math.round((usedKb / 1048576.0) * 10) / 10
            ramPercent = Math.max(0, Math.min(100, Math.round((usedKb / memTotalKb) * 100)))
        }
    }

    function _parseGpuOutput(raw) {
        const line = String(raw || "").trim()
        if (line === "") {
            gpuAvailable = false
            return
        }
        const parts = line.split(",").map(function(s) { return s.trim() })
        if (parts.length < 5) {
            gpuAvailable = false
            return
        }
        const util = Math.round(parseFloat(parts[1]))
        const usedMb = Math.round(parseFloat(parts[2]))
        const totalMb = Math.round(parseFloat(parts[3]))
        const temp = Math.round(parseFloat(parts[4]))

        if (isNaN(usedMb) || isNaN(totalMb) || totalMb <= 0) {
            gpuAvailable = false
            return
        }

        gpuName = parts[0]
        gpuUsage = isNaN(util) ? 0 : Math.max(0, Math.min(100, util))
        vramUsedMb = Math.max(0, usedMb)
        vramTotalMb = totalMb
        vramPercent = Math.max(0, Math.min(100, Math.round((vramUsedMb / vramTotalMb) * 100)))
        gpuTemp = isNaN(temp) ? 0 : temp
        gpuAvailable = true
    }

    function _parseDiskOutput(raw) {
        const lines = String(raw || "").trim().split("\n")
        const seenSources = {}
        const parsed = []
        const GB = 1073741824.0

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line)
                continue
            // Formato: [source] target used size pcent% (source puede estar vacío en contenedores)
            const parts = line.split(/\s+/)
            if (parts.length < 4)
                continue
            const pcentStr = parts[parts.length - 1]
            const sizeB = Number(parts[parts.length - 2]) || 0
            const usedB = Number(parts[parts.length - 3]) || 0
            const target = parts[parts.length - 4]
            const source = parts.length >= 5 ? parts.slice(0, parts.length - 4).join(" ") : target

            if (sizeB <= 0)
                continue
            const dedupKey = source + "|" + sizeB
            if (seenSources[dedupKey])
                continue
            seenSources[dedupKey] = true

            const pct = parseInt(pcentStr.replace("%", ""), 10)
            parsed.push({
                mount: target,
                usedGb: Math.round((usedB / GB) * 10) / 10,
                totalGb: Math.round((sizeB / GB) * 10) / 10,
                percent: isNaN(pct) ? Math.round((usedB / sizeB) * 100) : Math.max(0, Math.min(100, pct))
            })
        }

        if (parsed.length > 0) {
            disks = parsed
            diskMount = parsed[0].mount
            diskUsedGb = parsed[0].usedGb
            diskTotalGb = parsed[0].totalGb
            diskPercent = parsed[0].percent
        }
    }
}
