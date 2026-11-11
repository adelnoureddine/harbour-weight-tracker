import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Database.js" as Database
import "../js/utils.js" as Utils

/*
 * The weight a profile wants to reach, drawn as a line on the chart. An empty field
 * removes it.
 */
Dialog {
    id: dialog

    allowedOrientations: Orientation.All

    property int profileCode: -1

    readonly property real typedValue: Database.parseNumber(valueField.text.replace(/[.,]$/, ""))
    readonly property bool inRange: !isNaN(typedValue) && typedValue >= Database.WEIGHT_MIN
                                    && typedValue <= Database.WEIGHT_MAX

    canAccept: profileCode >= 0 && (valueField.text === "" || inRange)

    onAccepted: {
        Database.setTarget(profileCode, valueField.text === "" ? null : typedValue);
        appWindow.changed();
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Target weight")
                acceptText: qsTr("Save")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                TextField {
                    id: valueField
                    width: parent.width
                    label: qsTr("Target (kg)")
                    placeholderText: label
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: RegExpValidator { regExp: /^\d{1,3}([.,]\d{0,2})?$/ }
                    focus: true
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: dialog.canAccept
                    EnterKey.onClicked: dialog.accept()
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: valueField.text !== "" && !dialog.inRange
                    wrapMode: Text.Wrap
                    text: qsTr("Enter a weight between %1 and %2").arg(Utils.kg(Database.WEIGHT_MIN))
                                                                  .arg(Utils.kg(Database.WEIGHT_MAX))
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("The target is drawn as a line on the weight chart. Leave the field empty to remove it.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        var profile = Database.profile(profileCode);
        if (profile && profile.target !== null) {
            valueField.text = Utils.formatInput(profile.target);
        }
    }
}

// vim:et:ts=4:sw=4
