import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Database.js" as Database
import "../js/utils.js" as Utils

/*
 * Creates a profile (profileCode -1) or edits one. The birthday is saved as
 * "yyyy-MM-dd": version 1.3 saved the phone's date format, which it could not read
 * back, so editing a profile a second time required picking the birthday again.
 */
Dialog {
    id: dialog

    allowedOrientations: Orientation.All

    property int profileCode: -1
    // "yyyy-MM-dd", "" until one is picked.
    property string birthday: ""

    readonly property bool editing: profileCode >= 0
    readonly property real typedHeight: Database.parseNumber(heightField.text.replace(/[.,]$/, ""))
    readonly property bool heightInRange: !isNaN(typedHeight) && typedHeight >= Database.HEIGHT_MIN
                                          && typedHeight <= Database.HEIGHT_MAX

    canAccept: firstNameField.text.trim() !== "" && lastNameField.text.trim() !== ""
               && birthday !== "" && heightInRange

    onAccepted: {
        var profile = {
            firstName: firstNameField.text.trim(),
            lastName: lastNameField.text.trim(),
            gender: genderBox.currentIndex === 1 ? "M" : "F",
            birthday: birthday,
            height: typedHeight
        };
        if (editing) {
            Database.updateProfile(profileCode, profile);
            appWindow.changed();
        } else {
            appWindow.selectProfile(Database.addProfile(profile));
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader {
                title: dialog.editing ? qsTr("Edit profile") : qsTr("New profile")
                acceptText: qsTr("Save")
            }

            TextField {
                id: firstNameField
                width: parent.width
                label: qsTr("First name")
                placeholderText: label
                inputMethodHints: Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: lastNameField.focus = true
            }

            TextField {
                id: lastNameField
                width: parent.width
                label: qsTr("Last name")
                placeholderText: label
                inputMethodHints: Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: heightField.focus = true
            }

            ComboBox {
                id: genderBox
                width: parent.width
                label: qsTr("Gender")
                menu: ContextMenu {
                    MenuItem { text: qsTr("Female") }
                    MenuItem { text: qsTr("Male") }
                }
            }

            ValueButton {
                id: birthdayButton
                label: qsTr("Birthday")
                value: dialog.birthday !== "" ? Utils.longDate(dialog.birthday) : qsTr("Choose")
                valueColor: dialog.birthday !== "" ? Theme.highlightColor : Theme.errorColor
                onClicked: {
                    var initial = dialog.birthday !== "" ? Utils.fromLocalDateString(dialog.birthday)
                                                         : new Date(new Date().getFullYear() - 30, 0, 1);
                    var picker = pageStack.push("Sailfish.Silica.DatePickerDialog", { date: initial });
                    picker.accepted.connect(function () {
                        dialog.birthday = Utils.daysBetween(new Date(), picker.date) > 0
                                ? Utils.toLocalDateString(new Date())
                                : Utils.toLocalDateString(picker.date);
                    });
                }
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                TextField {
                    id: heightField
                    width: parent.width
                    //: Field label: the height, in centimetres
                    label: qsTr("Height (cm)")
                    placeholderText: label
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: RegExpValidator { regExp: /^\d{1,3}([.,]\d?)?$/ }
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: dialog.canAccept
                    EnterKey.onClicked: dialog.accept()
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: heightField.text !== "" && !dialog.heightInRange
                    wrapMode: Text.Wrap
                    //: Under the height field; %1 and %2 are the lowest and highest height accepted
                    text: qsTr("Enter a height between %1 and %2 cm").arg(Database.HEIGHT_MIN).arg(Database.HEIGHT_MAX)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        if (!editing) {
            firstNameField.focus = true;
            return;
        }
        var profile = Database.profile(profileCode);
        if (!profile) {
            return;
        }
        firstNameField.text = profile.firstName;
        lastNameField.text = profile.lastName;
        genderBox.currentIndex = profile.gender === "M" ? 1 : 0;
        // One that could not be read is left empty, to be picked again.
        birthday = profile.birthdayValid ? profile.birthday : "";
        heightField.text = profile.height !== null ? Utils.formatInput(profile.height) : "";
    }
}

// vim:et:ts=4:sw=4
