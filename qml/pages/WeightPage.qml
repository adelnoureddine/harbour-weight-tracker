import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Database.js" as Database
import "../js/utils.js" as Utils

/*
 * Every weight of the profile, as Health's history pages show it: the latest, a chart
 * of a chosen period with the target line, its statistics, and the list by day.
 *
 * Each row keeps its weight's code in the model. Version 1.3 kept the codes in a
 * separate array that was not rebuilt after a delete, so the next delete or edit on
 * the page could hit another weight than the one chosen.
 */
Page {
    id: page

    allowedOrientations: Orientation.All

    property var profile: null
    property var latest: null
    property int rangeDays: 30
    property var chartSeries: []
    property var chartStats: null
    property var rangeStart: null
    property var rangeEnd: null
    property string changeText: ""
    // Set once the range was chosen, by the first refresh or by the user.
    property bool rangeSettled: false
    property bool loaded: false
    readonly property bool hasData: !loaded || listModel.count > 0

    function refreshChart() {
        if (!profile) {
            return;
        }
        var points = Database.series(profile.code, rangeDays);
        if (rangeDays > 0) {
            var start = new Date();
            start.setHours(0, 0, 0, 0);
            start.setDate(start.getDate() - rangeDays + 1);
            rangeStart = start.getTime();
            rangeEnd = Date.now();
        } else {
            rangeStart = null;
            rangeEnd = null;
        }
        chartSeries = [{ points: points, color: Theme.highlightColor, label: qsTr("Weight") }];
        changeText = Utils.changeSinceText(points);
        chartStats = Database.stats(profile.code, rangeDays);
    }

    function refresh() {
        profile = appWindow.profileId >= 0 ? Database.profile(appWindow.profileId) : null;
        if (!profile) {
            return;
        }
        latest = Database.latestWeight(profile.code);
        var keepY = loaded ? listView.contentY : null;
        listModel.clear();
        var all = Database.weights(profile.code);
        for (var i = 0; i < all.length; i++) {
            listModel.append({ code: all[i].code, day: all[i].date, value: all[i].value });
        }
        if (keepY !== null) {
            listView.contentY = keepY;
            listView.returnToBounds();
        } else {
            scrollToTop.restart();
        }
        loaded = true;
        refreshChart();
        // Someone whose last weight is older than a month would get an empty chart
        // above a full list. Show everything instead.
        if (!rangeSettled) {
            rangeSettled = true;
            if (listModel.count > 0 && chartStats !== null && chartStats.count === 0) {
                rangeDays = 0;
            }
        }
    }

    function openWeight(code) {
        pageStack.animatorPush(Qt.resolvedUrl("WeightDialog.qml"), {
            profileId: page.profile.code,
            metricCode: code === undefined ? -1 : code
        });
    }

    onRangeDaysChanged: refreshChart()

    Connections {
        target: appWindow
        onRevisionChanged: page.refresh()
    }
    Component.onCompleted: refresh()

    RemorsePopup {
        id: clearRemorse
    }

    // The header grows once the chart and the statistics are in, and the list would
    // then open scrolled part way down. Until the user scrolls, it is kept at the top.
    property bool holdTop: true

    Timer {
        id: scrollToTop
        interval: 50
        onTriggered: {
            listView.forceLayout();
            listView.positionViewAtBeginning();
        }
    }

    SilicaListView {
        id: listView

        anchors.fill: parent
        onMovementStarted: page.holdTop = false

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium
            onHeightChanged: {
                if (page.holdTop) {
                    scrollToTop.restart();
                }
            }

            PageHeader {
                title: qsTr("Weight")
                description: page.profile ? page.profile.firstName : ""
            }

            HistoryHero {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: page.hasData && page.latest !== null
                valueText: page.latest ? Utils.formatValue(page.latest.value, 1) : ""
                unit: qsTr("kg")
                detailText: page.latest && page.profile
                            ? [Utils.targetText(page.latest.value, page.profile.target), page.changeText,
                               Utils.measuredWhen(page.latest.date)]
                                  .filter(function (part) { return part !== ""; }).join(" · ")
                            : ""
            }

            ChartCard {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: page.hasData
                series: page.chartSeries
                unit: qsTr("kg")
                decimals: 1
                emptyText: qsTr("No weight in this period")
                goalValue: page.profile ? page.profile.target : null
                //: On the chart, next to the line of the target, e.g. "Target 70 kg"
                goalText: page.profile && page.profile.target !== null
                          ? qsTr("Target %1").arg(Utils.kg(page.profile.target)) : ""
                rangeStart: page.rangeStart
                rangeEnd: page.rangeEnd
            }

            ChartRangeSelector {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: page.hasData
                days: page.rangeDays
                onDaysChanged: page.rangeDays = days
            }

            // ChartStats hides itself without data.
            ChartStats {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                stats: page.chartStats
                unit: qsTr("kg")
                decimals: 1
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        PullDownMenu {
            MenuItem {
                visible: listModel.count > 0
                text: qsTr("Delete all weights")
                onClicked: {
                    var code = page.profile.code;
                    clearRemorse.execute(qsTr("Deleting all weights"), function () {
                        Database.clearWeights(code);
                        appWindow.changed();
                    });
                }
            }
            MenuItem {
                //: Menu item: set the weight to reach
                text: qsTr("Target weight")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("TargetDialog.qml"), { profileCode: page.profile.code })
            }
            MenuItem {
                text: qsTr("Add weight")
                onClicked: page.openWeight()
            }
        }

        model: ListModel {
            id: listModel
        }

        section {
            property: "day"
            criteria: ViewSection.FullString
            delegate: SectionHeader {
                text: Utils.dayTitle(section)
            }
        }

        delegate: ListItem {
            id: listItem

            contentHeight: Theme.itemSizeSmall

            function remove() {
                // Read now: a refresh during the countdown rebuilds the rows.
                var profileCode = page.profile.code;
                var code = model.code;
                listItem.remorseDelete(function () {
                    Database.deleteWeight(profileCode, code);
                    appWindow.changed();
                });
            }

            onClicked: page.openWeight(model.code)

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: page.openWeight(model.code)
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: listItem.remove()
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                truncationMode: TruncationMode.Fade
                text: Utils.kg(model.value)
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }

        ViewPlaceholder {
            enabled: !page.hasData
            text: qsTr("No weight yet")
            hintText: qsTr("Pull down to add the first one")
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
