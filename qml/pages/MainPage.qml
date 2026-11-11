import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Database.js" as Database
import "../js/bmi.js" as Bmi
import "../js/utils.js" as Utils

/*
 * The profile shown, as Health's dashboard shows it: the latest weight with its trend,
 * the height and the BMI, each opening its own page.
 */
Page {
    id: page

    allowedOrientations: Orientation.All

    property var profile: null
    property int profileCount: 0
    property var latest: null
    property var trend: []
    property string changeText: ""
    property var bmi: null
    property int category: -1
    property string todayText: ""

    // Lines stay a readable length in landscape and on tablets.
    readonly property real contentWidth: Math.min(width, Screen.width * 1.25)
    readonly property bool usable: appWindow.ready && appWindow.databaseError === ""

    function refresh() {
        todayText = Utils.longDate(new Date());
        if (!usable) {
            return;
        }
        profileCount = Database.profiles().length;
        profile = appWindow.profileId >= 0 ? Database.profile(appWindow.profileId) : null;
        latest = profile ? Database.latestWeight(profile.code) : null;
        var points = profile ? Database.series(profile.code, 30) : [];
        // A month with fewer than two weights: the last ten, however old.
        if (profile && points.length < 2) {
            points = Database.series(profile.code, 0).slice(-10);
        }
        trend = points;
        changeText = Utils.changeSinceText(points);
        bmi = latest && profile.height !== null ? Bmi.compute(profile.height, latest.value) : null;
        category = Bmi.category(bmi);
    }

    function openAddWeight() {
        pageStack.animatorPush(Qt.resolvedUrl("WeightDialog.qml"), { profileId: appWindow.profileId });
    }

    function openProfile(code) {
        pageStack.animatorPush(Qt.resolvedUrl("ProfileDialog.qml"), { profileCode: code });
    }

    Connections {
        target: appWindow
        onRevisionChanged: page.refresh()
        onReadyChanged: page.refresh()
        onProfileIdChanged: page.refresh()
    }

    // "Measured today" becomes "Measured yesterday" overnight.
    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }
    Component.onCompleted: refresh()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                visible: page.usable
                text: page.profileCount > 0 ? qsTr("Profiles") : qsTr("Create a profile")
                onClicked: page.profileCount > 0 ? pageStack.animatorPush(Qt.resolvedUrl("ProfilesPage.qml"))
                                                 : page.openProfile(-1)
            }
            MenuItem {
                visible: page.usable
                text: qsTr("Backup and export")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("DataPage.qml"))
            }
            // Last: closest to the finger.
            MenuItem {
                visible: page.usable && page.profile !== null
                text: qsTr("Add weight")
                onClicked: page.openAddWeight()
            }
        }

        Column {
            id: column

            anchors.horizontalCenter: parent.horizontalCenter
            width: page.contentWidth
            spacing: Theme.paddingMedium

            // Profile name, today's date and an initial. Tapping it switches profile.
            BackgroundItem {
                id: header
                width: parent.width
                height: Math.max(Theme.itemSizeLarge, headerText.height + 2 * Theme.paddingLarge)
                enabled: page.profileCount > 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("ProfilesPage.qml"))

                Rectangle {
                    id: avatar
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    visible: page.profile !== null
                    width: Theme.itemSizeSmall
                    height: width
                    radius: width / 2
                    color: Theme.rgba(Theme.highlightColor, 0.3)

                    Label {
                        anchors.centerIn: parent
                        text: page.profile ? Utils.initials(page.profile.firstName, "") : ""
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                    }
                }

                Column {
                    id: headerText
                    anchors.right: avatar.visible ? avatar.left : parent.right
                    anchors.rightMargin: avatar.visible ? Theme.paddingLarge : Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 2 * Theme.horizontalPageMargin
                           - (avatar.visible ? avatar.width + Theme.paddingLarge : 0)

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        truncationMode: TruncationMode.Fade
                        //: The app's name, at the top of the main page before a profile exists
                        text: page.profile ? page.profile.firstName : qsTr("Weight Tracker")
                        font.pixelSize: Theme.fontSizeExtraLarge
                        font.family: Theme.fontFamilyHeading
                        color: Theme.highlightColor
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        truncationMode: TruncationMode.Fade
                        text: page.todayText
                        font.pixelSize: Theme.fontSizeSmall
                        color: header.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }
                }
            }

            Item { width: 1; height: Theme.paddingSmall }

            // The database could not be opened.
            Card {
                visible: appWindow.databaseError !== ""

                Row {
                    width: parent.width
                    spacing: Theme.paddingMedium
                    Icon {
                        id: errorIcon
                        source: "image://theme/icon-m-warning"
                        color: Theme.highlightColor
                    }
                    Label {
                        width: parent.width - errorIcon.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.Wrap
                        text: appWindow.databaseError
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                    }
                }
            }

            // No profile yet: where to start.
            Card {
                visible: page.usable && page.profileCount === 0
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Welcome")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Create a profile to start tracking your weight. Everyone in the family can have their own. Your data stays on this phone.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
                Item { width: 1; height: Theme.paddingSmall }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: Theme.buttonWidthLarge
                    text: qsTr("Create a profile")
                    onClicked: page.openProfile(-1)
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: Theme.buttonWidthLarge
                    text: qsTr("Restore a backup")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("DataPage.qml"))
                }
            }

            // A birthday version 1.x stored in a form that could not be read back.
            BackgroundItem {
                id: birthdayWarning
                visible: page.profile !== null && !page.profile.birthdayValid
                width: parent.width
                height: warningRow.height + 2 * Theme.paddingLarge
                highlightedColor: "transparent"
                onClicked: page.openProfile(page.profile.code)

                CardBackground {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    height: parent.height
                    highlighted: birthdayWarning.highlighted
                }
                Row {
                    id: warningRow
                    x: Theme.horizontalPageMargin + Theme.paddingLarge
                    y: Theme.paddingLarge
                    width: parent.width - 2 * x
                    spacing: Theme.paddingMedium
                    Icon {
                        id: warningIcon
                        source: "image://theme/icon-m-warning"
                        color: Theme.highlightColor
                    }
                    Label {
                        width: parent.width - warningIcon.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.Wrap
                        text: qsTr("The birthday of this profile could not be read. Tap to pick it again.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                    }
                }
            }

            // --- weight: the latest, its change and its trend ------------------------
            BackgroundItem {
                id: weightCard
                visible: page.profile !== null
                width: parent.width
                height: weightColumn.height + 2 * Theme.paddingLarge
                highlightedColor: "transparent"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("WeightPage.qml"))

                CardBackground {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    height: parent.height
                    highlighted: weightCard.highlighted
                    subtle: page.latest === null
                }

                Column {
                    id: weightColumn
                    x: Theme.horizontalPageMargin + Theme.paddingLarge
                    y: Theme.paddingLarge
                    width: parent.width - 2 * x
                    spacing: Theme.paddingSmall

                    Item {
                        width: parent.width
                        height: Theme.iconSizeSmall
                        HighlightImage {
                            id: weightIcon
                            width: Theme.iconSizeSmall
                            height: Theme.iconSizeSmall
                            sourceSize.width: Theme.iconSizeSmall
                            sourceSize.height: Theme.iconSizeSmall
                            source: Qt.resolvedUrl("../icons/weight.svg")
                            color: Theme.secondaryHighlightColor
                            highlighted: weightCard.highlighted
                        }
                        Label {
                            anchors.left: weightIcon.right
                            anchors.leftMargin: Theme.paddingSmall
                            anchors.right: weightWhen.left
                            anchors.rightMargin: Theme.paddingSmall
                            anchors.verticalCenter: parent.verticalCenter
                            truncationMode: TruncationMode.Fade
                            text: qsTr("Weight")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            id: weightWhen
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: page.latest ? Utils.measuredWhen(page.latest.date) : ""
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: weightCard.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }

                    Item {
                        width: parent.width
                        height: weightValue.height
                        visible: page.latest !== null
                        Label {
                            id: weightValue
                            text: page.latest ? Utils.formatValue(page.latest.value, 1) : ""
                            font.pixelSize: Theme.fontSizeHuge
                            color: weightCard.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            anchors.left: weightValue.right
                            anchors.leftMargin: Theme.paddingSmall
                            anchors.baseline: weightValue.baseline
                            //: Unit: kilograms
                            text: qsTr("kg")
                            font.pixelSize: Theme.fontSizeMedium
                            color: weightCard.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                        Label {
                            anchors.right: parent.right
                            anchors.baseline: weightValue.baseline
                            text: page.changeText
                            font.pixelSize: Theme.fontSizeSmall
                            color: weightCard.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                    }

                    Label {
                        width: parent.width
                        visible: text !== ""
                        wrapMode: Text.Wrap
                        text: page.profile && page.latest ? Utils.targetText(page.latest.value, page.profile.target) : ""
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: weightCard.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }

                    Sparkline {
                        visible: page.trend.length >= 2
                        width: parent.width
                        height: Theme.itemSizeExtraSmall
                        points: page.trend.map(function (p) { return p.v; })
                        lineColor: Theme.highlightColor
                    }

                    Label {
                        width: parent.width
                        visible: page.latest === null
                        wrapMode: Text.Wrap
                        text: qsTr("No weight yet. Pull down to add the first one.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: weightCard.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }
                }
            }

            // --- height and BMI, side by side ---------------------------------------
            Item {
                id: halfRow
                visible: page.profile !== null
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Math.max(heightColumn.height, bmiColumn.height) + 2 * Theme.paddingLarge

                readonly property real cardWidth: (width - Theme.paddingMedium) / 2

                BackgroundItem {
                    id: heightCard
                    width: halfRow.cardWidth
                    height: parent.height
                    highlightedColor: "transparent"
                    onClicked: page.openProfile(page.profile.code)

                    CardBackground {
                        anchors.fill: parent
                        highlighted: heightCard.highlighted
                    }
                    Column {
                        id: heightColumn
                        x: Theme.paddingLarge
                        y: Theme.paddingLarge
                        width: parent.width - 2 * Theme.paddingLarge
                        spacing: Theme.paddingSmall

                        Row {
                            spacing: Theme.paddingSmall
                            HighlightImage {
                                width: Theme.iconSizeSmall
                                height: Theme.iconSizeSmall
                                sourceSize.width: Theme.iconSizeSmall
                                sourceSize.height: Theme.iconSizeSmall
                                source: Qt.resolvedUrl("../icons/height.svg")
                                color: Theme.secondaryHighlightColor
                                highlighted: heightCard.highlighted
                            }
                            Label {
                                text: qsTr("Height")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.secondaryHighlightColor
                            }
                        }
                        Row {
                            spacing: Theme.paddingSmall
                            Label {
                                id: heightValue
                                text: page.profile && page.profile.height !== null ? Utils.formatValue(page.profile.height, 1) : "—"
                                font.pixelSize: Theme.fontSizeExtraLarge
                                color: heightCard.highlighted ? Theme.highlightColor : Theme.primaryColor
                            }
                            Label {
                                anchors.baseline: heightValue.baseline
                                //: Unit: centimetres
                                text: qsTr("cm")
                                font.pixelSize: Theme.fontSizeSmall
                                color: heightCard.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            }
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: qsTr("From the profile")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: heightCard.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }

                BackgroundItem {
                    id: bmiCard
                    anchors.right: parent.right
                    width: halfRow.cardWidth
                    height: parent.height
                    highlightedColor: "transparent"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("BmiPage.qml"))

                    CardBackground {
                        anchors.fill: parent
                        highlighted: bmiCard.highlighted
                        subtle: page.bmi === null
                    }
                    Column {
                        id: bmiColumn
                        x: Theme.paddingLarge
                        y: Theme.paddingLarge
                        width: parent.width - 2 * Theme.paddingLarge
                        spacing: Theme.paddingSmall

                        Row {
                            spacing: Theme.paddingSmall
                            HighlightImage {
                                width: Theme.iconSizeSmall
                                height: Theme.iconSizeSmall
                                sourceSize.width: Theme.iconSizeSmall
                                sourceSize.height: Theme.iconSizeSmall
                                source: Qt.resolvedUrl("../icons/bmi.svg")
                                color: Theme.secondaryHighlightColor
                                highlighted: bmiCard.highlighted
                            }
                            Label {
                                text: qsTr("BMI")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.secondaryHighlightColor
                            }
                        }
                        Label {
                            text: page.bmi === null ? "—" : appWindow.formatNumber(page.bmi, 1)
                            font.pixelSize: Theme.fontSizeExtraLarge
                            color: bmiCard.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        StatusPill {
                            text: appWindow.categoryName(page.category)
                            dotColor: Bmi.categoryColor(page.category)
                            maximumWidth: parent.width
                            highlighted: bmiCard.highlighted
                        }
                        Label {
                            width: parent.width
                            visible: page.bmi === null
                            wrapMode: Text.Wrap
                            text: qsTr("Needs a weight")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: bmiCard.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
