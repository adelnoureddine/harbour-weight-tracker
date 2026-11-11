import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * A link on a card row, opened in the browser: an icon, a title and a detail line.
 * Rows rather than buttons, as in Health's About page.
 */
BackgroundItem {
    id: linkRow

    property string title
    property string detail
    property string url
    property string icon

    width: parent ? parent.width : 0
    height: Math.max(Theme.itemSizeMedium, linkText.height + 2 * Theme.paddingMedium)
    highlightedColor: "transparent"
    onClicked: Qt.openUrlExternally(url)

    CardBackground {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        height: parent.height
        highlighted: linkRow.highlighted
    }

    Icon {
        id: linkIcon
        x: Theme.horizontalPageMargin + Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        source: linkRow.icon
        highlighted: linkRow.highlighted
    }

    Column {
        id: linkText
        anchors.left: linkIcon.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin + Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter

        Label {
            width: parent.width
            wrapMode: Text.Wrap
            text: linkRow.title
            color: linkRow.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            text: linkRow.detail
            font.pixelSize: Theme.fontSizeExtraSmall
            color: linkRow.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }
}

// vim:et:ts=4:sw=4
