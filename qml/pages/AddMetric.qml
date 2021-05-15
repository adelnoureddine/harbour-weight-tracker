import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: newMetric
    backNavigation: true
    allowedOrientations: Orientation.All

    property string metric_code;
    property string user_code;

    function addMetric(value){
        value = value.replace(',', '.');
        //load user_code from homepage, if(depth==3)adding from history else from homepage
        if(depth==3) user_code=previousPage().rootPage.user_code;
        else user_code=previousPage().user_code;
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT MAX(METRIC_CODE) AS METRIC FROM METRICS ');
                if(rs.rows.item(0).METRIC===null) metric_code="1"
                else{
                    metric_code = rs.rows.item(0).METRIC;
                    metric_code = parseInt(metric_code) +1;
                }
                var date = new Date();
                date = Qt.formatDate(date, "yyyy-MM-dd");
                rs = tx.executeSql('INSERT INTO METRICS VALUES (?,?,?,?,?)',[user_code,metric_code,date,"WEIGHT",value]);
                rs = tx.executeSql('SELECT * FROM METRICS WHERE USER_CODE=?',[user_code]);
            }
        )
        //reload homepage if adding from homepage or history if adding metric from history page
        previousPage().load();
        //reload homepage if add from history page
        if(depth==3) previousPage().rootPage.load();
        navigateBack(PageStackAction.Animated);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: 'Add new metric' }

            TextField {
                id: metricField
                width: parent.width
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                label: "kg"
                placeholderText: "Weight"
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: phoneField.focus = true
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                focus: true
            }
            Button {
                text: 'Add'
                anchors.horizontalCenter: parent.horizontalCenter
                enabled:metricField.acceptableInput
                onClicked: addMetric(metricField.text)
            }
        }
    }
}

