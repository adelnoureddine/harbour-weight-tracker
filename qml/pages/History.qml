import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page
    allowedOrientations: Orientation.All

    property bool deletingItems
    property Page rootPage
    property variant metric_tab: []

    function load(){
        listModel.load()
    }

    SilicaListView {
        id: listView
        model: listModel
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("History")
        }

        ViewPlaceholder {
            enabled: (listModel.populated && listModel.count === 0) || page.deletingItems
            text: "Empty history"
            hintText: "Pull down to add metrics"
        }

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: "Clear History"
                visible: listView.count
                onClicked: {
                    page.deletingItems = true
                    var remorse = Remorse.popupAction(
                                page, "Cleared",
                                function() {
                                    var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                                    db.transaction(
                                        function(tx){
                                            tx.executeSql('DELETE FROM METRICS WHERE USER_CODE=?',[rootPage.user_code])
                                        }
                                    )
                                    listModel.clear()
                                    rootPage.load()
                                })
                    remorse.canceled.connect(function() { page.deletingItems = false })
                }
            }
            MenuItem {
                text: "Add Metric"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./AddMetric.qml'))
            }
            MenuLabel {
                text: "Options"
            }
        }

        delegate: ListItem {
            id: list
            function remove() {
                remorseDelete(function() {
                    var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                    db.transaction(
                        function(tx){
                            tx.executeSql('DELETE FROM METRICS WHERE METRIC_CODE=?',[metric_tab[index]])
                        }
                    )
                    listModel.remove(index)
                    rootPage.load()
                })
            }
            function edit(value) {
                value = value.replace(',', '.');
                var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                db.transaction(
                    function(tx){
                        tx.executeSql('UPDATE METRICS SET VAL=? WHERE METRIC_CODE=?',[parseFloat(value),metric_tab[index]])
                    }
                )
                rootPage.load()
                listModel.load();
            }

            ListView.onRemove: animateRemoval()
            enabled: !page.deletingItems
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {}}

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"
                        onClicked: pageStack.animatorPush(editMetric)
                    }
                    MenuItem {
                        text: "Delete"
                        onClicked: remove()
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                anchors.verticalCenter: parent.verticalCenter
                text: model.text
                truncationMode: TruncationMode.Fade
                font.capitalization: Font.Capitalize
            }
            Component {
                id: editMetric
                Dialog{
                    acceptDestination: page
                    acceptDestinationAction: PageStackAction.Pop
                    canAccept: metricField.acceptableInput
                    onAccepted: {
                        edit(metricField.text)
                    }
                    SilicaFlickable {
                        anchors.fill: parent
                        contentHeight: column.height

                        Column {
                            id: column
                            width: parent.width
                            spacing: Theme.paddingLarge

                            DialogHeader { title: 'Edit this metric:' }

                            TextField {
                                id: metricField
                                width: parent.width
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                label: "kg"
                                placeholderText: "Weight"
                                focus: true
                                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                                EnterKey.onClicked: phoneField.focus = true
                                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                            }
                        }
                    }
                }
            }

        }
    }

    ListModel {
        id: listModel

        property bool populated
        property string metric_code;
        property int user_code;

        Component.onCompleted:{
            rootPage=previousPage()
            user_code=rootPage.user_code
            load()
        }

        function load() {
            listModel.clear()
            var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
            db.transaction(
                function(tx){

                    var rs = tx.executeSql('SELECT * FROM METRICS WHERE USER_CODE=? ORDER BY METRIC_CODE DESC',[user_code]);
                    var entries = rs.rows.length;
                    for(var i =0; i< rs.rows.length;i++){
                        metric_tab[i] = rs.rows.item(i).METRIC_CODE;
                        listModel.append({"text": rs.rows.item(i).METRIC_DATE + "                               " + rs.rows.item(i).VAL + " kg"});
                    }
                }
            )
            page.deletingItems = false
            populated = true
        }
    }

}
