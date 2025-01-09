import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: background
    anchors.centerIn: parent
    color: "#151818"
    // color: Kirigami.Theme.alternateBackgroundColor

    Rectangle {
        anchors.fill: parent
        color: "#44000000"
    }

    Rectangle {
        id: groove
        width: 480
        height: 12
        radius: 5
        anchors.centerIn: parent
        color: Kirigami.Theme.backgroundColor
        Rectangle {
            id: block
            height: 10
            width: 48
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: Kirigami.Theme.highlightColor

            SequentialAnimation on x {
                id: anim
                loops: Animation.Infinite

                NumberAnimation  {
                    from: 0
                    to: groove.width - block.width
                    duration: 1200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation  {
                    from: groove.width - block.width
                    to: 0
                    duration: 1200
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
}
