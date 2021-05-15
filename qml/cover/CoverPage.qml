import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

import "../js/utils.js" as WtUtils

CoverBackground {
    anchors.fill: parent

    function loadData() {
        var WtData = WtUtils.info_user(WtUtils.getLastUser());
        label_first_name.text = WtData.firstname;
        label_last_name.text = WtData.lastname;
        label_weight.text = WtData.weight + " kg";
        label_bmi.text = "BMI: " + WtData.bmi.toFixed(2);
    }

    Label {
        id: label_first_name
        anchors.top: parent.top
        text: "First"
        anchors.topMargin: 30
        font.pixelSize: Theme.fontSizeLarge
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label {
        id: label_last_name
        anchors.top: label_first_name.bottom
        text: "Last"
        font.pixelSize: Theme.fontSizeLarge
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label {
        id: label_weight
        anchors.top: label_last_name.bottom
        text: "Weight"
        anchors.topMargin: 30
        font.pixelSize: Theme.fontSizeExtraLarge
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label {
        id: label_bmi
        anchors.top: label_weight.bottom
        text: "BMI"
        anchors.topMargin: 30
        font.pixelSize: Theme.fontSizeLarge
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Component.onCompleted: loadData()

    CoverActionList {
        id: coverAction
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: loadData()
        }
    }
}
