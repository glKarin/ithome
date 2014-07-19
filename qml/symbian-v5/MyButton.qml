import QtQuick 1.0
import com.nokia.symbian 1.0

ImplicitSizeItem {
    id: button

    // Common Public API
    property bool checked: false
    property bool checkable: false
    property bool pressed: (stateGroup.state == "Pressed" || stateGroup.state == "AutoRepeating") && mouseArea.containsMouse
    property alias text: label.text
    property alias iconSource: icon.source
    property alias font: label.font

    signal clicked

    // Symbian specific signals and properties
    signal platformReleased
    signal platformPressAndHold

    property bool platformAutoRepeat: false

    implicitWidth: Math.max(container.contentWidth + 2 * internal.horizontalPadding, privateStyle.buttonSize)
    implicitHeight: Math.max(container.contentHeight + 2 * internal.verticalPadding, privateStyle.buttonSize)

    QtObject {
        id: internal
        objectName: "internal"

        property int autoRepeatInterval: 60
        property int verticalPadding: (privateStyle.buttonSize - platformStyle.graphicSizeSmall) / 2
        property int horizontalPadding: label.text ? platformStyle.paddingLarge : verticalPadding

        // "pressed" is a transient state, see press() function
        function modeName() {
            if (belongsToButtonRow())
                return parent.privateModeName(button, 0)
            else if (!button.enabled)
                return "disabled"
            else if (button.checked)
                return "latched"
            else
                return "normal"
        }

        function toggleChecked() {
            if (checkable)
                checked = !checked
        }

        function press() {
            if (!belongsToButtonGroup()) {
                if (checkable && checked)
                    privateStyle.play(Symbian.SensitiveButton)
                else
                    privateStyle.play(Symbian.BasicButton)
            } else if (checkable && !checked) {
                privateStyle.play(Symbian.BasicButton)
            }

            highlight.source = privateStyle.imagePath(internal.imageName() + "pressed")
            container.scale = 0.95
            highlight.opacity = 1
        }

        function release() {
            container.scale = 1
            highlight.opacity = 0
            if (tapRepeatTimer.running)
                tapRepeatTimer.stop()
            button.platformReleased()
        }

        function click() {
            if ((checkable && checked && !belongsToButtonGroup()) || !checkable)
                privateStyle.play(Symbian.BasicButton)
            internal.toggleChecked()
            clickedEffect.restart()
            button.clicked()
        }

        function repeat() {
            if (!checkable)
                privateStyle.play(Symbian.SensitiveButton)
            button.clicked()
        }

        // The function imageName() handles fetching correct graphics for the Button.
        // If the parent of a Button is ButtonRow, segmented-style graphics are used to create a
        // seamless row of buttons. Otherwise normal Button graphics are utilized.
        function imageName() {
            if (belongsToButtonRow())
                return parent.privateGraphicsName(button, 0)
            return "qtg_fr_pushbutton_"
        }

        function belongsToButtonGroup() {
            return button.parent
                   && button.parent.hasOwnProperty("checkedButton")
                   && button.parent.exclusive
        }

        function belongsToButtonRow() {
            return button.parent
                    && button.parent.hasOwnProperty("checkedButton")
                    && button.parent.hasOwnProperty("privateDirection")
                    && button.parent.privateDirection == Qt.Horizontal
                    && button.parent.children.length > 1
        }
    }

    StateGroup {
        id: stateGroup

        states: [
            State { name: "Pressed" },
            State { name: "AutoRepeating" },
            State { name: "Canceled" }
        ]

        transitions: [
            Transition {
                to: "Pressed"
                ScriptAction { script: internal.press() }
            },
            Transition {
                from: "Pressed"
                to: "AutoRepeating"
                ScriptAction { script: tapRepeatTimer.start() }
            },
            Transition {
                from: "Pressed"
                to: ""
                ScriptAction { script: internal.release() }
                ScriptAction { script: internal.click() }
            },
            Transition {
                from: "Pressed"
                to: "Canceled"
                ScriptAction { script: internal.release() }
            },
            Transition {
                from: "AutoRepeating"
                ScriptAction { script: internal.release() }
            }
        ]
    }

    BorderImage {
        source: main.night_mode? privateStyle.imagePath(internal.imageName() + internal.modeName()) :"qrc:/Image/button_white_symbian.png"
        border { left: 20; top: 20; right: 20; bottom: 20 }
        anchors.fill: parent

        BorderImage {
            id: highlight
            border { left: 20; top: 20; right: 20; bottom: 20 }
            opacity: 0
            anchors.fill: parent
        }
    }

    Item {
        id: container

        // Having both icon and text simultaneously is unspecified but supported by implementation
        property int spacing: (icon.height && label.text) ? platformStyle.paddingSmall : 0
        property int contentWidth: Math.max(icon.width, label.textWidth)
        property int contentHeight: icon.height + spacing + label.height

        width: Math.min(contentWidth, button.width - 2 * internal.horizontalPadding)
        height: Math.min(contentHeight, button.height - 2 * internal.verticalPadding)
        clip: true
        anchors.centerIn: parent

        Image {
            id: icon
            sourceSize.width: platformStyle.graphicSizeSmall
            sourceSize.height: platformStyle.graphicSizeSmall
            smooth: true
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            id: label
       
            elide: Text.ElideRight
            property int textWidth: text ? privateStyle.textWidth(text, font) : 0
            anchors {
                top: icon.bottom
                topMargin: parent.spacing
                left: parent.left
                right: parent.right
            }
            height: text ? privateStyle.fontHeight(font) : 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font { family: platformStyle.fontFamilyRegular; pixelSize: platformStyle.fontSizeLarge }
            color: {
                if (!button.enabled)
                    return platformStyle.colorDisabledLight
                else if (button.pressed)
                    return platformStyle.colorPressed
                else if (button.checked)
                    return platformStyle.colorChecked
                else
                    return main.night_mode?platformStyle.colorNormalLight:"black"
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        onPressed: stateGroup.state = "Pressed"

        onReleased: stateGroup.state = ""

        onCanceled: {
            // Mark as canceled
            stateGroup.state = "Canceled"
            // Reset state. Can't expect a release since mouse was ungrabbed
            stateGroup.state = ""
        }

        onPressAndHold: {
            if (stateGroup.state != "Canceled" && platformAutoRepeat)
                stateGroup.state = "AutoRepeating"
            button.platformPressAndHold()
        }

        onExited: stateGroup.state = "Canceled"
    }

    Timer {
        id: tapRepeatTimer

        interval: internal.autoRepeatInterval; running: false; repeat: true
        onTriggered: internal.repeat()
    }

    ParallelAnimation {
        id: clickedEffect
        PropertyAnimation {
            target: container
            property: "scale"
            from: 0.95
            to: 1.0
            easing.type: Easing.Linear
            duration: 100
        }
        PropertyAnimation {
            target: highlight
            property: "opacity"
            from: 1
            to: 0
            easing.type: Easing.Linear
            duration: 150
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Select || event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
            stateGroup.state = "Pressed"
            event.accepted = true
        }
    }

    Keys.onReleased: {
        if (event.key == Qt.Key_Select || event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
            stateGroup.state = ""
            event.accepted = true
        }
    }
}
