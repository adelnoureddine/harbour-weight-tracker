import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/bmi.js" as Bmi

/*
 * Where a BMI falls: the categories as coloured bands from 15 to 40, in Health's band
 * colours, with a marker at the value and the limits written under them.
 */
Item {
    id: bmiScale

    property var bmi: null
    // The limits written under the bar.
    readonly property var ticks: [18.5, 25, 30, 35]

    function xOf(value) {
        var clamped = Math.max(Bmi.SCALE_MIN, Math.min(Bmi.SCALE_MAX, value));
        return (clamped - Bmi.SCALE_MIN) / (Bmi.SCALE_MAX - Bmi.SCALE_MIN) * width;
    }

    width: parent ? parent.width : 0
    height: marker.height + Theme.paddingSmall + tickRow.height

    // [from, to, category]: obesity classes share the red band.
    Repeater {
        model: [
            [Bmi.SCALE_MIN, 18.5, 0],
            [18.5, 25, 1],
            [25, 30, 2],
            [30, Bmi.SCALE_MAX, 3]
        ]

        Rectangle {
            x: bmiScale.xOf(modelData[0])
            width: bmiScale.xOf(modelData[1]) - x
            height: Theme.paddingMedium
            anchors.verticalCenter: marker.verticalCenter
            color: Bmi.categoryColor(modelData[2])
            opacity: 0.8
        }
    }

    Rectangle {
        id: marker
        visible: bmiScale.bmi !== null
        x: Math.max(0, Math.min(bmiScale.width - width, bmiScale.xOf(bmiScale.bmi === null ? 0 : bmiScale.bmi) - width / 2))
        width: Theme.paddingLarge + Theme.paddingSmall
        height: width
        radius: width / 2
        color: Theme.primaryColor
        border.width: Math.max(2, Math.round(2 * Theme.pixelRatio))
        border.color: Theme.rgba(Theme.highlightDimmerColor, 0.8)
    }

    Item {
        id: tickRow
        y: marker.height + Theme.paddingSmall
        width: parent.width
        height: tickMetrics.height

        Label {
            id: tickMetrics
            visible: false
            text: "0"
            font.pixelSize: Theme.fontSizeTiny
        }

        Repeater {
            model: bmiScale.ticks

            Label {
                x: Math.max(0, Math.min(bmiScale.width - width, bmiScale.xOf(modelData) - width / 2))
                text: appWindow.formatMeasure(modelData)
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
            }
        }
    }
}

// vim:et:ts=4:sw=4
