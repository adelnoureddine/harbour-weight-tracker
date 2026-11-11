import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Database.js" as Database
import "../js/utils.js" as Utils

/*
 * Adds a weight, or edits one (metricCode >= 0). The day can be chosen, so a weight
 * can be added afterwards; version 1.3 always used today.
 */
Dialog {
    id: dialog

    allowedOrientations: Orientation.All

    property int profileId: -1
    property int metricCode: -1
    property date selectedDate: new Date()

    readonly property bool editing: metricCode >= 0
    // "70." while typing is 70.
    readonly property real typedValue: Database.parseNumber(valueField.text.replace(/[.,]$/, ""))
    readonly property bool inRange: !isNaN(typedValue) && typedValue >= Database.WEIGHT_MIN
                                    && typedValue <= Database.WEIGHT_MAX
    readonly property bool inFuture: Utils.daysBetween(new Date(), selectedDate) > 0
    // The weight before this one, to type the new one against: a slip such as 665 for
    // 66.5 stands out next to it.
    property string contextText: ""

    canAccept: profileId >= 0 && inRange && !inFuture

    onAccepted: {
        var day = Utils.toLocalDateString(selectedDate);
        if (editing) {
            Database.updateWeight(profileId, metricCode, day, typedValue);
        } else {
            Database.addWeight(profileId, day, typedValue);
        }
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
                title: dialog.editing ? qsTr("Edit weight") : qsTr("Add weight")
                acceptText: qsTr("Save")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                TextField {
                    id: valueField
                    width: parent.width
                    //: Field label: the weight, in kilograms
                    label: qsTr("Weight (kg)")
                    placeholderText: label
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    // The old pattern was [\.|,], which also accepted a literal pipe.
                    validator: RegExpValidator { regExp: /^\d{1,3}([.,]\d{0,2})?$/ }
                    focus: true
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: dialog.canAccept
                    EnterKey.onClicked: dialog.accept()
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: text !== "" && (valueField.text === "" || dialog.inRange)
                    text: dialog.contextText
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: valueField.text !== "" && !dialog.inRange
                    wrapMode: Text.Wrap
                    //: Under the weight field; %1 and %2 are the lowest and highest weight accepted
                    text: qsTr("Enter a weight between %1 and %2").arg(Utils.kg(Database.WEIGHT_MIN))
                                                                  .arg(Utils.kg(Database.WEIGHT_MAX))
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                }
            }

            ValueButton {
                id: dateButton
                label: qsTr("Date")
                value: Utils.dayTitle(Utils.toLocalDateString(dialog.selectedDate))
                onClicked: {
                    var picker = pageStack.push("Sailfish.Silica.DatePickerDialog", { date: dialog.selectedDate });
                    picker.accepted.connect(function () {
                        dialog.selectedDate = picker.date;
                    });
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: dialog.inFuture
                wrapMode: Text.Wrap
                text: qsTr("This date is in the future.")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
            }
        }

        VerticalScrollDecorator {}
    }

    // Once. Again on PageStatus.Active would overwrite what was typed whenever the user
    // comes back from the date picker.
    Component.onCompleted: {
        if (editing) {
            var entry = Database.weight(profileId, metricCode);
            if (entry) {
                valueField.text = Utils.formatInput(entry.value);
                var day = Utils.fromLocalDateString(entry.date);
                if (day !== null) {
                    selectedDate = day;
                }
            }
        } else if (profileId >= 0) {
            var last = Database.latestWeight(profileId);
            //: The latest weight, to type a new one against: %1 is the weight, %2 its date
            contextText = last ? qsTr("Last: %1, %2").arg(Utils.kg(last.value)).arg(Utils.formatDate(last.date)) : "";
        }
    }
}

// vim:et:ts=4:sw=4
