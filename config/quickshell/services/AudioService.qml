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

    readonly property real volume: {
        if (defaultSink && defaultSink.ready && defaultSink.audio) {
            const v = defaultSink.audio.volume
            if (!isNaN(v))
                return Math.max(0.0, Math.min(1.0, v))
        }
        return 0.0
    }
    readonly property int volumePercent: Math.round(volume * 100)
    readonly property bool muted: (defaultSink && defaultSink.ready && defaultSink.audio) ? defaultSink.audio.muted : false

    readonly property real micVolume: {
        if (defaultSource && defaultSource.ready && defaultSource.audio) {
            const v = defaultSource.audio.volume
            if (!isNaN(v))
                return Math.max(0.0, Math.min(1.0, v))
        }
        return 0.0
    }
    readonly property int micPercent: Math.round(micVolume * 100)
    readonly property bool micMuted: (defaultSource && defaultSource.ready && defaultSource.audio) ? defaultSource.audio.muted : false

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
        const num = Number(val)
        if (isNaN(num))
            return
        const clamped = Math.max(0.0, Math.min(1.0, num))
        const pct = Math.round(clamped * 100)
        const sink = defaultSink
        if (sink && sink.ready && sink.audio) {
            sink.audio.volume = clamped
            if (pct > 0 && sink.audio.muted)
                sink.audio.muted = false
        } else {
            if (pct > 0)
                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
            Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", pct + "%"])
        }
    }

    function setVolumePercent(pct) {
        const num = Number(pct)
        if (isNaN(num))
            return
        setVolume(Math.max(0, Math.min(100, Math.round(num))) / 100.0)
    }

    function toggleMute() {
        const sink = defaultSink
        if (sink && sink.ready && sink.audio)
            sink.audio.muted = !sink.audio.muted
        else
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    function setMicVolume(val) {
        const num = Number(val)
        if (isNaN(num))
            return
        const clamped = Math.max(0.0, Math.min(1.0, num))
        const pct = Math.round(clamped * 100)
        const source = defaultSource
        if (source && source.ready && source.audio) {
            source.audio.volume = clamped
            if (pct > 0 && source.audio.muted)
                source.audio.muted = false
        } else {
            if (pct > 0)
                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "0"])
            Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SOURCE@", pct + "%"])
        }
    }

    function setMicVolumePercent(pct) {
        const num = Number(pct)
        if (isNaN(num))
            return
        setMicVolume(Math.max(0, Math.min(100, Math.round(num))) / 100.0)
    }

    function toggleMicMute() {
        const source = defaultSource
        if (source && source.ready && source.audio)
            source.audio.muted = !source.audio.muted
        else
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
    }

    function setDefaultSink(node) {
        if (!node)
            return
        Pipewire.preferredDefaultAudioSink = node
        if (node.id !== undefined && node.id !== null)
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)])
    }
}
