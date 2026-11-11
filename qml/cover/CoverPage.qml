import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Database.js" as Database
import "../js/bmi.js" as Bmi
import "../js/utils.js" as Utils

/*
 * The latest weight of the profile shown, its trend and its BMI. It follows changes
 * made in the app; version 1.3 needed its refresh action for that, and showed
 * "undefined" or failed without a profile or a weight.
 */
CoverBackground {
    id: cover

    property var profile: null
    property var latest: null
    property var trend: []
    property var bmi: null
    property int category: -1

    function refresh() {
        if (!appWindow.ready || appWindow.databaseError !== "") {
            return;
        }
        profile = appWindow.profileId >= 0 ? Database.profile(appWindow.profileId) : null;
        latest = profile ? Database.latestWeight(profile.code) : null;
        var points = profile ? Database.series(profile.code, 30) : [];
        if (profile && points.length < 2) {
            points = Database.series(profile.code, 0).slice(-10);
        }
        trend = points;
        bmi = latest && profile.height !== null ? Bmi.compute(profile.height, latest.value) : null;
        category = Bmi.category(bmi);
    }

    function openAddWeight() {
        if (!cover.profile) {
            return;
        }
        pageStack.pop(null, PageStackAction.Immediate);
        pageStack.push(Qt.resolvedUrl("../pages/WeightDialog.qml"), { profileId: cover.profile.code },
                       PageStackAction.Immediate);
        appWindow.activate();
    }

    Connections {
        target: appWindow
        onRevisionChanged: cover.refresh()
        onReadyChanged: cover.refresh()
        onProfileIdChanged: cover.refresh()
    }
    onStatusChanged: {
        if (status === Cover.Active) {
            refresh();
        }
    }
    Component.onCompleted: refresh()

    Column {
        x: Theme.paddingLarge
        y: Theme.paddingLarge
        width: parent.width - 2 * Theme.paddingLarge
        spacing: Theme.paddingMedium
        visible: cover.latest !== null

        Label {
            width: parent.width
            truncationMode: TruncationMode.Fade
            //: Cover header: "Weight" and the profile's first name
            text: cover.profile ? qsTr("Weight · %1").arg(cover.profile.firstName) : ""
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.highlightColor
        }

        Row {
            width: parent.width
            spacing: Theme.paddingSmall
            Label {
                id: valueLabel
                width: Math.min(implicitWidth, parent.width - unitLabel.width - parent.spacing)
                truncationMode: TruncationMode.Fade
                text: cover.latest ? Utils.formatValue(cover.latest.value, 1) : ""
                font.pixelSize: Theme.fontSizeExtraLarge
                color: Theme.primaryColor
            }
            Label {
                id: unitLabel
                anchors.baseline: valueLabel.baseline
                text: qsTr("kg")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
            }
        }

        Sparkline {
            visible: cover.trend.length >= 2
            width: parent.width
            height: visible ? Theme.paddingLarge * 2 : 0
            points: cover.trend.map(function (p) { return p.v; })
            filled: false
            lineColor: Theme.highlightColor
        }

        Label {
            width: parent.width
            truncationMode: TruncationMode.Fade
            text: cover.latest ? Utils.measuredWhen(cover.latest.date) : ""
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
        }

        // The BMI and its category, a dot in its band colour.
        Row {
            width: parent.width
            spacing: Theme.paddingSmall
            visible: cover.bmi !== null

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.paddingMedium
                height: width
                radius: width / 2
                color: Bmi.categoryColor(cover.category)
            }
            Label {
                width: parent.width - Theme.paddingMedium - parent.spacing
                truncationMode: TruncationMode.Fade
                //: Cover: the BMI, e.g. "BMI 24.6"
                text: cover.bmi !== null ? qsTr("BMI %1").arg(appWindow.formatNumber(cover.bmi, 1)) : ""
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
            }
        }
    }

    CoverPlaceholder {
        visible: cover.latest === null
        //: Cover text without a weight: the app's name
        text: qsTr("Weight Tracker")
        icon.source: "/usr/share/icons/hicolor/86x86/apps/harbour-weight-tracker.png"
    }

    CoverActionList {
        enabled: cover.profile !== null
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: cover.openAddWeight()
        }
    }
}

// vim:et:ts=4:sw=4
