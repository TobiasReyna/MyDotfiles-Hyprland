pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Seguimiento nativo de nodos por PipeWire
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: {
            const list = []
            if (Pipewire.defaultAudioSink)
                list.push(Pipewire.defaultAudioSink)
            if (Pipewire.defaultAudioSource)
                list.push(Pipewire.defaultAudioSource)
            const allNodes = Pipewire.nodes ? Pipewire.nodes.values : []
            for (let i = 0; i < allNodes.length; i++) {
                const n = allNodes[i]
                if (n && n.audio && n.isSink && !n.isStream)
                    list.push(n)
            }
            return list
        }
    }

    readonly property real volume: (defaultSink && defaultSink.audio) ? Math.max(0, Math.min(1.0, defaultSink.audio.volume)) : 0
    readonly property int volumePercent: Math.round(volume * 100)
    readonly property bool muted: (defaultSink && defaultSink.audio) ? defaultSink.audio.muted : false

    readonly property real micVolume: (defaultSource && defaultSource.audio) ? Math.max(0, Math.min(1.0, defaultSource.audio.volume)) : 0
    readonly property int micPercent: Math.round(micVolume * 100)
    readonly property bool micMuted: (defaultSource && defaultSource.audio) ? defaultSource.audio.muted : false

    readonly property var outputSinks: {
        const result = []
        const allNodes = Pipewire.nodes ? Pipewire.nodes.values : []
        for (let i = 0; i < allNodes.length; i++) {
            const n = allNodes[i]
            if (n && n.audio && n.isSink && !n.isStream)
                result.push(n)
        }
        return result
    }

    readonly property string volumeIcon: {
        if (muted || volumePercent === 0)
            return "volume_off"
        if (volumePercent < 35)
            return "volume_down"
        return "volume_up"
    }

    readonly property string micIcon: micMuted ? "mic_off" : "mic"

    function setVolume(val) {
        const clamped = Math.max(0.0, Math.min(1.0, val))
        if (defaultSink && defaultSink.audio) {
            defaultSink.audio.volume = clamped
            if (clamped > 0 && defaultSink.audio.muted)
                defaultSink.audio.muted = false
        } else {
            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", clamped.toFixed(2)])
        }
    }

    function toggleMute() {
        if (defaultSink && defaultSink.audio)
            defaultSink.audio.muted = !defaultSink.audio.muted
        else
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    function setMicVolume(val) {
        const clamped = Math.max(0.0, Math.min(1.0, val))
        if (defaultSource && defaultSource.audio) {
            defaultSource.audio.volume = clamped
            if (clamped > 0 && defaultSource.audio.muted)
                defaultSource.audio.muted = false
        } else {
            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", clamped.toFixed(2)])
        }
    }

    function toggleMicMute() {
        if (defaultSource && defaultSource.audio)
            defaultSource.audio.muted = !defaultSource.audio.muted
        else
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
    }

    function setDefaultSink(node) {
        if (!node)
            return
        Pipewire.preferredDefaultAudioSink = node
        if (node.id !== undefined)
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)])
    }
}
