import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../components"
import "../services"

PopupSurface {
    id: root

    popupId: "network"
    cardWidth: 380
    cardMaxHeight: 540
    alignment: "top-right"

    // 0 = Wi-Fi, 1 = Bluetooth
    property int activeTab: 0
    property string passwordTargetSsid: ""

    onOpened: {
        passwordTargetSsid = ""
        NetworkService.refreshStatus()
        NetworkService.scan(false)
        BluetoothService.refresh()
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        // Cabecera + selector de pestañas (Wi-Fi / Bluetooth)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 18
                color: ThemeColors.surfaceContainerLow

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Wi-Fi", icon: NetworkService.barIcon },
                            { label: "Bluetooth", icon: BluetoothService.barIcon }
                        ]

                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 15
                            color: root.activeTab === index ? ThemeColors.primaryContainer : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialIcon {
                                    icon: modelData.icon
                                    size: 16
                                    filled: root.activeTab === index
                                    color: root.activeTab === index ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                                }

                                Text {
                                    text: modelData.label
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    font.weight: root.activeTab === index ? Font.DemiBold : Font.Medium
                                    color: root.activeTab === index ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeTab = index
                                    root.passwordTargetSsid = ""
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // PESTAÑA 0: WI-FI
        // =====================================================================
        ColumnLayout {
            visible: root.activeTab === 0
            Layout.fillWidth: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToggleTile {
                    Layout.fillWidth: true
                    icon: NetworkService.barIcon
                    title: "Wi-Fi"
                    subtitle: NetworkService.activeSsid !== ""
                        ? NetworkService.activeSsid + " (" + NetworkService.activeSignal + "%)"
                        : (NetworkService.wifiEnabled ? "Sin conexión" : "Desactivado")
                    active: NetworkService.wifiEnabled
                    busy: NetworkService.busy
                    onClicked: NetworkService.toggleWifi()
                }

                PillButton {
                    icon: "refresh"
                    label: NetworkService.scanning ? "…" : "Escanear"
                    active: NetworkService.scanning
                    onClicked: NetworkService.scan(true)
                }
            }

            // Mensaje de estado / error
            Text {
                visible: NetworkService.statusMessage !== ""
                Layout.fillWidth: true
                text: NetworkService.statusMessage
                font.family: "Inter"
                font.pixelSize: 11
                color: ThemeColors.primary
                wrapMode: Text.WordWrap
            }

            // Campo de contraseña inline para redes protegidas
            Rectangle {
                visible: root.passwordTargetSsid !== ""
                Layout.fillWidth: true
                implicitHeight: pwdCol.implicitHeight + 16
                radius: 14
                color: ThemeColors.surfaceContainerHigh
                border.width: 1
                border.color: ThemeColors.primary

                ColumnLayout {
                    id: pwdCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: "Contraseña para «" + root.passwordTargetSsid + "»"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: ThemeColors.colorOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        TextField {
                            id: pwdField
                            Layout.fillWidth: true
                            echoMode: TextInput.Password
                            placeholderText: "Ingresá la clave Wi-Fi..."
                            color: ThemeColors.colorOnSurface
                            placeholderTextColor: ThemeColors.colorOnSurfaceVariant
                            font.family: "Inter"
                            font.pixelSize: 12
                            background: Rectangle {
                                radius: 10
                                color: ThemeColors.surfaceContainerLow
                                border.width: 1
                                border.color: pwdField.activeFocus ? ThemeColors.primary : ThemeColors.outlineVariant
                            }
                            onAccepted: {
                                NetworkService.connect(root.passwordTargetSsid, pwdField.text)
                                pwdField.text = ""
                                root.passwordTargetSsid = ""
                            }
                        }

                        PillButton {
                            icon: "check"
                            active: true
                            onClicked: {
                                NetworkService.connect(root.passwordTargetSsid, pwdField.text)
                                pwdField.text = ""
                                root.passwordTargetSsid = ""
                            }
                        }

                        PillButton {
                            icon: "close"
                            onClicked: {
                                pwdField.text = ""
                                root.passwordTargetSsid = ""
                            }
                        }
                    }
                }
            }

            // Lista scrollable de redes Wi-Fi
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(290, Math.max(80, NetworkService.networks.length * 46))
                clip: true

                ListView {
                    model: NetworkService.networks
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 42
                        radius: 12
                        color: modelData.active
                            ? Qt.rgba(ThemeColors.primaryContainer.r, ThemeColors.primaryContainer.g, ThemeColors.primaryContainer.b, 0.75)
                            : (netHover.containsMouse ? ThemeColors.surfaceContainerHigh : ThemeColors.surfaceContainerLow)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            MaterialIcon {
                                icon: modelData.signal >= 75 ? "signal_wifi_4_bar"
                                    : modelData.signal >= 50 ? "network_wifi_3_bar"
                                    : modelData.signal >= 25 ? "network_wifi_2_bar"
                                    : "network_wifi_1_bar"
                                size: 17
                                color: modelData.active ? ThemeColors.colorOnPrimaryContainer : ThemeColors.primary
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                color: modelData.active ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                                elide: Text.ElideRight
                            }

                            MaterialIcon {
                                visible: modelData.secured
                                icon: "lock"
                                size: 14
                                color: modelData.active ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                            }

                            Text {
                                text: modelData.active ? "Desconectar" : (modelData.signal + "%")
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: modelData.active ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                            }
                        }

                        MouseArea {
                            id: netHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.active) {
                                    NetworkService.disconnect()
                                } else if (modelData.secured) {
                                    root.passwordTargetSsid = modelData.ssid
                                    pwdField.text = ""
                                    pwdField.forceActiveFocus()
                                } else {
                                    NetworkService.connect(modelData.ssid, "")
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: NetworkService.wifiEnabled && NetworkService.networks.length === 0 && !NetworkService.scanning
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "No se encontraron redes. Tocá «Escanear»."
                font.family: "Inter"
                font.pixelSize: 12
                color: ThemeColors.colorOnSurfaceVariant
            }
        }

        // =====================================================================
        // PESTAÑA 1: BLUETOOTH
        // =====================================================================
        ColumnLayout {
            visible: root.activeTab === 1
            Layout.fillWidth: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToggleTile {
                    Layout.fillWidth: true
                    icon: BluetoothService.barIcon
                    title: "Bluetooth"
                    subtitle: BluetoothService.powered
                        ? (BluetoothService.connectedCount > 0 ? BluetoothService.connectedCount + " conectado(s)" : "Encendido")
                        : "Apagado"
                    active: BluetoothService.powered
                    busy: BluetoothService.busy
                    onClicked: BluetoothService.togglePower()
                }

                PillButton {
                    icon: "bluetooth_searching"
                    label: BluetoothService.scanning ? "…" : "Escanear"
                    active: BluetoothService.scanning
                    onClicked: BluetoothService.scan()
                }
            }

            Text {
                visible: BluetoothService.statusMessage !== ""
                Layout.fillWidth: true
                text: BluetoothService.statusMessage
                font.family: "Inter"
                font.pixelSize: 11
                color: ThemeColors.primary
                wrapMode: Text.WordWrap
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(290, Math.max(80, BluetoothService.devices.length * 48))
                clip: true

                ListView {
                    model: BluetoothService.devices
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 44
                        radius: 12
                        color: modelData.connected
                            ? Qt.rgba(ThemeColors.primaryContainer.r, ThemeColors.primaryContainer.g, ThemeColors.primaryContainer.b, 0.75)
                            : (btHover.containsMouse ? ThemeColors.surfaceContainerHigh : ThemeColors.surfaceContainerLow)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            MaterialIcon {
                                icon: modelData.connected ? "bluetooth_connected" : "bluetooth"
                                size: 17
                                color: modelData.connected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.primary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                    color: modelData.connected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurface
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.connected ? "Conectado" : (modelData.paired ? "Emparejado" : modelData.mac)
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    color: modelData.connected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.colorOnSurfaceVariant
                                }
                            }

                            Text {
                                text: modelData.connected ? "Desconectar" : "Conectar"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: modelData.connected ? ThemeColors.colorOnPrimaryContainer : ThemeColors.primary
                            }
                        }

                        MouseArea {
                            id: btHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BluetoothService.toggleDevice(modelData.mac, modelData.connected)
                        }
                    }
                }
            }

            Text {
                visible: BluetoothService.powered && BluetoothService.devices.length === 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Sin dispositivos Bluetooth encontrados."
                font.family: "Inter"
                font.pixelSize: 12
                color: ThemeColors.colorOnSurfaceVariant
            }
        }
    }
}
