import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

PopupSurface {
    id: root

    popupId: "calendar"
    cardWidth: 320
    cardMaxHeight: 380
    alignment: "top-center"

    property int displayYear: (new Date()).getFullYear()
    property int displayMonth: (new Date()).getMonth()

    readonly property var _monthsFullEs: [
        "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ]
    readonly property var _weekdaysShortEs: ["Lu", "Ma", "Mi", "Ju", "Vi", "Sá", "Do"]

    readonly property var calendarCells: {
        const firstDay = new Date(displayYear, displayMonth, 1)
        const startOffset = (firstDay.getDay() + 6) % 7 // Lunes = 0
        const daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()
        const today = new Date()
        const isThisMonth = today.getFullYear() === displayYear && today.getMonth() === displayMonth

        const cells = []
        for (let i = 0; i < startOffset; i++)
            cells.push({ day: "", isToday: false })
        for (let d = 1; d <= daysInMonth; d++)
            cells.push({ day: String(d), isToday: isThisMonth && d === today.getDate() })
        return cells
    }

    onOpened: {
        const now = new Date()
        displayYear = now.getFullYear()
        displayMonth = now.getMonth()
    }

    function shiftMonth(delta) {
        const dt = new Date(displayYear, displayMonth + delta, 1)
        displayYear = dt.getFullYear()
        displayMonth = dt.getMonth()
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            PillButton {
                icon: "chevron_left"
                onClicked: root.shiftMonth(-1)
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root._monthsFullEs[root.displayMonth] + " " + root.displayYear
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: ThemeColors.colorOnSurface
            }

            PillButton {
                icon: "chevron_right"
                onClicked: root.shiftMonth(1)
            }
        }

        // Encabezado de días de la semana
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 4

            Repeater {
                model: root._weekdaysShortEs
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: ThemeColors.colorOnSurfaceVariant
                }
            }
        }

        // Días del mes
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 4
            rowSpacing: 4

            Repeater {
                model: root.calendarCells

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 16
                    color: modelData.isToday ? ThemeColors.primary : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: modelData.isToday ? Font.Bold : Font.Normal
                        color: modelData.isToday ? ThemeColors.colorOnPrimary : ThemeColors.colorOnSurface
                    }
                }
            }
        }
    }
}
