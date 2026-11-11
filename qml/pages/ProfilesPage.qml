import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Database.js" as Database
import "../js/utils.js" as Utils

/*
 * Every profile, on cards as in Health: tap one to show it, long-press to edit or
 * delete it. Replaces version 1.3's profile combo box and its separate settings page.
 */
Page {
    id: page

    allowedOrientations: Orientation.All

    function refresh() {
        listModel.clear();
        var all = Database.profiles();
        for (var i = 0; i < all.length; i++) {
            listModel.append({
                code: all[i].code,
                name: (all[i].firstName + " " + all[i].lastName).trim(),
                initials: Utils.initials(all[i].firstName, all[i].lastName),
                detail: Utils.profileDetail(all[i])
            });
        }
    }

    function openProfile(code) {
        pageStack.animatorPush(Qt.resolvedUrl("ProfileDialog.qml"), { profileCode: code });
    }

    Connections {
        target: appWindow
        onRevisionChanged: page.refresh()
    }
    Component.onCompleted: refresh()

    SilicaListView {
        id: listView

        anchors.fill: parent
        spacing: Theme.paddingMedium

        header: PageHeader {
            title: qsTr("Profiles")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("New profile")
                onClicked: page.openProfile(-1)
            }
        }

        model: ListModel {
            id: listModel
        }

        delegate: ListItem {
            id: row

            readonly property bool current: model.code === appWindow.profileId

            contentHeight: Math.max(Theme.itemSizeLarge, textColumn.height + 2 * Theme.paddingLarge)
            // The pressed look is the card's own; not a full-width block.
            highlightedColor: "transparent"

            function remove() {
                var code = model.code;
                row.remorseDelete(function () {
                    Database.deleteProfile(code);
                    appWindow.reloadProfile();
                });
            }

            onClicked: {
                appWindow.selectProfile(model.code);
                pageStack.pop();
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: page.openProfile(model.code)
                    }
                    MenuItem {
                        //: Deletes the profile and all its weights
                        text: qsTr("Delete")
                        onClicked: row.remove()
                    }
                }
            }

            CardBackground {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: row.contentHeight
                highlighted: row.highlighted
                primary: row.current && !row.highlighted
            }

            Rectangle {
                id: badge
                x: Theme.horizontalPageMargin + Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.itemSizeSmall
                height: width
                radius: width / 2
                color: Theme.rgba(Theme.highlightColor, 0.3)

                Label {
                    anchors.centerIn: parent
                    text: model.initials
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.highlightColor
                }
            }

            Column {
                id: textColumn
                anchors.left: badge.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin + Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.name
                    color: row.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.detail
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: row.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
                StatusPill {
                    visible: row.current
                    //: The profile shown on the main page
                    text: qsTr("Current")
                    dotColor: Theme.highlightColor
                    highlighted: row.highlighted
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No profile yet")
            hintText: qsTr("Pull down to create one")
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
