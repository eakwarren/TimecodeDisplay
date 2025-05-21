import MuseScore 3.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import Muse.Ui 1.0
import QtQuick.Layouts 1.3
import Muse.UiComponents 1.0

MuseScore {
    version: "1.0"
    pluginType: "dialog"
    requiresScore: true
    id: timecodeDisplay

    // Properties for 4.4
    title: "Timecode Display"
    description: "Displays synced timecode with offset and drop-frame support."
    thumbnailName: "TimecodeDisplayIcon.png"

    width: 225
    height: 75
    visible: true

    property var playbackModel: null
    property bool useDirectPlaybackAPI: false
    property real fps: 24
    property bool dropFrames: false
    property real currentTime: 0
    property bool durationEnabled: true


    // Initialize plugin
    Component.onCompleted: {
        console.log("Hello Timecode Display");

        try { // Try to use the direct playback API

            console.log("Testing playback model...");

            playbackModel = Qt.createQmlObject(
                        'import MuseScore.Playback 1.0
                 PlaybackToolBarModel {}',
                        timecodeDisplay,
                        "dynamicPlaybackModel"
                        );

            if (playbackModel) {
                playbackModel.load();
                useDirectPlaybackAPI = true;
                console.log("Loaded playback model");
            }

        } catch (error) {

            console.log("Error loading playback model: " + error);
        }

        updateTimer.start();

    }

    onRun: {

    }

    Timer {
        id: updateTimer
        interval: 16  // 60fps offset support
        repeat: true
        running: false
        onTriggered: {
            if (useDirectPlaybackAPI && playbackModel) {
                tcDisplay.text = formatTime(getPlayTimeSeconds());
            }
        }
    }

    /*===================
        UI Layout
    ===================*/

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Display your formatted timecode string here
        StyledTextLabel {
            id: tcDisplay
            text: {
                formatTime(getPlayTimeSeconds()) // re-evaluates if includeHours changes
            }
            font.pixelSize: 36
            color: ui.theme.accentColor
            topPadding: 10
        }

        FlatButton {
            id: settings
            toolTipTitle: "Settings"
            icon: IconCode.SETTINGS_COG
            width: 20
            height: 20
            transparent: true
            anchors.top: parent.top
            anchors.topMargin: -5
            anchors.right: parent.right
            opacity: .25
            onClicked: {
                // Show settings
                settingsOverlay.opacity = 1;
            }
        }


        // Settings Overlay
        Rectangle {
            id: settingsOverlay
            width: parent.width
            height: parent.height
            color: Qt.rgba(0, 0, 0, 0.5) // Semi-transparent background
            opacity: 0.0
            visible: opacity > 0
            anchors.fill: parent
            z: 100 // Ensure it's above all other elements

            // Add a MouseArea to block clicks to elements behind
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                // Consume all mouse events to prevent clicking through
                onClicked: { /* Do nothing, just consume the event */ }
                onPressed: { /* Do nothing, just consume the event */ }
                onReleased: { /* Do nothing, just consume the event */ }
            }

            // Settings panel with the original size
            Rectangle {
                width: 225
                height: 75
                anchors.centerIn: parent
                color: ui.theme.backgroundPrimaryColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 8

                    Item {
                        id: fpsInfo
                        anchors.left: parent.left
                        width: parent.width
                        height: 20

                        StyledTextLabel {
                            id: fpsDesc
                            color: ui.theme.fontPrimaryColor
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Fps "
                        }

                        TextField {
                            id: fpsField

                            text: fps

                            placeholderText: "24"
                            color: ui.theme.fontPrimaryColor
                            // Set the placeholder with dynamic opacity when empty
                            placeholderTextColor: Qt.rgba(
                                                      ui.theme.fontPrimaryColor.r,
                                                      ui.theme.fontPrimaryColor.g,
                                                      ui.theme.fontPrimaryColor.b,
                                                      text.length > 1 ? 1.0 : 0.5
                                                      )

                            width: 50
                            anchors.left: fpsDesc.right
                            horizontalAlignment: TextInput.AlignLeft
                            anchors.verticalCenter: parent.verticalCenter
                            validator: RegularExpressionValidator { regularExpression: /^((\d{1,2}).(\d{1,3}))$/ || /^((\d{1,2})$/ }

                            enabled: true
                        }

                        Label {
                                id: offsetText

                                anchors.right: offsetField.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Offset "
                            }

                        TextField {
                            id: offsetField

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 85
                            text: "00:00:00;00" // default value
                            placeholderText: "HH:MM:SS;FF"
                            horizontalAlignment: TextInput.AlignLeft

                            onTextEdited: {
                                tcDisplay.text = formatTime(getPlayTimeSeconds());
                            }
                        }

                    }

                    Item {
                        width: parent.width
                        height: 15

                        Label {
                            id: fpsExamples

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            font.italic: true
                            font.pointSize: 11
                            color: ui.theme.fontPrimaryColor
                            text: "24, 29.97, 60, etc."
                        }
                    }

                    // Status and Save row
                    Item {
                        width: parent.width
                        height: 25

                        FlatButton {
                            id: durationInfo
                            toolTipTitle: "Show duration"
                            icon: durationEnabled ? IconCode.EYE_OPEN : IconCode.EYE_CLOSED
                            width: 20
                            height: 20
                            transparent: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                durationEnabled = !durationEnabled;
                            }
                        }

                        StyledTextLabel {
                            id: durDesc
                            text: " Selection duration"
                            anchors.left: durationInfo.right
                            anchors.verticalCenter: parent.verticalCenter

                        }

                        FlatButton {
                            id: saveButton
                            text: "Save"
                            width: 50
                            height: 20
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                settingsOverlay.opacity = 0;
                            }
                        }
                    }
                }
            }
        }
    }


        // TimeInputField {
        //     id: timeField

        //     Layout.alignment: left

        //     //! NOTE: explicit width prevents the content from jumping around
        //     // when a score is being played
        //     // See: https://github.com/musescore/MuseScore/issues/9633
        //     width: 70

        //     // maxTime: playbackModel.maxPlayTime
        //     maxMillisecondsNumber: 999
        //     time: playbackModel.playTime


        //     onTimeEdited: function(newTime) {
        //         playbackModel.playTime = newTime
        //     }
        // }

    function formatTime(seconds) {
        var fpsVal = parseFloat(fpsField.text);
        if (isNaN(fpsVal) || fpsVal <= 0) fpsVal = fps;
        var dropFrames = fpsVal === 29.97 || fpsVal === 59.94 || fpsVal === 23.976 || fpsVal === 23.98;

        var offsetSeconds = timecodeOffsetToSeconds(offsetField.text, fpsVal, dropFrames);
        var totalMilliseconds = Math.round((seconds + offsetSeconds) * 1000);

        return formatTimecode(totalMilliseconds, fpsVal, dropFrames);
    }

    function formatTimecode(ms, fps, drop) {
        const isDrop = drop && (fps === 29.97 || fps === 59.94 || fps === 23.976 || fps === 23.98);
        const frInt = Math.floor(fps); // 30 or 60 or 24
        const dropFrames = (fps === 29.97) ? 2 :
                           (fps === 59.94) ? 4 :
                           (fps === 23.976 || fps === 23.98) ? 1 : 0;

        const totalSeconds = ms / 1000;
        let totalFrames = Math.floor(totalSeconds * frInt); // use integer fps (30, 60)
        // let totalFrames = Math.round(ms / 1000 * fps);  // use round (up) instead of floor (down)

        if (isDrop && dropFrames > 0) {
            const framesPer10Minutes = frInt * 60 * 10;
            const d = totalFrames;

            const tenMinuteChunks = Math.floor(d / framesPer10Minutes);
            const framesSinceLast10 = d % framesPer10Minutes;
            const minutesSinceLast10 = Math.floor(framesSinceLast10 / (frInt * 60));

            const dropCount = dropFrames * (tenMinuteChunks * 9 + Math.max(0, minutesSinceLast10 - Math.floor(minutesSinceLast10 / 10)));
            totalFrames += dropCount;
        }

        const hours = Math.floor(totalFrames / (frInt * 3600));
        const minutes = Math.floor((totalFrames % (frInt * 3600)) / (frInt * 60));
        const seconds = Math.floor((totalFrames % (frInt * 60)) / frInt);
        const frames = totalFrames % frInt;

        const separator = isDrop ? ";" : ":";

        function pad2(n) {
            return String(n).padStart(2, "0");
        }

        return pad2(hours) + ":" + pad2(minutes) + ":" + pad2(seconds) + separator + pad2(frames);
    }

    function getPlayTimeSeconds() {
        var t = playbackModel.playTime;
        if (!t) return 0;

        // fallback: calculate difference to midnight manually
        var midnight = new Date(t.getFullYear(), t.getMonth(), t.getDate(), 0, 0, 0);
        var diffMs = t.getTime() - midnight.getTime();
        return diffMs / 1000.0;
    }

    function timecodeOffsetToSeconds(offsetText, fps, dropFrame) {
        if (!offsetText || typeof offsetText !== "string") return 0;

        var parts = offsetText.trim().split(/[:;]/).map(Number);
        while (parts.length < 4) parts.unshift(0); // pad to [hh, mm, ss, ff]
        var [hh, mm, ss, ff] = parts;

        if (!dropFrame || fps !== 30) {
            // Simple timecode math
            return hh * 3600 + mm * 60 + ss + ff / fps;
        }

        // DROP-FRAME CALCULATION for 29.97 DF (30 fps timecode)
        // Formula from SMPTE: https://avid.secure.force.com/pkb/articles/en_US/How_To/Timecode-Calculations

        var totalMinutes = hh * 60 + mm;
        var dropFrames = 2;
        var framesPerHour = 107892;
        var framesPer24Hours = 2589408;
        var framesPer10Minutes = 17982;
        var framesPerMinute = 1798;

        // Total dropped frames = 2 × (totalMinutes - totalMinutes / 10)
        var droppedFrames = dropFrames * (totalMinutes - Math.floor(totalMinutes / 10));

        var totalFrames = ((hh * 3600 + mm * 60 + ss) * fps + ff) - droppedFrames;

        return totalFrames / fps;
    }


    function timeStringToSeconds(timeString) {
        // Example input: "01:23:45.678"
        let parts = timeString.split(":");
        if (parts.length !== 3)
            return 0;

        let hours = parseInt(parts[0]);
        let minutes = parseInt(parts[1]);

        let secParts = parts[2].split(".");
        let seconds = parseInt(secParts[0]);
        let milliseconds = secParts.length > 1 ? parseInt(secParts[1]) : 0;

        let totalSeconds = hours * 3600 + minutes * 60 + seconds + (milliseconds / 1000);
        return totalSeconds;
    }

}
