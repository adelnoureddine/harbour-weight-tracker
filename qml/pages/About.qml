import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Weight Tracker")
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("A simple Health Monitoring App")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            SectionHeader {
                text: qsTr("Maintainer and Current Developer")
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                text: qsTr("Adel Noureddine © 2021-2022")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }


            SectionHeader {
                text: qsTr("Initial Authors")
            }

            Column {

                width: parent.width

                Label {
                    text: "Manon Sauvageot © 2021"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }

                Label {
                    text: "Yoann Dumont © 2021"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }

                Label {
                    text: "Louis Puyou © 2021"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            SectionHeader {
                text: qsTr("Source Code")
            }

            Label {
                text: qsTr("Licensed under GNU GPL v3")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Icon {
                 source: "image://theme/icon-s-cloud-download"
                 anchors {
                     horizontalCenter: parent.horizontalCenter
                 }
             }

            Text {
                text: "<a href=\"https://gitlab.com/adelnoureddine/harbour-weight-tracker\">" + qsTr("View source code on GitLab") + "</a>"
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
                font.pixelSize: Theme.fontSizeSmall
                linkColor: Theme.highlightColor

                onLinkActivated: Qt.openUrlExternally("https://gitlab.com/adelnoureddine/harbour-weight-tracker")
            }

            SectionHeader {
                text: qsTr("Health sources")
            }

            LinkedLabel {
                x: Theme.horizontalPageMargin
                text: "<a href=\"http://www.euro.who.int/en/health-topics/disease-prevention/nutrition/a-healthy-lifestyle/body-mass-index-bmi\">World Heath Organisation Europe</a>"
                font.pixelSize: Theme.fontSizeSmall
                linkColor: Theme.highlightColor
                width: parent.width - 2*x

                onLinkActivated: Qt.openUrlExternally("http://www.euro.who.int/en/health-topics/disease-prevention/nutrition/a-healthy-lifestyle/body-mass-index-bmi")
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            LinkedLabel {
                x: Theme.horizontalPageMargin
                text: "<a href=\"https://www.cdc.gov/healthyweight/assessing/bmi/adult_bmi/metric_bmi_calculator/bmi_calculator.html\">Centers for Disease Control and Prevention (USA)</a>"
                font.pixelSize: Theme.fontSizeSmall
                linkColor: Theme.highlightColor
                width: parent.width - 2*x

                onLinkActivated: Qt.openUrlExternally("https://www.cdc.gov/healthyweight/assessing/bmi/adult_bmi/metric_bmi_calculator/bmi_calculator.html")
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
