import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "media"
    cardWidth: 386
    cardMaxHeight: 420
    alignment: "top-center"

    property int selectedPlayerIndex: 0
    property real displayPosition: 0

    readonly property var players: Mpris.players ? Mpris.players.values : []

    readonly property var activePlayer: {
        if (players.length === 0)
            return null
        if (selectedPlayerIndex >= 0 && selectedPlayerIndex < players.length)
            return players[selectedPlayerIndex]
        return players[0]
    }

    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property real trackLength: (activePlayer && activePlayer.length > 0) ? activePlayer.length : 0
    readonly property string artUrl: (activePlayer && activePlayer.trackArtUrl) ? String(activePlayer.trackArtUrl) : ""

    // Activa Cava únicamente mientras el popup está abierto y hay audio sonando (0% CPU en reposo)
    Binding {
        target: CavaService
        property: "active"
        value: root.isOpen && root.isPlaying
    }

    function formatTime(secs) {
        if (!secs || secs < 0 || isNaN(secs))
            return "0:00"
        const total = Math.floor(secs)
        const h = Math.floor(total / 3600)
        const m = Math.floor((total % 3600) / 60)
        const s = total % 60
        const ss = String(s).padStart(2, "0")
        if (h > 0)
            return h + ":" + String(m).padStart(2, "0") + ":" + ss
        return m + ":" + ss
    }

    function syncPosition() {
        if (!activePlayer) {
            displayPosition = 0
            return
        }
        if (!progressSlider.pressed)
            displayPosition = Math.max(0, activePlayer.position || 0)
    }

    function pickBestPlayer() {
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].playbackState === MprisPlaybackState.Playing) {
                selectedPlayerIndex = i
                return
            }
        }
        selectedPlayerIndex = 0
    }

    function cycleLoop() {
        if (!activePlayer || !activePlayer.loopSupported)
            return
        if (activePlayer.loopState === MprisLoopState.None)
            activePlayer.loopState = MprisLoopState.Playlist
        else if (activePlayer.loopState === MprisLoopState.Playlist)
            activePlayer.loopState = MprisLoopState.Track
        else
            activePlayer.loopState = MprisLoopState.None
    }

    onOpened: {
        pickBestPlayer()
        syncPosition()
    }

    onActivePlayerChanged: syncPosition()

    // Actualiza posición cada 1s solo mientras el popup está abierto y reproduciendo
    Timer {
        interval: 1000
        running: root.isOpen && root.isPlaying
        repeat: true
        onTriggered: {
            if (root.activePlayer) {
                root.activePlayer.positionChanged()
                root.syncPosition()
            }
        }
    }

    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onPositionChanged() { root.syncPosition() }
        function onTrackTitleChanged() { root.syncPosition() }
    }

    // Contenedor raíz con fondo difuminado de carátula detrás del contenido
    Item {
        width: parent.width
        implicitHeight: mainCol.implicitHeight

        // Fondo reactivo con carátula difuminada + scrim oscuro para legibilidad
        ClippingRectangle {
            visible: root.activePlayer !== null && root.artUrl !== ""
            anchors.fill: parent
            anchors.margins: -16
            radius: 22
            color: "transparent"

            Image {
                id: backdropImg
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: false
            }

            MultiEffect {
                anchors.fill: backdropImg
                source: backdropImg
                blurEnabled: true
                blurMax: 32
                blur: 0.72
                saturation: 0.15
                opacity: 0.28
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(ThemeColors.surfaceContainer.r, ThemeColors.surfaceContainer.g, ThemeColors.surfaceContainer.b, 0.55)
                    }
                    GradientStop {
                        position: 0.65
                        color: Qt.rgba(ThemeColors.surfaceContainer.r, ThemeColors.surfaceContainer.g, ThemeColors.surfaceContainer.b, 0.84)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(ThemeColors.surfaceContainer.r, ThemeColors.surfaceContainer.g, ThemeColors.surfaceContainer.b, 0.95)
                    }
                }
            }
        }

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 12

            // =================================================================
            // Selector de reproductores (visible si hay más de 1 reproductor)
            // =================================================================
            RowLayout {
                visible: root.players.length > 1
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.players

                    delegate: Rectangle {
                        id: playerChip
                        required property int index
                        required property var modelData
                        readonly property bool isCurrent: root.activePlayer === modelData

                        implicitHeight: 26
                        implicitWidth: chipRow.implicitWidth + 16
                        radius: 13
                        color: isCurrent
                            ? ThemeColors.primaryContainer
                            : (chipMouse.containsMouse ? ThemeColors.surfaceContainerHigh : Qt.rgba(ThemeColors.surfaceContainerLow.r, ThemeColors.surfaceContainerLow.g, ThemeColors.surfaceContainerLow.b, 0.78))
                        border.width: 1
                        border.color: isCurrent ? ThemeColors.primary : "transparent"

                        Behavior on color { ColorAnimation { duration: 130 } }

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 5

                            MaterialIcon {
                                icon: playerChip.modelData.playbackState === MprisPlaybackState.Playing ? "graphic_eq" : "music_note"
                                size: 13
                                color: playerChip.isCurrent ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                            }

                            Text {
                                text: playerChip.modelData.identity || "Reproductor"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: playerChip.isCurrent ? Font.DemiBold : Font.Normal
                                color: playerChip.isCurrent ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                                elide: Text.ElideRight
                                Layout.maximumWidth: 110
                            }
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedPlayerIndex = playerChip.index
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // =================================================================
            // Estado activo: carátula, metadatos, progreso, controles y Cava
            // =================================================================
            ColumnLayout {
                visible: root.activePlayer !== null
                Layout.fillWidth: true
                spacing: 12

                // Cuerpo principal: Carátula 88x88 + metadatos
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    ClippingRectangle {
                        Layout.preferredWidth: 88
                        Layout.preferredHeight: 88
                        radius: 16
                        color: ThemeColors.primaryContainer
                        border.width: 1
                        border.color: Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.5)

                        Image {
                            id: coverImg
                            visible: root.artUrl !== "" && status === Image.Ready
                            anchors.fill: parent
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                        }

                        MaterialIcon {
                            visible: !coverImg.visible
                            anchors.centerIn: parent
                            icon: "music_note"
                            size: 34
                            filled: true
                            color: ThemeColors.colorOnPrimaryContainer
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        // Badge del reproductor
                        Rectangle {
                            visible: (root.activePlayer && root.activePlayer.identity) ? true : false
                            implicitHeight: 20
                            implicitWidth: badgeText.implicitWidth + 14
                            radius: 10
                            color: Qt.rgba(ThemeColors.primaryContainer.r, ThemeColors.primaryContainer.g, ThemeColors.primaryContainer.b, 0.72)

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: root.activePlayer ? (root.activePlayer.identity || "") : ""
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: ThemeColors.colorOnPrimaryContainer
                            }
                        }

                        // Título de la canción
                        Text {
                            Layout.fillWidth: true
                            text: (root.activePlayer && root.activePlayer.trackTitle) ? root.activePlayer.trackTitle : "Sin título"
                            font.family: "Inter"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: ThemeColors.colorOnSurface
                            elide: Text.ElideRight
                        }

                        // Artista
                        Text {
                            visible: text !== ""
                            Layout.fillWidth: true
                            text: (root.activePlayer && root.activePlayer.trackArtist) ? root.activePlayer.trackArtist : ""
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: ThemeColors.primary
                            elide: Text.ElideRight
                        }

                        // Álbum
                        Text {
                            visible: text !== ""
                            Layout.fillWidth: true
                            text: (root.activePlayer && root.activePlayer.trackAlbum) ? root.activePlayer.trackAlbum : ""
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: ThemeColors.colorOnSurfaceVariant
                            elide: Text.ElideRight
                        }
                    }
                }

                // Barra de progreso interactiva + tiempos mm:ss
                ColumnLayout {
                    visible: root.trackLength > 0
                    Layout.fillWidth: true
                    spacing: 2

                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        from: 0
                        to: Math.max(1, root.trackLength)
                        value: Math.min(to, root.displayPosition)
                        enabled: root.activePlayer !== null && root.activePlayer.canSeek

                        onMoved: {
                            root.displayPosition = value
                            if (root.activePlayer && root.activePlayer.canSeek)
                                root.activePlayer.position = value
                        }

                        background: Rectangle {
                            x: progressSlider.leftPadding
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            width: progressSlider.availableWidth
                            height: 5
                            radius: 2.5
                            color: Qt.rgba(ThemeColors.surfaceContainerHighest.r, ThemeColors.surfaceContainerHighest.g, ThemeColors.surfaceContainerHighest.b, 0.85)

                            Rectangle {
                                width: progressSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2.5
                                color: ThemeColors.primary
                            }
                        }

                        handle: Rectangle {
                            x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            width: progressSlider.hovered || progressSlider.pressed ? 14 : 10
                            height: width
                            radius: width / 2
                            color: ThemeColors.primary
                            border.width: 2
                            border.color: ThemeColors.colorOnPrimary

                            Behavior on width { NumberAnimation { duration: 100 } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.formatTime(root.displayPosition)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: ThemeColors.colorOnSurfaceVariant
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.formatTime(root.trackLength)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: ThemeColors.colorOnSurfaceVariant
                        }
                    }
                }

                // Controles de reproducción centrados
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    // Shuffle (discreto si soportado)
                    Rectangle {
                        visible: root.activePlayer !== null && root.activePlayer.shuffleSupported
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: (root.activePlayer && root.activePlayer.shuffle)
                            ? ThemeColors.primaryContainer
                            : (shufMouse.containsMouse ? ThemeColors.surfaceContainerHigh : "transparent")

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "shuffle"
                            size: 17
                            color: (root.activePlayer && root.activePlayer.shuffle)
                                ? ThemeColors.colorOnPrimaryContainer
                                : ThemeColors.colorOnSurfaceVariant
                        }

                        MouseArea {
                            id: shufMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer)
                                    root.activePlayer.shuffle = !root.activePlayer.shuffle
                            }
                        }
                    }

                    // Anterior
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: prevMouse.containsMouse ? ThemeColors.surfaceContainerHigh : Qt.rgba(ThemeColors.surfaceContainerLow.r, ThemeColors.surfaceContainerLow.g, ThemeColors.surfaceContainerLow.b, 0.7)
                        opacity: (root.activePlayer && root.activePlayer.canGoPrevious) ? 1.0 : 0.4

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "skip_previous"
                            size: 22
                            filled: true
                            color: ThemeColors.colorOnSurface
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.activePlayer !== null && root.activePlayer.canGoPrevious
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (root.activePlayer)
                                    root.activePlayer.previous()
                            }
                        }
                    }

                    // Botón principal Play / Pause (Material 3 FAB destacado)
                    Rectangle {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        radius: root.isPlaying ? 16 : 23
                        color: playMouse.containsMouse ? Qt.lighter(ThemeColors.primary, 1.08) : ThemeColors.primary

                        Behavior on radius { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: root.isPlaying ? "pause" : "play_arrow"
                            size: 26
                            filled: true
                            color: ThemeColors.colorOnPrimary
                        }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer)
                                    root.activePlayer.togglePlaying()
                            }
                        }
                    }

                    // Siguiente
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: nextMouse.containsMouse ? ThemeColors.surfaceContainerHigh : Qt.rgba(ThemeColors.surfaceContainerLow.r, ThemeColors.surfaceContainerLow.g, ThemeColors.surfaceContainerLow.b, 0.7)
                        opacity: (root.activePlayer && root.activePlayer.canGoNext) ? 1.0 : 0.4

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "skip_next"
                            size: 22
                            filled: true
                            color: ThemeColors.colorOnSurface
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.activePlayer !== null && root.activePlayer.canGoNext
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (root.activePlayer)
                                    root.activePlayer.next()
                            }
                        }
                    }

                    // Repeat (discreto si soportado)
                    Rectangle {
                        visible: root.activePlayer !== null && root.activePlayer.loopSupported
                        readonly property bool loopActive: root.activePlayer !== null && root.activePlayer.loopState !== MprisLoopState.None
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: loopActive
                            ? ThemeColors.primaryContainer
                            : (loopMouse.containsMouse ? ThemeColors.surfaceContainerHigh : "transparent")

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: (root.activePlayer && root.activePlayer.loopState === MprisLoopState.Track) ? "repeat_one" : "repeat"
                            size: 17
                            color: parent.loopActive
                                ? ThemeColors.colorOnPrimaryContainer
                                : ThemeColors.colorOnSurfaceVariant
                        }

                        MouseArea {
                            id: loopMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cycleLoop()
                        }
                    }
                }

                // =============================================================
                // Visualizador estilo Cava (26 barras reactivas redondeadas)
                // =============================================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 14
                    color: Qt.rgba(
                        ThemeColors.surfaceContainerLowest.r,
                        ThemeColors.surfaceContainerLowest.g,
                        ThemeColors.surfaceContainerLowest.b,
                        0.62
                    )
                    border.width: 1
                    border.color: Qt.rgba(ThemeColors.outlineVariant.r, ThemeColors.outlineVariant.g, ThemeColors.outlineVariant.b, 0.35)

                    Row {
                        id: cavaRow
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        spacing: 4

                        Repeater {
                            model: CavaService.barCount

                            delegate: Item {
                                required property int index
                                readonly property real level: (CavaService.bars && index < CavaService.bars.length) ? CavaService.bars[index] : 0

                                width: Math.max(3, (cavaRow.width - (CavaService.barCount - 1) * cavaRow.spacing) / CavaService.barCount)
                                height: cavaRow.height

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(4, Math.round((parent.level / 100.0) * parent.height))
                                    radius: width / 2

                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: ThemeColors.primary }
                                        GradientStop { position: 1.0; color: ThemeColors.secondary }
                                    }

                                    Behavior on height {
                                        NumberAnimation { duration: 70; easing.type: Easing.OutQuad }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // Estado vacío (sin reproductores MPRIS activos)
            // =================================================================
            ColumnLayout {
                visible: root.activePlayer === null
                Layout.fillWidth: true
                Layout.topMargin: 18
                Layout.bottomMargin: 18
                spacing: 8

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "music_off"
                    size: 34
                    color: ThemeColors.colorOnSurfaceVariant
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Nada reproduciéndose"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: ThemeColors.colorOnSurface
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Iniciá música o video para controlar la reproducción aquí"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: ThemeColors.colorOnSurfaceVariant
                }
            }
        }
    }
}
