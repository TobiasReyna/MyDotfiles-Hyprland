pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var history: []
    property var popups: []
    property bool dnd: false

    readonly property int maxHistory: 50
    readonly property int maxPopups: 4
    readonly property int unreadCount: history.length

    readonly property bool hasCritical: {
        for (let i = 0; i < history.length; i++) {
            if (history[i] && history[i].isCritical)
                return true
        }
        return false
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true

        onNotification: function(notification) {
            root._handleNotification(notification)
        }
    }

    function _formatClock(dateObj) {
        const hh = String(dateObj.getHours()).padStart(2, "0")
        const mm = String(dateObj.getMinutes()).padStart(2, "0")
        return hh + ":" + mm
    }

    function formatTimeLabel(timestampMs) {
        if (!timestampMs)
            return ""
        const diffSec = Math.max(0, Math.floor((Date.now() - timestampMs) / 1000))
        if (diffSec < 60)
            return "Ahora"
        const diffMin = Math.floor(diffSec / 60)
        if (diffMin < 60)
            return "hace " + diffMin + "m"
        return _formatClock(new Date(timestampMs))
    }

    function resolveIconSource(item) {
        if (!item)
            return ""
        if (item.image && item.image !== "")
            return item.image
        const icon = item.appIcon || ""
        if (icon === "")
            return ""
        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("image://"))
            return icon
        return Quickshell.iconPath(icon, true)
    }

    function _extractActions(notification) {
        const out = []
        const raw = notification ? notification.actions : null
        if (!raw || typeof raw.length !== "number")
            return out
        for (let i = 0; i < raw.length; i++) {
            const act = raw[i]
            if (!act)
                continue
            const label = String(act.text || act.identifier || "").trim()
            if (label === "")
                continue
            out.push({
                identifier: String(act.identifier || ""),
                text: label,
                actionObj: act
            })
        }
        return out
    }

    function _handleNotification(notification) {
        if (!notification)
            return

        // Mantener vivo el objeto Notification para acciones e imágenes adjuntas
        notification.tracked = true

        const isCrit = notification.urgency === NotificationUrgency.Critical
        const rawTimeout = Number(notification.expireTimeout || 0)
        let timeoutMs = isCrit ? 9000 : 5000
        if (rawTimeout > 0)
            timeoutMs = Math.max(2000, Math.min(30000, Math.round(rawTimeout * 1000)))

        const now = new Date()
        const entry = {
            id: notification.id,
            appName: String(notification.appName || "Sistema"),
            appIcon: String(notification.appIcon || ""),
            image: String(notification.image || ""),
            summary: String(notification.summary || "Notificación"),
            body: String(notification.body || ""),
            urgency: notification.urgency,
            isCritical: isCrit,
            timestamp: now.getTime(),
            timeText: _formatClock(now),
            timeoutMs: timeoutMs,
            actions: _extractActions(notification),
            notif: notification
        }

        // Reemplazar si ya existe el mismo ID en historial; si no, insertar arriba
        const nextHistory = history.filter(function(item) { return item.id !== entry.id })
        nextHistory.unshift(entry)
        while (nextHistory.length > maxHistory) {
            const evicted = nextHistory.pop()
            if (evicted && evicted.notif) {
                try { evicted.notif.tracked = false } catch (e) {}
            }
        }
        history = nextHistory

        // Mostrar toast si DND está desactivado (o si es urgencia crítica)
        if (!dnd || isCrit) {
            const nextPopups = popups.filter(function(item) { return item.id !== entry.id })
            nextPopups.unshift(entry)
            while (nextPopups.length > maxPopups)
                nextPopups.pop()
            popups = nextPopups
        }
    }

    function dismissPopup(id) {
        popups = popups.filter(function(item) { return item.id !== id })
    }

    function removeFromHistory(id) {
        const target = history.find(function(item) { return item.id === id })
        popups = popups.filter(function(item) { return item.id !== id })
        history = history.filter(function(item) { return item.id !== id })
        if (target && target.notif) {
            try { target.notif.dismiss() } catch (e) {}
        }
    }

    function clearAll() {
        const old = history
        popups = []
        history = []
        for (let i = 0; i < old.length; i++) {
            if (old[i] && old[i].notif) {
                try { old[i].notif.dismiss() } catch (e) {}
            }
        }
    }

    function toggleDnd() {
        dnd = !dnd
        if (dnd) {
            // Al activar DND ocultar toasts no críticos visibles
            popups = popups.filter(function(item) { return item.isCritical })
        }
    }

    function invokeAction(notif, action) {
        if (!action)
            return
        try {
            action.invoke()
        } catch (e) {}
        if (notif) {
            dismissPopup(notif.id)
            if (!notif.resident)
                removeFromHistory(notif.id)
        }
    }
}
