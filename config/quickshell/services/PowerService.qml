pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery !== null && battery.isPresent

    readonly property int percentage: {
        if (!hasBattery)
            return 100
        const p = battery.percentage
        return p <= 1.0 ? Math.round(p * 100) : Math.round(p)
    }

    readonly property bool charging: hasBattery && (
        battery.state === UPowerDeviceState.Charging ||
        battery.state === UPowerDeviceState.PendingCharge
    )

    readonly property bool fullyCharged: hasBattery && battery.state === UPowerDeviceState.FullyCharged
    readonly property bool lowBattery: hasBattery && !charging && percentage <= 20

    readonly property string timeRemaining: {
        if (!hasBattery)
            return "Alimentación externa"
        if (fullyCharged)
            return "Carga completa"
        const secs = charging ? battery.timeToFull : battery.timeToEmpty
        if (!secs || secs <= 0)
            return charging ? "Cargando" : "En batería"
        const hours = Math.floor(secs / 3600)
        const mins = Math.floor((secs % 3600) / 60)
        const suffix = charging ? " para completar" : " restantes"
        if (hours > 0)
            return hours + " h " + mins + " min" + suffix
        return mins + " min" + suffix
    }

    readonly property string batteryIcon: {
        if (!hasBattery)
            return "power"
        if (charging)
            return "battery_charging_full"
        if (percentage >= 95)
            return "battery_full"
        if (percentage >= 80)
            return "battery_6_bar"
        if (percentage >= 65)
            return "battery_5_bar"
        if (percentage >= 50)
            return "battery_4_bar"
        if (percentage >= 35)
            return "battery_3_bar"
        if (percentage >= 20)
            return "battery_2_bar"
        if (percentage >= 10)
            return "battery_1_bar"
        return "battery_alert"
    }

    // Perfil de energía gestionado con powerprofilesctl (sincronizado con UPower.PowerProfiles)
    property string currentProfile: "balanced"
    property bool hasPerformanceProfile: true

    readonly property string profileLabel: {
        if (currentProfile === "power-saver")
            return "Ahorro"
        if (currentProfile === "performance")
            return "Rendimiento"
        return "Equilibrado"
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshProfile()
    }

    function refreshProfile() {
        if (!profileReadProc.running)
            profileReadProc.running = true
    }

    function setProfile(profileName) {
        if (profileSetProc.running)
            return
        currentProfile = profileName
        profileSetProc.command = ["powerprofilesctl", "set", profileName]
        profileSetProc.running = true
    }

    Process {
        id: profileReadProc
        command: [
            "sh", "-c",
            "printf 'CUR %s\\n' \"$(powerprofilesctl get 2>/dev/null || echo balanced)\"; " +
            "powerprofilesctl list 2>/dev/null | grep -q 'performance:' && echo 'PERF 1' || echo 'PERF 0'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = (text || "").trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim()
                    if (l.startsWith("CUR "))
                        root.currentProfile = l.slice(4).trim()
                    else if (l === "PERF 1")
                        root.hasPerformanceProfile = true
                    else if (l === "PERF 0")
                        root.hasPerformanceProfile = false
                }
            }
        }
    }

    Process {
        id: profileSetProc
        onExited: root.refreshProfile()
    }
}
