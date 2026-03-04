import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtMultimedia 5.15

ApplicationWindow {
    id: window
    visible: true
    width: 600
    height: 700
    title: "Barcode Scanner Pro"
    
    // Theme setup to match main application style
    Material.theme: Material.Light
    Material.accent: "#F49000"
    Material.primary: "#1F1F1F"
    color: "#f0f2f5"
    
    // Function to handle Ring callbacks for setting barcode
    function setScannedBarcode(barcode) {
        barcodeField.text = barcode;
    }
    
    // Function to handle Ring callback for save result
    function onSaveResult(success, msg) {
        if (success) {
            toast.show("Data saved successfully!");
            clearForm();
        } else {
            toast.show("Failed to save: " + msg);
        }
    }
    
    function clearForm() {
        barcodeField.text = "";
        overtimeField.value = 0;
        notesField.text = "";
        updateDateTime();
    }
    
    function submitData() {
        if (barcodeField.text.trim() === "") {
            toast.show("Barcode cannot be empty!");
            return;
        }
        if (datetimeField.text.trim() === "") {
            toast.show("Date is mandatory!");
            return;
        }
        // Call save backend
        Ring.callFunc("backend_saveData", [
            barcodeField.text,
            datetimeField.text,
            overtimeField.value,
            notesField.text
        ]);
    }
    
    function updateDateTime() {
        var now = new Date();
        datetimeField.text = Qt.formatDateTime(now, "dd/MM/yyyy");
    }
    
    Component.onCompleted: {
        updateDateTime();
    }

    Connections {
        target: typeof ringBridge !== "undefined" ? ringBridge : null
        function onTextChanged() {
            var val = ringBridge.text;
            if (val.indexOf("barcode:") === 0) {
                setScannedBarcode(val.substring(8));
                cameraPopup.close();
                toast.show("Barcode scanned successfully!");
                // Notice: DO NOT auto-submit here per user request!
            } else if (val.indexOf("toast:") === 0) {
                toast.show(val.substring(6));
            } else if (val.indexOf("save_result:") === 0) {
                var data = val.substring(12).split(";");
                onSaveResult(data[0] === "1", data[1]);
            }
        }
    }

    // Top Header
    Rectangle {
        id: header
        width: parent.width
        height: 80
        color: "#F49000"
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            
            Text {
                text: "Barcode Auto-Scanner"
                font.pixelSize: 24
                font.bold: true
                color: "white"
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            Image {
                source: "qrc:/logo.ico"
                sourceSize.width: 40
                sourceSize.height: 40
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Main Content
    ScrollView {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        clip: true

        ColumnLayout {
            width: parent.width - 40 // Adjust for margins
            spacing: 20
            
            // Card container
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: contentCol.implicitHeight + 40
                color: "white"
                radius: 12
                layer.enabled: true
                
                ColumnLayout {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15
                    
                    Text {
                        text: "Scan & Register"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#333333"
                    }
                    
                    // Barcode Field with inline Scanner Button
                    RowLayout {
                        Layout.fillWidth: true
                        
                        TextField {
                            id: barcodeField
                            placeholderText: "Enter or Scan Barcode..."
                            Layout.fillWidth: true
                            font.pixelSize: 16
                            
                            // Scanner Icon Component inside TextField
                            background: Rectangle {
                                implicitWidth: 200
                                implicitHeight: 40
                                border.color: barcodeField.activeFocus ? Material.accent : "#E0E0E0"
                                border.width: barcodeField.activeFocus ? 2 : 1
                                radius: 4
                                
                                // Scanner Icon Button on the right inside the field
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 32
                                    height: 32
                                    color: "transparent"
                                    radius: 4
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "📷" // Camera/Scanner icon
                                        font.pixelSize: 18
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            cameraPopup.open();
                                        }
                                    }
                                }
                            }
                            
                            // Auto-submit when manual barcode scanner hits "Enter"
                            onAccepted: {
                                submitData();
                            }
                        }
                    }
                    
                    // Date Time
                    TextField {
                        id: datetimeField
                        Layout.fillWidth: true
                        font.pixelSize: 16
                        placeholderText: "Date (dd/mm/yyyy)"
                        
                        // Optional Calendar Icon Representation
                        background: Rectangle {
                            implicitWidth: 200
                            implicitHeight: 40
                            border.color: datetimeField.activeFocus ? Material.accent : "#E0E0E0"
                            border.width: datetimeField.activeFocus ? 2 : 1
                            radius: 4
                            
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "📅"
                                font.pixelSize: 18
                            }
                        }
                    }
                    
                    // Overtime
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Overtime (Hours):"
                            font.pixelSize: 16
                            color: "#333333"
                        }
                        SpinBox {
                            id: overtimeField
                            from: 0
                            to: 24
                            value: 0
                            Layout.fillWidth: true
                        }
                    }
                    
                    // Notes
                    TextArea {
                        id: notesField
                        placeholderText: "Additional Notes..."
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        font.pixelSize: 16
                        wrapMode: TextEdit.WordWrap
                        background: Rectangle {
                            border.color: "#E0E0E0"
                            border.width: 1
                            radius: 4
                        }
                    }
                    
                    Item { Layout.preferredHeight: 10 } // Spacer
                    
                    // Submit
                    Button {
                        text: "Save & Send"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        font.pixelSize: 16
                        font.bold: true
                        Material.background: "#F49000"
                        Material.foreground: "white"
                        onClicked: {
                            submitData();
                        }
                    }
                }
            }
        }
    }
    
    // Custom Toast Notification
    Rectangle {
        id: toast
        width: toastText.implicitWidth + 40
        height: toastText.implicitHeight + 20
        color: "#333333"
        radius: 20
        opacity: 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        
        Text {
            id: toastText
            color: "white"
            anchors.centerIn: parent
            font.pixelSize: 14
        }
        
        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: toastAnimOut.start()
        }
        
        NumberAnimation {
            id: toastAnimIn
            target: toast
            property: "opacity"
            to: 1
            duration: 300
            onStarted: toast.visible = true
            onStopped: toastTimer.start()
        }
        
        NumberAnimation {
            id: toastAnimOut
            target: toast
            property: "opacity"
            to: 0
            duration: 300
            onStopped: toast.visible = false
        }
        
        function show(msg) {
            toastText.text = msg;
            toastAnimIn.start();
        }
    }
    
    // Live Camera Popup Overlay
    Popup {
        id: cameraPopup
        width: parent.width * 0.9
        height: parent.height * 0.8
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        onOpened: {
            camera.start();
            autoScanTimer.start();
        }
        
        onClosed: {
            camera.stop();
            autoScanTimer.stop();
        }
        
        Rectangle {
            id: cameraContainer
            anchors.fill: parent
            color: "black"
            radius: 12
            property bool isAutoScan: false
            
            Timer {
                id: autoScanTimer
                interval: 1500
                running: false
                repeat: true
                onTriggered: {
                    if (camera.cameraStatus === Camera.ActiveStatus) {
                        cameraContainer.isAutoScan = true;
                        videoOutput.grabToImage(function(result) {
                            var path = "temp_auto.png";
                            result.saveToFile(path);
                            Ring.callFunc("backend_autoScanImage", [path]);
                            cameraContainer.isAutoScan = false;
                        });
                    }
                }
            }
            
            Camera {
                id: camera
                
                // Force Auto-Focus for close-up scanning (crucial for barcodes)
                focus {
                    focusMode: CameraFocus.ContinuousFocus
                    focusPointMode: CameraFocus.FocusPointCenter
                }
                
                // Ensure good exposure to capture white background and black stripes
                exposure {
                    exposureMode: CameraExposure.ExposureAuto
                }
            }
            
            VideoOutput {
                id: videoOutput
                source: camera
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                focus: visible
            }
            
            // Scanner Viewfinder Overlay
            Item {
                anchors.fill: parent
                
                // Darkened background outside the viewfinder
                Rectangle {
                    anchors.fill: parent
                    color: "#A0000000" // Semi-transparent black
                    
                    // Cutout the middle for the viewfinder
                    Rectangle {
                        id: viewfinder
                        width: 300
                        height: 150
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: "white"
                        border.width: 3
                        radius: 8
                    }
                }
                
                // Animated red scanner laser
                Rectangle {
                    id: scannerLine
                    width: viewfinder.width - 20
                    height: 2
                    color: "red"
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        running: cameraPopup.visible
                        NumberAnimation {
                            from: viewfinder.y + 10
                            to: viewfinder.y + viewfinder.height - 10
                            duration: 1500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            from: viewfinder.y + viewfinder.height - 10
                            to: viewfinder.y + 10
                            duration: 1500
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
            
            // Capture Button Overlay
            Button {
                text: "🟢 Capture & Scan"
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 20
                width: 200
                height: 60
                font.pixelSize: 18
                font.bold: true
                Material.background: "green"
                Material.foreground: "white"
                onClicked: {
                    cameraContainer.isAutoScan = false;
                    toast.show("Decoding manual capture...");
                    videoOutput.grabToImage(function(result) {
                        var path = "temp_manual.png";
                        result.saveToFile(path);
                        Ring.callFunc("backend_processCameraImage", [path]);
                    });
                }
            }
            
            // Close Button
            Button {
                text: "❌"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                width: 50
                height: 50
                Material.background: "red"
                Material.foreground: "white"
                onClicked: {
                    cameraPopup.close();
                }
            }
        }
    }
}
