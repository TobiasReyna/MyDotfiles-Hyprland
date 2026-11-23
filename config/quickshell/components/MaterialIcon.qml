import QtQuick
import ".."

Text {
    id: root

    property string icon: ""
    property real size: 18
    property bool filled: false
    property int weight: 400

    text: icon
    color: ThemeColors.colorOnSurface
    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.variableAxes: ({
        "FILL": filled ? 1 : 0,
        "wght": weight,
        "GRAD": 0,
        "opsz": Math.max(20, Math.min(48, Math.round(size)))
    })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
