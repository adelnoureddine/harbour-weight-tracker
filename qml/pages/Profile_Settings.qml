import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page
    allowedOrientations: Orientation.All

    property int user_code
    property string user_lastname;
    property string user_firstname;
    property string user_gender;
    property string user_birthday;
    property double user_height;
    property Page rootPage

    function load(){
        getLastname()
        getFirstname()
        getGender()
        getBirthday()
        getHeight()
    }

    function getLastname (){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM USERS WHERE USER_CODE=?',[user_code])
                if(rs.rows.length > 0){
                    user_lastname = rs.rows.item(0).LASTNAME;
                }
            }
        )
    }

    function getFirstname (){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM USERS WHERE USER_CODE=?',[user_code])
                if(rs.rows.length > 0){
                    user_firstname = rs.rows.item(0).FIRSTNAME;
                }
            }
        )
    }

    function getGender (){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM USERS WHERE USER_CODE=?',[user_code])
                if(rs.rows.length > 0){
                    user_gender = rs.rows.item(0).GENDER;
                }
            }
        )
    }

    function getBirthday (){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM USERS WHERE USER_CODE=?',[user_code])
                if(rs.rows.length > 0){
                    user_birthday = rs.rows.item(0).BIRTHDAY;
                }
            }
        )
    }

    function getHeight (){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM USERS WHERE USER_CODE=?',[user_code])
                if(rs.rows.length > 0){
                    user_height = rs.rows.item(0).HEIGHT;
                }
            }
        )
    }

    function updateLastname (lastname){

        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                tx.executeSql('UPDATE USERS SET LASTNAME=? WHERE USER_CODE=?',[lastname,user_code])
            }
        )
        lastnameValue.text = lastname

    }
    function updateFirstname (firstname){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                tx.executeSql('UPDATE USERS SET FIRSTNAME=? WHERE USER_CODE=?',[firstname,user_code])
            }
        )
        firstnameValue.text = firstname
    }
    function updateGender (gender){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                tx.executeSql('UPDATE USERS SET GENDER=? WHERE USER_CODE=?',[gender,user_code])
            }
        )
        genderValue.text = gender
    }
    function updateBirthday (birthday){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                tx.executeSql('UPDATE USERS SET BIRTHDAY=? WHERE USER_CODE=?',[birthday,user_code])
            }
        )
        birthdayValue.text = birthday
    }
    function updateHeight (height){
        height = height.replace(',', '.');
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                tx.executeSql('UPDATE USERS SET HEIGHT=? WHERE USER_CODE=?',[height,user_code])
            }
        )
        heightValue.text = height + " cm"
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: mainColumn.height

        PullDownMenu {
            MenuItem {
                text: "Remove Profile"
                onClicked: pageStack.animatorPush(removeAccept)
            }
            MenuItem {
                text: "Modify Profile"
                onClicked: pageStack.animatorPush(dialogPage)
            }


            MenuLabel { text: "Manage Profile" }
        }

        Column {
            id: mainColumn
            x: Theme.paddingLarge
            width:page.width
            spacing: Theme.paddingLarge

            PageHeader{
                title: qsTr("Profile Settings")
            }

            Row{//FIRSTNAME
                id: firstnameRow

                Label {
                    text: qsTr("First name :")
                    width:page.width / 2.5
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    id:firstnameValue
                    text:user_firstname
                    width:page.width / 1.5
                    color: Theme.secondaryColor
                }
            }

            Row{ //LASTNAME
                id: lastnameRow

                Label {
                    text: qsTr("Last name :")
                    width:page.width / 2.5
                    color: Theme.secondaryHighlightColor

                }
                Label {
                    id:lastnameValue
                    text:user_lastname
                    width:page.width / 1.5
                    color: Theme.secondaryColor
                }

            }

            Row{//GENDER
                id: genderRow

                Label {
                    text: qsTr("Gender :")
                    width:page.width / 2.5
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    id:genderValue
                    text:user_gender
                    width:page.width / 1.5
                    color: Theme.secondaryColor
                }
            }

            Row{//BIRTHDAY
                id: birthdayRow

                Label {
                    text: qsTr("Birthday :")
                    width:page.width / 2.5
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    id:birthdayValue
                    text:user_birthday
                    width:page.width / 1.5
                    color: Theme.secondaryColor
                }
            }

            Row{//HEIGHT
                id: heightRow

                Label {
                    text: qsTr("Height :")
                    width:page.width / 2.5
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    id:heightValue
                    text:user_height + " cm"
                    width:page.width / 1.5
                    color: Theme.secondaryColor
                }
            }


            Component {
                id: dialogPage

                Dialog {
                    canAccept: lastnameField.text!="" && firstnameField.text!="" && genderField.text!="" && birthdayField.value!="" && heightField.text!="" && heightField.acceptableInput
                    acceptDestination: page
                    acceptDestinationAction: PageStackAction.Pop


                    Flickable {
                        width: parent.width
                        height: parent.height

                        Column {
                            id: dialogColumn
                            x: Theme.paddingLarge
                            width: page.width
                            spacing: Theme.paddingLarge

                            DialogHeader {
                                title: "Modify your profile"
                            }

                            TextField {
                                id : firstnameField
                                width: page.width
                                text: user_firstname
                                label: "First name"
                            }

                            TextField{
                                id : lastnameField
                                width: page.width
                                text: user_lastname
                                label: "Last name"
                            }

                            ComboBox {
                                function getCurrentIndex(){
                                    if (user_gender === "M") return 1
                                    if (user_gender === "F") return 0
                                }

                                id:genderField
                                currentIndex: getCurrentIndex()
                                menu: ContextMenu {
                                    MenuItem { text: "F" }
                                    MenuItem { text: "M" }
                                }
                                width: page.width
                                label: "Gender"
                            }

                            ValueButton {
                                property date selectedDate

                                function openDateDialog() {
                                    var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog",
                                                                     { date: selectedDate })

                                    obj.pageCompleted.connect(function(page) {
                                        page.accepted.connect(function() {
                                            //value = page.dateText
                                            selectedDate = page.date
                                            value = selectedDate.toLocaleDateString("yyyy-MM-dd")
                                        })
                                    })
                                }

                                id : birthdayField
                                value: Qt.formatDate(new Date(user_birthday))
                                width: page.width
                                onClicked: openDateDialog()
                                label: "Birthday"
                            }

                            TextField{
                                id : heightField
                                width:page.width / 1.5
                                text: user_height
                                label: "Height (in cm)"
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                                EnterKey.onClicked: phoneField.focus = true
                                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                            }
                        }
                    }

                    onAccepted: {
                        updateLastname(lastnameField.text)
                        updateFirstname(firstnameField.text)
                        updateGender(genderField.currentItem.text)
                        updateBirthday(birthdayField.value)
                        updateHeight(heightField.text)
                        rootPage.load();
                    }

                }
            }

            Component {
                id: removeAccept

                Dialog {
                    acceptDestination: rootPage
                    acceptDestinationAction: PageStackAction.Pop
                    Flickable {
                        width: parent.width
                        height: parent.height

                        Column {
                            id: mainColumn
                            x: Theme.paddingLarge
                            width: page.width
                            spacing: Theme.paddingLarge
                            DialogHeader {
                                title: "Delete this profile ?"
                            }


                            Row{//FIRSTNAME
                                id: firstnameRow

                                Label {
                                    text: qsTr("First name :")
                                    width:page.width / 2.5
                                    color: Theme.secondaryHighlightColor
                                }
                                Label {
                                    id:firstnameValue
                                    text:user_firstname
                                    width:page.width / 1.5
                                    color: Theme.secondaryColor
                                }
                            }

                            Row{ //LASTNAME
                                Label {
                                    text: qsTr("Last name :")
                                    width:page.width / 2.5
                                    color: Theme.secondaryHighlightColor

                                }
                                Label {
                                    id:lastnameValue
                                    text:user_lastname
                                    width:page.width / 1.5
                                    color: Theme.secondaryColor
                                }

                            }

                            Row{//GENDER
                                id: genderRow

                                Label {
                                    text: qsTr("Gender :")
                                    width:page.width / 2.5
                                    color: Theme.secondaryHighlightColor
                                }
                                Label {
                                    id:genderValue
                                    text:user_gender
                                    width:page.width / 1.5
                                    color: Theme.secondaryColor
                                }
                            }

                            Row{//BIRTHDAY
                                id: birthdayRow

                                Label {
                                    text: qsTr("Birthday :")
                                    width:page.width / 2.5
                                    color: Theme.secondaryHighlightColor
                                }
                                Label {
                                    id:birthdayValue
                                    text:user_birthday
                                    width:page.width / 1.5
                                    color: Theme.secondaryColor
                                }
                            }

                            Row{//HEIGHT
                                id: heightRow

                                Label {
                                    text: qsTr("Height :")
                                    width:page.width / 2.5
                                    color: Theme.secondaryHighlightColor
                                }
                                Label {
                                    id:heightValue
                                    text:user_height + " cm"
                                    width:page.width / 1.5
                                    color: Theme.secondaryColor
                                }
                            }
                        }

                    }
                    onAccepted: {
                        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                        db.transaction(
                            function(tx){
                                tx.executeSql('DELETE FROM METRICS WHERE USER_CODE=?',[user_code])
                                tx.executeSql('DELETE FROM USERS WHERE USER_CODE=?',[user_code])
                                tx.executeSql('DELETE FROM SETTINGS WHERE USER_CODE=?',[user_code])
                            }
                        )
                        rootPage.user_code=""
                        rootPage.load()
                    }

                }
            }

            Component.onCompleted:{
                rootPage=previousPage()
                user_code=rootPage.user_code
                load()
            }
        }

    }
}
