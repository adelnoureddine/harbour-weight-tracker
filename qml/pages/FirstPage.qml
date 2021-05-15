import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

import "../js/utils.js" as WtUtils

Page {
    id: root
    allowedOrientations: Orientation.All

    property variant usercodes: []
    property int currentProfileIndex
    property string user_description;
    property string u_height;
    property string u_weight;
    property string user_code;
    property double bmi: 0.0;
    property double height_square: 0.0;
    property double recommended_min_weight: 0.0;
    property double recommended_max_weight: 0.0;
    property string recommended_weight_description;
    property string category_bmi;
    property string category_bmi_description;
    property string slider_color;
    property bool profiles;
    property variant wtData;

    function getProfiles(){
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM USERS');
                if(rs.rows.length > 0){
                    profiles = true;
                }
                else profiles=false;
        })
    }

    function load() {
        wtData = WtUtils.info_user(user_code);

        user_description = "Welcome " + wtData.firstname + " " + wtData.lastname + "!"
        u_height = " Height: " + wtData.height + " cm"
        u_weight = " Weight: " + wtData.weight + " kg"

        calculate();
        getProfiles();
    }

    function loadUser(val) {
        user_code=val;
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                tx.executeSql('UPDATE SETTINGS USER_CODE=?',[user_code]);
            })
    }

    function calculate() {
        var user_height = wtData.height / 100
        height_square = (user_height * user_height)
        if ((wtData.weight > 0) && (user_height > 0)) {
            bmi = wtData.weight / height_square;
            recommended_min_weight = 18.5 * height_square
            recommended_max_weight = 24.9 * height_square
            recommended_weight_description = "The recommended weight for your height is between " + recommended_min_weight.toFixed(2) + " kg and " + recommended_max_weight.toFixed(2) + " kg"
            calculate_bmi_category();
        }
    }

    function calculate_bmi_category() {
        if (bmi < 18.5) {
            category_bmi = "Underweight";
            slider_color = "#2eb3db";
            category_bmi_description = "Your weight is under the recommended values. Talk to your doctor for medical advice."
        } else if (bmi < 25) {
            category_bmi = "Normal weight";
            slider_color = "#14f52a";
            category_bmi_description = "Your weight is in the normal category for adults of your height."
        } else if (bmi < 30) {
            category_bmi = "Overweight (pre-obesity)";
            slider_color = "yellow";
            category_bmi_description = "Your weight is above the recommended values. Talk to your doctor for medical advice."
        } else if (bmi < 35) {
            category_bmi = "Obese Class I";
            slider_color = "orange";
            category_bmi_description = "Your weight is high above the recommended values. People who are overweight or obese are at higher risk for chronic conditions such as high blood pressure, diabetes, and high cholesterol. Talk to your doctor for medical advice."
        } else if (bmi < 40) {
            category_bmi = "Obese Class II";
            slider_color = "red";
            category_bmi_description = "Your weight is high above the recommended values. People who are overweight or obese are at higher risk for chronic conditions such as high blood pressure, diabetes, and high cholesterol. Talk to your doctor for medical advice."
        } else if (bmi >= 40) {
            category_bmi = "Obese Class III";
            slider_color = "red";
            category_bmi_description = "Your weight is high above the recommended values. People who are overweight or obese are at higher risk for chronic conditions such as high blood pressure, diabetes, and high cholesterol. Talk to your doctor for medical advice."
        } else {
            category_bmi = "Unkown category";
            slider_color = "white";
            category_bmi_description = ""
        }
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: "About"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./About.qml'))
            }
            MenuItem {
                visible: user_code!=''
                text: "Settings"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./Profile_Settings.qml'))
            }
            MenuItem {
                visible: profiles==true
                text: "Change Profile"
                onClicked: pageStack.animatorPush(changeProfile)
            }
            MenuItem {
                visible: user_code!=''
                text: "History"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./History.qml'))
            }
            MenuItem {
                visible: user_code!=''
                text: "Add metric"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./AddMetric.qml'))
            }
            MenuItem {
                visible: user_code=='' && profiles ==false
                text: "Create Profile"
                onClicked:pageStack.animatorPush(createProfile)
            }

            MenuLabel { text: "Menu" }
        }

        contentHeight: column.height

         Column {
             id: column
             x: Theme.paddingLarge
             width: parent.width - 2*x
             spacing: Theme.paddingLarge
             PageHeader { title: "Weight Tracker"}




             ViewPlaceholder {
                 enabled: user_code=='' && profiles==false
                 text: "No profile created"
                 hintText: "Swipe down to create one !"
             }

             ViewPlaceholder {
                 enabled: user_code=='' && profiles==true
                 text: "No profile selected"
                 hintText: "Swipe down to select one !"
             }
            //Welcome user
             Label {
                 visible: user_code!=''
                 x: Theme.horizontalPageMargin
                 width: parent.width
                 text: user_description
                 color: Theme.highlightColor
                 font.pixelSize: Theme.fontSizeLarge
             }

             // Height
             Label {
                 visible: user_code!=''
                 wrapMode: Text.Wrap
                 width: parent.width
                 text: u_height
                 color: 'white'
             }

             ViewPlaceholder {
                 enabled: wtData.weight==0 && user_code!=''
                 text: "No metrics avaible"
                 hintText: "Pull down to add metrics"
             }

             // Weight
             Label {
                 visible: wtData.weight!==0
                 wrapMode: Text.Wrap
                 width: parent.width
                 text: u_weight
                 color: 'white'
             }

             // BMI value
             Label {
                 visible: wtData.weight!==0
                 text: "Your BMI is"
                 color: Theme.highlightColor
                 font.pixelSize: Theme.fontSizeLarge
                 anchors.left: parent.left
                 anchors.leftMargin: 30
             }

             Slider {
                 visible: wtData.weight!==0
                 id: changingSlider
                 value: bmi
                 minimumValue: 0
                 maximumValue: 50
                 stepSize: 10
                 width: parent.width
                 handleVisible: false
                 enabled: handleVisible
                 valueText : bmi.toFixed(2)
                 label: category_bmi
                 valueLabelColor: slider_color
                 backgroundColor: slider_color
                 color: slider_color
            }

             // Description
             Label {
                 visible: wtData.weight!==0
                 text: "Description"
                 color: Theme.highlightColor
                 font.pixelSize: Theme.fontSizeLarge
                 anchors.left: parent.left
                 anchors.leftMargin: 30
             }

             // Recommended weight
             Label {
                 visible: wtData.weight!==0
                 wrapMode: Text.Wrap
                 width: parent.width
                 text: recommended_weight_description
                 color: 'white'
             }

             // BMI category description
             Label {
                 visible: wtData.weight!==0
                 wrapMode: Text.Wrap
                 width: parent.width
                 text: category_bmi_description
                 color: 'white'
             }

             Component {
                 id: createProfile

                 Dialog {
                     canAccept: lastnameField.text!="" && firstnameField.text!="" && genderField.text!="" && birthdayField.value!="" && heightField.acceptableInput
                     acceptDestination: root

                     acceptDestinationAction: PageStackAction.Pop

                     onAcceptPendingChanged: {
                         if (acceptPending) {
                             var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                             db.transaction(
                                 function(tx){
                                     var code
                                     var rs = tx.executeSql('SELECT MAX(USER_CODE) AS USER_CODE FROM USERS');
                                     if(rs.rows.item(0)===null) code = 1
                                     else{
                                         code = (rs.rows.item(0).USER_CODE) + 1;
                                     }
                                     tx.executeSql('INSERT INTO USERS VALUES (?,?,?,?,?,?)',[code,lastnameField.text,firstnameField.text,genderField.currentItem.text,birthdayField.value,heightField.text]);
                                     rs = tx.executeSql('SELECT * FROM SETTINGS');
                                     if(rs.rows.length===0) tx.executeSql('INSERT INTO SETTINGS VALUES (?)',[code]);
                                     else tx.executeSql('UPDATE SETTINGS SET USER_CODE=?',[code]);

                                     user_code=code;
                                 }
                             )
                             root.load()
                             load()
                         }
                     }

                     Flickable {
                         // ComboBox requires a flickable ancestor
                         width: parent.width
                         height: parent.height
                         interactive: false

                         Column {
                             width: parent.width

                             DialogHeader {
                                 title: "Create your profile"
                             }
                             TextField{
                                 id : firstnameField
                                 width:parent.width
                                 label: "First name";
                                 placeholderText: label
                             }
                             TextField{
                                 id : lastnameField
                                 width:parent.width
                                 label: "Last name";
                                 placeholderText: label
                             }
                             ComboBox {
                                 id:genderField
                                 label: "Gender"
                                 menu: ContextMenu {
                                     MenuItem { text: "F" }
                                     MenuItem { text: "M" }
                                 }
                                 width: parent.width/2
                             }
                             ValueButton {
                                 property date selectedDate

                                 function openDateDialog() {
                                     var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog",
                                                                      { date: selectedDate })

                                     obj.pageCompleted.connect(function(page) {
                                         page.accepted.connect(function() {
                                             selectedDate = page.date
                                             value = selectedDate.toLocaleDateString("yyyy-MM-dd")
                                         })
                                     })
                                 }

                                 label: "Birthday date"
                                 id : birthdayField
                                 width: parent.width
                                 onClicked: openDateDialog()
                             }
                             TextField{
                                 id : heightField
                                 width:parent.width
                                 label: "Height(cm)"; placeholderText: label
                                 inputMethodHints: Qt.ImhFormattedNumbersOnly
                                 EnterKey.iconSource: "image://theme/icon-m-enter-next"
                                 EnterKey.onClicked: phoneField.focus = true
                                 validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                             }

                             }
                         }
                     }
                 }
                 Component {
                     id: changeProfile

                     Page {
                         anchors.fill: parent
                         Column {
                             width: parent.width
                             PageHeader {
                                 title: "Change Profile"
                             }
                             ListModel{
                                 id:listModel

                                 Component.onCompleted:{
                                     listModel.load()
                                     profileList.currentIndex=currentProfileIndex
                                 }

                                 function load() {
                                     listModel.clear()
                                     var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                                     db.transaction(
                                         function(tx){
                                             var rs = tx.executeSql('SELECT * FROM USERS');
                                             for(var i =0; i< rs.rows.length;i++){
                                                 listModel.append({text: rs.rows.item(i).FIRSTNAME});
                                                 usercodes[i]=rs.rows.item(i).USER_CODE;
                                                 if(usercodes[i]==user_code) currentProfileIndex=i;

                                             }
                                         }
                                     )
                                 }
                             }
                             ComboBox {

                                 id: profileList
                                 label: "Profiles"
                                 menu: ContextMenu {
                                     Repeater{
                                         model: listModel

                                         MenuItem {text: modelData;onClicked:{
                                                 user_code=usercodes[index]
                                                 currentProfileIndex=index
                                                 var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                                                 db.transaction(
                                                     function(tx){
                                                         var rs = tx.executeSql('SELECT * FROM SETTINGS');
                                                         if(rs.rows.length===0) tx.executeSql('INSERT INTO SETTINGS VALUES (?)',[user_code]);
                                                         else tx.executeSql('UPDATE SETTINGS SET USER_CODE=?',[user_code]);
                                                     }
                                                 )
                                             root.load()
                                             pageStack.pop()}}
                                     }

                                 }
                             }
                             Button {
                                 text: "Create New Profile"
                                 anchors.horizontalCenter: parent.horizontalCenter
                                 onClicked: pageStack.animatorPush(createProfile)
                             }
                         }

                     }
                 }
             }

             Component.onCompleted:{
                 user_code = WtUtils.getLastUser()
                 load()
             }
         }
}
