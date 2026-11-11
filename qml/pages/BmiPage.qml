import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Database.js" as Database
import "../js/bmi.js" as Bmi
import "../js/utils.js" as Utils

/*
 * The BMI of the latest weight, as Simple BMI Calculator shows it: its category, where
 * it falls, and the healthy weight range for the profile's height.
 */
Page {
    id: page

    allowedOrientations: Orientation.All

    property var profile: null
    property var latest: null
    property var bmi: null
    property int category: -1
    property var healthy: null

    readonly property real contentWidth: Math.min(width, Screen.width * 1.25)

    function refresh() {
        profile = appWindow.profileId >= 0 ? Database.profile(appWindow.profileId) : null;
        latest = profile ? Database.latestWeight(profile.code) : null;
        bmi = latest && profile.height !== null ? Bmi.compute(profile.height, latest.value) : null;
        category = Bmi.category(bmi);
        healthy = profile && profile.height !== null ? Bmi.healthyRange(profile.height) : null;
    }

    Connections {
        target: appWindow
        onRevisionChanged: page.refresh()
    }
    Component.onCompleted: refresh()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column

            anchors.horizontalCenter: parent.horizontalCenter
            width: page.contentWidth
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("BMI")
                description: page.profile ? page.profile.firstName : ""
            }

            Card {
                visible: page.bmi !== null
                spacing: Theme.paddingMedium

                Column {
                    width: parent.width

                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        //: %1 is a weight and %2 a height, e.g. "From 72.5 kg and 170 cm"
                        text: page.latest && page.profile
                              ? qsTr("From %1 and %2").arg(Utils.kg(page.latest.value))
                                                      .arg(qsTr("%1 cm").arg(Utils.formatValue(page.profile.height, 1)))
                              : ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                    }

                    Row {
                        spacing: Theme.paddingSmall

                        Label {
                            id: bmiLabel
                            text: page.bmi === null ? "" : appWindow.formatNumber(page.bmi, 1)
                            font.pixelSize: Theme.fontSizeHuge
                            color: Theme.primaryColor
                        }
                        Label {
                            anchors.baseline: bmiLabel.baseline
                            //: Unit of the BMI: kilograms per square metre
                            text: qsTr("kg/m²")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryColor
                        }
                    }
                }

                StatusPill {
                    text: appWindow.categoryName(page.category)
                    dotColor: Bmi.categoryColor(page.category)
                    maximumWidth: parent.width
                }

                BmiScale {
                    bmi: page.bmi
                }

                Column {
                    width: parent.width
                    visible: page.healthy !== null

                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("Healthy weight for your height")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                    }
                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        //: %1 and %2 are weights in kilograms, with one decimal
                        text: page.healthy === null ? ""
                              : qsTr("%1 to %2 kg").arg(appWindow.formatNumber(page.healthy.min, 1))
                                                   .arg(appWindow.formatNumber(page.healthy.max, 1))
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.primaryColor
                    }
                }
            }

            Card {
                visible: page.category >= 0

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: appWindow.categoryName(page.category)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: appWindow.categoryDescription(page.category)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
            }

            Card {
                visible: page.bmi === null
                subtle: true

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Add a weight to see the BMI.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("The BMI is a screening measure for adults: it does not tell fat from muscle, and is not medical advice.")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
