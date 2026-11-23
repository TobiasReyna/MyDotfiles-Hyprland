import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "wallpaper"
    cardWidth: 740
    cardMaxHeight: 540
    alignment: "center"

    property var wallpapers: []
    property bool loading: false

    readonly property string _scriptResolver:
        "if [ -x \"$HOME/.local/bin/wallpaper.sh\" ]; then echo \"$HOME/.local/bin/wallpaper.sh\"; " +
        "elif [ -x \"$HOME/dotfiles/scripts/wallpaper.sh\" ]; then echo \"$HOME/dotfiles/scripts/wallpaper.sh\"; fi"

    onOpened: refreshList()

    function refreshList() {
        if (listProc.running)
            return
        loading = true
        listProc.running = true
    }

    function applyWallpaper(path) {
        if (!path)
            return
        Quickshell.execDetached([
            "sh", "-c",
            "s=$(" + _scriptResolver + "); [ -n \"$s\" ] && \"$s\" \"$1\"",
            "_", path
        ])
        PopupState.close()
    }

    function applyRandom() {
        Quickshell.execDetached([
            "sh", "-c",
            "s=$(" + _scriptResolver + "); [ -n \"$s\" ] && \"$s\" --random"
        ])
        PopupState.close()
    }

    Process {
        id: listProc
        command: [
            "sh", "-c",
            "s=$(" + root._scriptResolver + "); " +
            "if [ -n \"$s\" ]; then " +
            "  out=$(\"$s\" --list); " +
            "  if [ \"$out\" = '[]' ] && [ -d \"$HOME/Pictures/Wallpapers\" ]; then " +
            "    \"$s\" --list \"$HOME/Pictures/Wallpapers\"; " +
            "  else printf '%s\\n' \"$out\"; fi; " +
            "else echo '[]'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse((text || "[]").trim())
                    root.wallpapers = Array.isArray(parsed) ? parsed : []
                } catch (e) {
                    root.wallpapers = []
                }
                root.loading = false
            }
        }
        onExited: root.loading = false
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        // Cabecera
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialIcon {
                icon: "wallpaper"
                size: 20
                color: ThemeColors.primary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Selector de Wallpapers"
                    font.family: "Inter"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: ThemeColors.colorOnSurface
                }

                Text {
                    text: root.loading
                        ? "Cargando galería..."
                        : (root.wallpapers.length + " imagen(es) · Genera paleta Material You al instante")
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: ThemeColors.colorOnSurfaceVariant
                }
            }

            PillButton {
                icon: "shuffle"
                label: "Aleatorio"
                active: true
                onClicked: root.applyRandom()
            }

            PillButton {
                icon: "refresh"
                onClicked: root.refreshList()
            }
        }

        // Grilla de miniaturas
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 430

            GridView {
                id: grid
                anchors.fill: parent
                clip: true
                cellWidth: Math.floor(width / 3)
                cellHeight: 146
                model: root.wallpapers

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Item {
                    id: tile
                    required property var modelData
                    readonly property bool isActive: modelData.active === true || modelData.path === ThemeColors.wallpaperPath

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 14
                        clip: true
                        color: ThemeColors.surfaceContainerLow
                        border.width: tile.isActive ? 2 : 1
                        border.color: tile.isActive
                            ? ThemeColors.primary
                            : (tileMouse.containsMouse ? ThemeColors.secondary : ThemeColors.outlineVariant)

                        Image {
                            anchors.fill: parent
                            source: "file://" + tile.modelData.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 320
                            sourceSize.height: 200
                        }

                        // Etiqueta inferior translúcida
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 28
                            color: Qt.rgba(ThemeColors.surfaceContainerLowest.r, ThemeColors.surfaceContainerLowest.g, ThemeColors.surfaceContainerLowest.b, 0.78)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 4

                                MaterialIcon {
                                    visible: tile.isActive
                                    icon: "check_circle"
                                    size: 14
                                    filled: true
                                    color: ThemeColors.primary
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: tile.modelData.name || ""
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    color: ThemeColors.colorOnSurface
                                    elide: Text.ElideMiddle
                                }
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyWallpaper(tile.modelData.path)
                        }
                    }
                }
            }

            // Estado vacío amigable
            ColumnLayout {
                visible: !root.loading && root.wallpapers.length === 0
                anchors.centerIn: parent
                spacing: 8

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "photo_library"
                    size: 36
                    color: ThemeColors.colorOnSurfaceVariant
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No hay wallpapers todavía"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: ThemeColors.colorOnSurface
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Agregá imágenes en ~/dotfiles/wallpapers o ~/Pictures/Wallpapers"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: ThemeColors.colorOnSurfaceVariant
                }
            }
        }
    }
}
