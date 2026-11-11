import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

/*
 * Picks a backup file from anywhere the app may read: Documents, Downloads or a memory
 * card (see Permissions in harbour-weight-tracker.desktop). A page of its own, as in
 * Health, so the Backup and export page still loads should Sailfish.Pickers be missing.
 */
FilePickerPage {
    id: picker

    // The path of the file that was chosen. The page closes itself after it.
    signal picked(string path)

    //: Title of the page for choosing a backup file to restore
    title: qsTr("Choose a backup")
    nameFilters: ["*.json"]

    onSelectedContentPropertiesChanged: {
        if (selectedContentProperties !== null && selectedContentProperties.filePath) {
            picker.picked(String(selectedContentProperties.filePath));
        }
    }
}

// vim:et:ts=4:sw=4
