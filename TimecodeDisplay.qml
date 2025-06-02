import MuseScore 3.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import Muse.UiComponents 1.0
import Muse.Ui 1.0

MuseScore {
    version: "1.0"
    pluginType: "dialog"
    requiresScore: true
    id: timecodeDisplay

    // Properties for 4.4
    title: "Timecode Display"
    description: "Displays synced timecode with offset and drop-frame support. Optionally shows the duration of a selection in the score."
    thumbnailName: "TimecodeDisplayIcon.png"

    width: 225
    height: 75
    visible: true

    property var playbackModel: null
    property bool useDirectPlaybackAPI: false
    property real fps: 24
    property bool dropFrames: false
    property real currentTime: 0
    property bool durationEnabled: false
    property int startTick: 0
    property int endTick: 0
    property int tickDuration: 0


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

    onRun: {  }

    Timer {
        id: updateTimer
        interval: 16  // 60fps offset support
        repeat: true
        running: false
        onTriggered: {

            if (useDirectPlaybackAPI && playbackModel) {
                tcDisplay.text = formatTime(getPlayTimeSeconds());
            }

            if (durationEnabled) {
                var seconds = durationTicksToSeconds();
                if (isNaN(seconds)) {
                    selectionDurationDisplay.text = "No range selection.";
                } else {
                    var offsetSeconds = timecodeOffsetToSeconds(offsetField.text, fpsField.text, dropFrames);
                    selectionDurationDisplay.text = formatTime(seconds - offsetSeconds);
                }
            } else {
                selectionDurationDisplay.text = "";
            }
        }
    }

    /*===================
        UI Layout
    ===================*/

    Item {
        id: mainItem
        anchors.fill: parent
        anchors.margins: 10
        anchors.topMargin: 0

        Column {
            id: mainColumn
            spacing: 10
            width: parent.width
            height: parent.height

            RowLayout {
                height: 30
                Layout.fillWidth: true

                StyledTextLabel {
                    id: tcDisplay
                    text: { formatTime(getPlayTimeSeconds()) } // re-evaluates if includeHours changes
                    font.pixelSize: { if (fpsField.text === "999") { 33 } else { 36 } }
                    color: ui.theme.accentColor
                }

            }

            RowLayout {
                height: 25
                width: parent.width
                Layout.topMargin: 40

                FlatButton {
                    id: durationInfo
                    toolTipTitle: "Selection duration"
                    icon: IconCode.LOOP
                    width: 20
                    height: 20
                    transparent: true
                    Layout.alignment: Qt.AlignLeft
                    opacity: durationEnabled ? 1 : .25
                    onClicked: { durationEnabled = !durationEnabled; }
                }

                StyledTextLabel {
                    id: selectionDurationDisplay
                    Layout.alignment: Qt.AlignHCenter
                    opacity: durationEnabled ? 1 : 0
                    text: "00:00:00:00"
                    font.pixelSize: 16
                    color: selectionDurationDisplay.text.length > 0
                           ? ui.theme.fontPrimaryColor
                           : Qt.rgba(ui.theme.fontPrimaryColor.r,
                                     ui.theme.fontPrimaryColor.g,
                                     ui.theme.fontPrimaryColor.b,
                                     0.4) // gray out when empty
                    wrapMode: Text.Wrap
                    width: parent.width - settings.width - 10
                }

                FlatButton {
                    id: settings
                    toolTipTitle: "Settings"
                    icon: IconCode.SETTINGS_COG
                    width: 20
                    height: 20
                    transparent: true
                    Layout.alignment: Qt.AlignRight
                    opacity: .25
                    onClicked: { settingsOverlay.opacity = 1; } // Show settings
                }

            }

        }

        // Settings Overlay
        Rectangle {
            id: settingsOverlay
            width: parent.width
            height: parent.height
            color: ui.theme.backgroundPrimaryColor
            opacity: 0.0
            visible: opacity > 0
            anchors.fill: parent
            z: 100 // above all other elements

            // block clicks to elements behind
            MouseArea {
                Layout.fillWidth: true
                hoverEnabled: true
                onClicked: { } // do nothing, just consume the events
                onPressed: { }
                onReleased: { }
            }

            // Settings panel with the original size
            Item {
                width: parent.width
                height: parent.height

                Column {
                    width: parent.width
                    height: parent.height
                    spacing: 10

                    RowLayout {
                        height: 30
                        Layout.topMargin: 10

                        StyledTextLabel {
                            id: fpsDesc
                            color: ui.theme.fontPrimaryColor
                            Layout.alignment: Qt.AlignLeft
                            text: "Fps"
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

                            Layout.preferredWidth: 50
                            Layout.minimumWidth: 50
                            Layout.maximumWidth: 50
                            Layout.alignment: Qt.AlignLeft
                            horizontalAlignment: TextInput.AlignLeft
                            validator: RegularExpressionValidator { regularExpression: /^((\d{1,2}).(\d{1,3}))$/ || /^((\d{1,2})$/ }
                            enabled: true
                        }

                        Label {
                            id: offsetText
                            Layout.alignment: Qt.AlignRight
                            text: "Offset"
                        }

                        TextField {
                            id: offsetField

                            Layout.alignment: Qt.AlignRight
                            Layout.preferredWidth: 85
                            Layout.minimumWidth: 85
                            Layout.maximumWidth: 85
                            text: "00:00:00:00" // default value
                            placeholderText: "HH:MM:SS:FF"
                            horizontalAlignment: TextInput.AlignLeft
                            onTextEdited: {
                                tcDisplay.text = formatTime(getPlayTimeSeconds());
                            }
                        }

                    }

                    RowLayout {
                        height: 25
                        width: parent.width
                        Layout.topMargin: 40

                        FlatButton {
                            id: framerateInfo
                            icon: IconCode.QUESTION_MARK
                            toolTipTitle: "Example frame rates"
                            transparent: true
                            width: 20
                            height: 20
                            Layout.alignment: Qt.AlignLeft
                            onClicked: { popupView.toggleOpened() }

                            StyledPopupView {
                                id: popupView
                                contentWidth: layout.childrenRect.width
                                contentHeight: layout.childrenRect.height

                                Column {
                                    id: layout
                                    spacing: 10

                                    Repeater {
                                        model: [
                                            "Film: 24", "NTSC: 29.97*", "NTSC HD: 59.94*",
                                            "PAL: 25", "PAL HD: 50", "Web: 30", "HD: 60",
                                            "Other: 23.978*", "Other: 23.98*", "Ms: 999",
                                            "Any number: 15, 12.34", "* drop frame"
                                        ]
                                        delegate: Text {
                                            text: modelData
                                            color: ui.theme.fontPrimaryColor
                                        }
                                    }
                                }
                            }
                        }

                        FlatButton {
                            id: saveButton
                            icon: IconCode.SAVE
                            toolTipTitle: "Save"
                            transparent: true
                            width: 20
                            height: 20
                            Layout.alignment: Qt.AlignRight
                            onClicked: { settingsOverlay.opacity = 0; }
                        }
                    }
                }
            }
        }
    }

    /*===================
        Functions
    ===================*/

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

    function durationTicksToSeconds() { // ran from onRun

        var sel = getSelection();
          if (sel === null) { //no selection
              selectionDurationDisplay.text = "No selection"
              // console.log('No selection');
                return;
          }
          // var beatBaseItem = beatBase.model.get(beatBase.currentIndex);
          // Start Tempo
          var foundTempo = undefined;
          var segment = sel.startSeg;
          while ((foundTempo === undefined) && (segment)) {
                foundTempo = findExistingTempoElement(segment);
                segment = segment.prev;
          }
          if (foundTempo !== undefined) {
                // console.log('Found start tempo text = ' + foundTempo.text);
                // Try to extract base beat
                // var targetBeatBaseIndex = findBeatBaseFromMarking(foundTempo);
                // if (targetBeatBaseIndex !== -1) {
                //       // Apply it
                //       previousBeatIndex = targetBeatBaseIndex;
                //       beatBase.currentIndex = targetBeatBaseIndex;
                //       beatBaseItem = beatBase.model.get(targetBeatBaseIndex);
                // }
                // Update input field according to the (detected) beat
                // startBPMvalue.placeholderText = Math.round(foundTempo.tempo * 60 / beatBaseItem.mult * 10) / 10;
          }
          // End Tempo
          foundTempo = undefined;
          segment = sel.endSeg;
          while ((foundTempo === undefined) && (segment)) {
                foundTempo = findExistingTempoElement(segment);
                segment = segment.prev
          }
          if (foundTempo !== undefined) {
                // console.log('Found end tempo text = ' + foundTempo.text);
                // endBPMvalue.placeholderText = Math.round(foundTempo.tempo * 60 / beatBaseItem.mult * 10) / 10;
          }

          var cursor = curScore.newCursor();
          // console.log("startTick: " + startTick);
          // console.log("endTick: " + endTick);

          cursor.rewindToTick(startTick); //start of selection

          let tempo = cursor.tempo; //expressed as multiplier of 60, 120BPM = 2, 130BPM = 2.1666666666666665
          // console.log("tempo: " + tempo);

          let tpqn = 480; // typically 480
          // console.log("tpqn: " + tpqn);
          // tempo = curScore.tempo(startTick); // in BPM

          let secondsPerTick = (60/(60 * tempo)) / tpqn; // this assumes tempo is BPM (120), not 2. secondsPerTick = 0.00104166667
          // console.log("secondsPerTick: " + secondsPerTick);

          let durationSeconds = tickDuration * secondsPerTick; // 3840 * 0.00104166667 = 4

          // console.log("tickDuration: " + tickDuration);
          // console.log("durationSeconds: " + durationSeconds);

          let durationMilliseconds = durationSeconds * 1000;

          // console.log("Duration: ", durationSeconds, "seconds");
          // console.log("Duration: ", durationMilliseconds, "milliseconds");

          return durationSeconds
    }

    function getSelection() {
          var selection = null;
          var cursor = curScore.newCursor();
          cursor.rewind(1); //start of selection
          if (!cursor.segment) { //no selection
              selectionDurationDisplay.text = "No selection"
              // console.log('No selection');
                return selection;
          }
          selection = {
                start: cursor.tick,
                startSeg: cursor.segment,
                end: null,
                endSeg: null
          };

          // console.log("selection.start: " + selection.start);
          // console.log("selection.startSeg: " + selection.startSeg);

          cursor.rewind(2); //find end of selection
          if (cursor.tick === 0) {
                // this happens when the selection includes
                // the last measure of the score.
                // rewind(2) goes behind the last segment (where
                // there's none) and sets tick=0
                selection.end = curScore.lastSegment.tick + 1;
                selection.endSeg = curScore.lastSegment;

                // console.log("if selection.end: " + selection.end);
                // console.log("if selection.endSeg: " + selection.endSeg);
          }
          else {
                selection.end = cursor.tick;
                selection.endSeg = cursor.segment;

              // console.log("else selection.end: " + selection.end);  // showing up in logs
              // console.log("else selection.endSeg: " + selection.endSeg);
          }
          startTick = selection.start;
          endTick = selection.end;
          tickDuration = selection.end - selection.start;

          // console.log("tickDuration: " + tickDuration);
          // console.log("selection: " + selection);
          return selection;
    }

    function findExistingTempoElement(segment) { //look in reverse order, there might be multiple TEMPO_TEXTs attached
          // in that case MuseScore uses the last one in the list
          for (var i = segment.annotations.length; i-- > 0; ) {
                if (segment.annotations[i].type === Element.TEMPO_TEXT) {
                      return (segment.annotations[i]);
                }
          }
          return undefined; //invalid - no tempo text found
    }

    function applyTempoChanges()
    {
          var sel = getSelection();
          if (sel === null) { //no selection
              selectionDurationDisplay.text = "No selection"
              // console.log('No selection');
                return;
          }
          var durationTicks = sel.end - sel.start;
          // console.log("durationTicks: " + durationTicks);

          var beatBaseItem = beatBase.model.get(beatBase.currentIndex);
          var startTempo = getTempoFromInput(startBPMvalue) * beatBaseItem.mult;
          var endTempo = getTempoFromInput(endBPMvalue) * beatBaseItem.mult;
          var tempoRange = (endTempo - startTempo);
          // console.log('Applying to selection [' + sel.start + ', ' + sel.end + '] = ' + durationTicks);
          // console.log(startTempo + ' (' + (startTempo*60) + ') -> ' + endTempo + ' (' + (endTempo*60) + ') = ' + tempoRange);

          var cursor = curScore.newCursor();
          cursor.rewind(1); //start of selection
          var tempoTracker = {}; //tracker to ensure only one marking is created per 0.1 tempo changes
          var endSegment = { track: undefined, tick: undefined };

          curScore.startCmd();
          //add indicative text if required
          if (startTextValue.text !== "") {
                var startText = newElement(Element.STAFF_TEXT);
                startText.text = startTextValue.text;
                if (startText.textStyleType !== undefined) {
                      startText.textStyleType = TextStyleType.TECHNIQUE;
                }
                cursor.add(startText);
          }

          var midPoint = ((curveType.isLinear) ? 50.0 : midpointSlider.value) / 100; //linear == hit midpoint at 50% tickRange
          var p = Math.log(0.5) / Math.log(midPoint);
          // To find the matching tempo for each tick, we perform (%tickrange)^(p)
          for (var trackIdx = 0; trackIdx < cursor.score.ntracks; ++trackIdx) {
                cursor.rewind(1);
                cursor.track = trackIdx;

                while (cursor.segment && (cursor.tick < sel.end)) {
                      //interpolation of the desired tempo
                      var curveXpct = (cursor.tick - sel.start) / durationTicks;
                      var outputPct = Math.pow(curveXpct, p);
                      var newTempo = (outputPct * tempoRange) + startTempo;
                      applyTempoToSegment(newTempo, cursor, false, beatBaseItem, tempoTracker);
                      cursor.next();
                }

                if (cursor.segment) { //first element after selection
                      if ((endSegment.tick === undefined) || (cursor.tick < endSegment.tick)) { //is closer to the selection end than in previous tracks
                            endSegment.track = cursor.track;
                            endSegment.tick = cursor.tick;
                      }
                }
          }
          //processed selection, now end at new tempo with a visible element
          if ((endSegment.track !== undefined) && (endSegment.tick !== undefined)) { //but only if we found one
                //relocate it
                cursor.rewind(1);
                cursor.track = endSegment.track;
                while (cursor.tick < endSegment.tick) { cursor.next(); }
                //arrived at end segment, write marking
                applyTempoToSegment(endTempo, cursor, true, beatBaseItem);
          }

          curScore.endCmd(false);
    }

}
