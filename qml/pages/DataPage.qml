import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Database.js" as Database
import "../js/HealthExport.js" as HealthExport
import "../js/utils.js" as Utils

/*
 * Backups, the CSV export, the move to Health, and restoring a backup, laid out as
 * Health's Backup and restore page.
 *
 * Files go to Documents/WeightTracker, where they can be copied to a computer or to
 * another phone; the Health backup goes to Documents/Health, where Health finds it.
 * Before a restore replaces the data, a copy of it is kept in the app's private folder,
 * and those copies are in the restore list too.
 */
Page {
    id: page

    allowedOrientations: Orientation.All

    // The last result, shown under the section it belongs to ("backup", "csv",
    // "health" or "restore").
    property string statusMessage: ""
    property bool statusIsError: false
    property string statusFor: ""

    property var healthProblems: []
    property int profileCount: 0
    // What to do once a dialog or the file picker has closed.
    property var pending: null

    readonly property real contentWidth: Math.min(width, Screen.width * 1.25)

    function report(message, isError, section) {
        statusMessage = message;
        statusIsError = isError === true;
        statusFor = section;
    }

    function refresh() {
        var profiles = Database.profiles();
        profileCount = profiles.length;
        healthProblems = HealthExport.problems(profiles);
        refreshBackups();
    }

    function writeExport(directory, name, content, section) {
        if (directory === "") {
            report(appWindow.files.lastError(), true, section);
            return;
        }
        var path = directory + "/" + name;
        if (appWindow.files.writeFile(path, content)) {
            //: %1 is the path of the file just written
            report(qsTr("Saved to %1").arg(path), false, section);
        } else {
            report(appWindow.files.lastError(), true, section);
        }
    }

    function backUp() {
        var content;
        try {
            content = JSON.stringify(Database.exportBackup(), null, 2);
        } catch (error) {
            report(qsTr("Could not read the data: %1").arg(error.message), true, "backup");
            return;
        }
        writeExport(appWindow.files.exportDirectory(), appWindow.stampedName("weight-tracker-backup", ".json"),
                    content, "backup");
        refreshBackups();
    }

    function exportCsv() {
        writeExport(appWindow.files.exportDirectory(), appWindow.stampedName("weight-tracker-weights", ".csv"),
                    Database.exportCsv(), "csv");
    }

    /*
     * The Health backup. Its name ends in the date and time the way Health's own do,
     * so Health shows when it was made.
     */
    function exportHealth() {
        var profiles = Database.profiles();
        if (HealthExport.problems(profiles).length > 0) {
            report(qsTr("Fix the profiles listed above first."), true, "health");
            return;
        }
        var dump = HealthExport.build(profiles, Database.weights, appWindow.profileId, new Date());
        writeExport(appWindow.files.healthDirectory(), appWindow.stampedName("weight-tracker-to-health", ".json"),
                    JSON.stringify(dump, null, 2), "health");
    }

    function failureText(error) {
        switch (error && error.reason) {
        case "not-a-backup": return qsTr("This is not a Weight Tracker backup file.");
        case "newer-backup": return qsTr("This backup was made by a newer version of Weight Tracker. Update the app first.");
        case "no-profiles":  return qsTr("This backup contains no profiles.");
        default:
            return qsTr("Restore failed: %1").arg(error && error.message ? error.message : String(error))
                    + " " + qsTr("Nothing was changed.");
        }
    }

    // Reads a backup and asks before replacing anything, showing what it contains.
    function openBackup(path) {
        var content = appWindow.files.readFile(path);
        if (content === "") {
            report(appWindow.files.lastError() || qsTr("This backup file is empty."), true, "restore");
            return;
        }
        var dump;
        var info;
        try {
            try {
                dump = JSON.parse(content);
            } catch (syntaxError) {
                throw { reason: "not-a-backup" };
            }
            info = Database.inspectBackup(dump);
        } catch (error) {
            report(failureText(error), true, "restore");
            return;
        }
        report("", false, "");
        var dialog = pageStack.push(confirmComponent, {
            fileName: path.substring(path.lastIndexOf("/") + 1),
            info: info
        });
        dialog.accepted.connect(function () {
            page.pending = { action: "restore", dump: dump, path: path };
        });
    }

    function restore(path, dump) {
        // What is there now is kept first, so a restore of the wrong file can be undone
        // from this list. Without that copy, nothing is replaced.
        if (profileCount > 0 && !appWindow.saveCopy("before-restore", Database.exportBackup())) {
            report(qsTr("Could not save a safety copy, so nothing was changed: %1").arg(appWindow.files.lastError()),
                   true, "restore");
            return;
        }
        try {
            Database.restoreBackup(dump);
        } catch (error) {
            report(failureText(error), true, "restore");
            refresh();
            return;
        }
        //: %1 is the name of the backup file
        report(qsTr("Restored from %1").arg(path.substring(path.lastIndexOf("/") + 1)), false, "restore");
        appWindow.reloadProfile();
    }

    /*
     * The backups in Documents/WeightTracker and the app's own copies, newest first.
     * The Health backups in Documents/Health are not Weight Tracker's and are left out.
     */
    function refreshBackups() {
        var rows = [];
        var i;
        var exported = appWindow.files.exportDirectory();
        var paths = exported !== "" ? appWindow.files.listFiles(exported, ".json") : [];
        for (i = 0; i < paths.length; i++) {
            rows.push({ path: String(paths[i]), kind: "" });
        }
        var own = appWindow.files.backupDirectory();
        paths = own !== "" ? appWindow.files.listFiles(own, ".json") : [];
        for (i = 0; i < paths.length; i++) {
            var name = String(paths[i]).substring(String(paths[i]).lastIndexOf("/") + 1);
            rows.push({ path: String(paths[i]),
                        kind: name.indexOf("weight-tracker-before-upgrade") === 0 ? "before-upgrade" : "before-restore" });
        }
        for (i = 0; i < rows.length; i++) {
            var modified = appWindow.files.fileInfo(rows[i].path).modified;
            rows[i].modified = modified;
            rows[i].title = rows[i].kind === "" ? rows[i].path.substring(rows[i].path.lastIndexOf("/") + 1)
                                                : Utils.formatDate(new Date(modified)) + ", "
                                                  + Format.formatDate(new Date(modified), Formatter.TimeValue);
        }
        rows.sort(function (a, b) { return b.modified - a.modified; });
        backupModel.clear();
        for (i = 0; i < rows.length; i++) {
            backupModel.append(rows[i]);
        }
    }

    function kindText(kind) {
        switch (kind) {
        //: Marks the copy made of the data just before a restore replaced it
        case "before-restore": return qsTr("Before restore");
        //: Marks the copy made of the data just before the update to this version changed it
        case "before-upgrade": return qsTr("Before update");
        default: return "";
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && pending !== null) {
            pendingTimer.restart();
        }
    }

    // Not from the status handler itself: pushing a page while this one is still
    // settling as the active page is a binding loop on its status.
    Timer {
        id: pendingTimer
        interval: 50
        onTriggered: {
            if (page.status !== PageStatus.Active || page.pending === null) {
                return;
            }
            if (pageStack.busy) {
                restart();
                return;
            }
            var todo = page.pending;
            page.pending = null;
            if (todo.action === "restore") {
                page.restore(todo.path, todo.dump);
            } else if (todo.action === "open") {
                page.openBackup(todo.path);
            }
        }
    }

    Connections {
        target: appWindow
        onRevisionChanged: page.refresh()
    }
    Component.onCompleted: refresh()

    Component {
        id: confirmComponent

        Dialog {
            id: confirm

            property string fileName
            property var info

            allowedOrientations: Orientation.All

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: confirmColumn.height + Theme.paddingLarge

                Column {
                    id: confirmColumn
                    width: parent.width
                    spacing: Theme.paddingLarge

                    DialogHeader {
                        title: qsTr("Restore this backup?")
                        acceptText: qsTr("Restore")
                    }

                    Card {
                        Label {
                            width: parent.width
                            wrapMode: Text.WrapAnywhere
                            text: confirm.fileName
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            visible: confirm.info.exportedAt !== ""
                            //: When a backup was made, %1 is a date
                            text: qsTr("Made on %1").arg(Utils.formatDate(confirm.info.exportedAt.substring(0, 10)))
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            //: %1 is a list of names
                            text: qsTr("Profiles: %1").arg(confirm.info.profiles.join(", "))
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: qsTr("%n weight(s)", "", confirm.info.entries)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primaryColor
                        }
                    }

                    Row {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        spacing: Theme.paddingMedium
                        Icon {
                            id: confirmIcon
                            source: "image://theme/icon-m-warning"
                            color: Theme.highlightColor
                        }
                        Label {
                            width: parent.width - confirmIcon.width - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            wrapMode: Text.Wrap
                            text: qsTr("Everything now in Weight Tracker is replaced. A copy of it is kept first, in the restore list.")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.highlightColor
                        }
                    }
                }
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                //: Menu item: pick a backup file from Downloads or a memory card
                text: qsTr("Restore from another folder")
                onClicked: {
                    var picker = pageStack.push(Qt.resolvedUrl("PickBackupPage.qml"));
                    picker.picked.connect(function (path) {
                        page.pending = { action: "open", path: path };
                    });
                }
            }
        }

        Column {
            id: column

            anchors.horizontalCenter: parent.horizontalCenter
            width: page.contentWidth
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Backup and export")
            }

            // --- back up ------------------------------------------------------------
            Card {
                visible: page.profileCount > 0
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    text: qsTr("Back up")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Saves every profile and weight to a file in Documents/WeightTracker. Copy it somewhere safe, or to another phone to restore it there.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: Theme.buttonWidthLarge
                    text: qsTr("Back up now")
                    onClicked: page.backUp()
                }
                StatusLine {
                    message: page.statusFor === "backup" ? page.statusMessage : ""
                    isError: page.statusIsError
                }
            }

            // --- spreadsheet --------------------------------------------------------
            Card {
                visible: page.profileCount > 0
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    text: qsTr("Spreadsheet")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Saves every weight to a CSV file in Documents/WeightTracker, for a spreadsheet. CSV files cannot be restored.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: Theme.buttonWidthLarge
                    text: qsTr("Export CSV")
                    onClicked: page.exportCsv()
                }
                StatusLine {
                    message: page.statusFor === "csv" ? page.statusMessage : ""
                    isError: page.statusIsError
                }
            }

            // --- move to Health -----------------------------------------------------
            Card {
                visible: page.profileCount > 0
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    text: qsTr("Move to Health")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Health, the app that follows Weight Tracker, can take your profiles, weights, heights and target weights. This saves them as a Health backup in Documents/Health.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("In Health, choose Restore a backup on its welcome screen, or Backup and restore in its menu. Restoring replaces everything already in Health, so do it before you start using Health.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                }

                // Profiles Health would refuse: it needs both names and a birthday.
                Repeater {
                    model: page.healthProblems

                    Row {
                        width: parent.width
                        spacing: Theme.paddingMedium
                        Icon {
                            id: problemIcon
                            source: "image://theme/icon-s-warning"
                            color: Theme.highlightColor
                        }
                        Label {
                            width: parent.width - problemIcon.width - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            wrapMode: Text.Wrap
                            //: %1 is a profile's name
                            text: qsTr("%1: edit the profile to pick its birthday again.")
                                  .arg((modelData.firstName + " " + modelData.lastName).trim())
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.highlightColor
                        }
                    }
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: Theme.buttonWidthLarge
                    enabled: page.healthProblems.length === 0
                    text: qsTr("Create Health backup")
                    onClicked: page.exportHealth()
                }
                StatusLine {
                    message: page.statusFor === "health" ? page.statusMessage : ""
                    isError: page.statusIsError
                }
            }

            // --- restore ------------------------------------------------------------
            SectionHeader {
                text: qsTr("Restore")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Backups in Documents/WeightTracker, and the copies kept before a restore or an update. Restoring one replaces all data in Weight Tracker. To restore a file from somewhere else, pull down.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
            }

            StatusLine {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                message: page.statusFor === "restore" ? page.statusMessage : ""
                isError: page.statusIsError
            }

            Column {
                width: parent.width
                spacing: Theme.paddingMedium

                Repeater {
                    model: ListModel {
                        id: backupModel
                    }

                    delegate: BackgroundItem {
                        id: backupRow
                        width: parent.width
                        height: Math.max(Theme.itemSizeMedium, backupText.height + 2 * Theme.paddingMedium)
                        highlightedColor: "transparent"
                        onClicked: page.openBackup(model.path)

                        CardBackground {
                            x: Theme.horizontalPageMargin
                            width: parent.width - 2 * Theme.horizontalPageMargin
                            height: parent.height
                            highlighted: backupRow.highlighted
                        }
                        Icon {
                            id: backupIcon
                            x: Theme.horizontalPageMargin + Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter
                            source: "image://theme/icon-m-backup"
                            highlighted: backupRow.highlighted
                        }
                        Column {
                            id: backupText
                            anchors.left: backupIcon.right
                            anchors.leftMargin: Theme.paddingLarge
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.horizontalPageMargin + Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.paddingSmall

                            Label {
                                width: parent.width
                                wrapMode: Text.WrapAnywhere
                                text: model.title
                                font.pixelSize: Theme.fontSizeSmall
                                color: backupRow.highlighted ? Theme.highlightColor : Theme.primaryColor
                            }
                            StatusPill {
                                text: page.kindText(model.kind)
                                dotColor: Theme.secondaryHighlightColor
                                highlighted: backupRow.highlighted
                            }
                        }
                    }
                }
            }

            Card {
                visible: backupModel.count === 0
                subtle: true

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("No backups found")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                }
            }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
