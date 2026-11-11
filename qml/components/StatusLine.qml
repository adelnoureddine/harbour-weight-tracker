import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * What the last action of a section did ("Saved to ..."), or why it failed, under it.
 */
Row {
    id: line

    property string message: ""
    property bool isError: false

    width: parent ? parent.width : 0
    visible: message !== ""
    spacing: Theme.paddingMedium

    Icon {
        id: icon
        source: line.isError ? "image://theme/icon-s-warning" : "image://theme/icon-s-accept"
        color: line.isError ? Theme.errorColor : Theme.highlightColor
    }
    Label {
        width: parent.width - icon.width - parent.spacing
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: Text.WrapAnywhere
        text: line.message
        font.pixelSize: Theme.fontSizeExtraSmall
        color: line.isError ? Theme.errorColor : Theme.highlightColor
    }
}

// vim:et:ts=4:sw=4
