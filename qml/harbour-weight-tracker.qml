import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.weight.tracker.FileWriter 1.0
import "pages"
import "js/Database.js" as Database

/*
 * The window holds what every page and the cover share: the profile shown, and a
 * revision number that goes up after every change to the data. Pages and the cover
 * reload when either changes, instead of calling each other's load() as version 1.3
 * did (through previousPage() and the page stack depth).
 */
ApplicationWindow {
    id: appWindow

    // The profile shown, -1 without any.
    property int profileId: -1
    property int revision: 0
    // Set once the database is open and upgraded; pages wait for it.
    property bool ready: false
    // Why the database could not be opened, shown on the main page.
    property string databaseError: ""

    readonly property alias files: fileWriter

    // After every write to the data.
    function changed() {
        revision++;
    }

    function selectProfile(code) {
        Database.setCurrentProfile(code);
        profileId = code;
        changed();
    }

    // After a restore or a profile deletion: back to whatever profile is current.
    function reloadProfile() {
        profileId = Database.currentProfile();
        changed();
    }

    function stampedName(prefix, suffix) {
        var now = new Date();
        function pad(n) { return (n < 10 ? "0" : "") + n; }
        return prefix + "-" + now.getFullYear() + "-" + pad(now.getMonth() + 1) + "-" + pad(now.getDate())
                + "-" + pad(now.getHours()) + pad(now.getMinutes()) + suffix;
    }

    /*
     * A private copy of all data, before something replaces it ("before-upgrade",
     * "before-restore"). The last five of each kind are kept. Returns whether it was saved.
     */
    function saveCopy(kind, dump) {
        var directory = fileWriter.backupDirectory();
        if (directory === "") {
            return false;
        }
        var prefix = "weight-tracker-" + kind;
        if (!fileWriter.writeFile(directory + "/" + stampedName(prefix, ".json"), JSON.stringify(dump))) {
            return false;
        }
        var existing = fileWriter.listFiles(directory, ".json").filter(function (path) {
            return path.substring(path.lastIndexOf("/") + 1).indexOf(prefix + "-") === 0;
        });
        for (var i = 5; i < existing.length; i++) {
            fileWriter.removeFile(existing[i]);
        }
        return true;
    }

    // --- shared with the BMI pages (the same words as Simple BMI Calculator) ---------

    function formatNumber(value, decimals) {
        return Number(value).toLocaleString(Qt.locale(), "f", decimals);
    }

    function formatMeasure(value) {
        return formatNumber(value, Math.round(value * 10) % 10 === 0 ? 0 : 1);
    }

    function categoryName(index) {
        switch (index) {
        case 0: return qsTr("Underweight");
        case 1: return qsTr("Normal weight");
        //: The WHO calls it pre-obesity
        case 2: return qsTr("Overweight");
        case 3: return qsTr("Obesity class I");
        case 4: return qsTr("Obesity class II");
        case 5: return qsTr("Obesity class III");
        default: return "";
        }
    }

    function categoryDescription(index) {
        switch (index) {
        case 0: return qsTr("Your weight is below the healthy range for adults of your height. Talk to your doctor for medical advice.");
        case 1: return qsTr("Your weight is in the healthy range for adults of your height.");
        case 2: return qsTr("Your weight is above the healthy range for adults of your height. Talk to your doctor for medical advice.");
        case 3:
        case 4:
        case 5: return qsTr("Your weight is well above the healthy range for adults of your height. People with obesity are at higher risk of conditions such as high blood pressure, diabetes and high cholesterol. Talk to your doctor for medical advice.");
        default: return "";
        }
    }

    FileWriter {
        id: fileWriter
    }

    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    /*
     * Opens the database. A database of version 1.x is upgraded (Database.init), after
     * a copy of it is saved: the upgrade rewrites the user's only copy of their data.
     */
    Component.onCompleted: {
        try {
            if (Database.storedSchemaVersion() === 1) {
                if (!saveCopy("before-upgrade", Database.exportBackup())) {
                    console.warn("Could not save a copy before the upgrade:", fileWriter.lastError());
                }
            }
            Database.init(Qt.locale());
            profileId = Database.currentProfile();
        } catch (error) {
            databaseError = error.reason === "schema-newer"
                    ? qsTr("Your data was saved by a newer version of Weight Tracker. Update the app to open it.")
                    : qsTr("The data could not be opened: %1").arg(error.message);
        }
        ready = true;
    }
}

// vim:et:ts=4:sw=4
