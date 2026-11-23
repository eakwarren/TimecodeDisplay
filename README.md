# TimecodeDisplay
Shows MuseScore playback time as timecode. Supports multiple timecode formats and features an optional selection duration view.

<img width="200" alt="TimecodeDisplayScreenshot" src="https://github.com/user-attachments/assets/becf1c0d-4781-41fb-a7d8-39f8385e3e1a" />


Developed with ❤️ by Eric Warren


## Setup
1. Unzip the latest release to your ~/Documents/Musescore4/Plugins directory.

2. Enable the plugin in MuseScore Studio under Plugins > Manage plugins. Click the plugin and click Enable. Perhaps set a shortcut in Preferences > Shortcuts. (I use Cmd+'.) Load a score and open the plugin with the shortcut or under Plugins.

3. In the Timecode Display window, click the Settings (cog) button. Enter a frame rate. For milliseconds, enter `1000`. The final field then shows three digits, for example `00:00:01:025`. (The ? icon lists example frame rates.) Set an offset if needed. Click the Save button.

In the main window, clicking the Loop button will activate selection duration. To show a duration, select a range in the score.

## Known Issues
View known issues on [GitHub](https://github.com/eakwarren/TimecodeDisplay/issues)


## To Do
If you have a suggestion or find a bug please report it on [GitHub](https://github.com/eakwarren/TimecodeDisplay/issues). I don’t promise a fix or tech support, but I’m happy to take a look. 🙂


## Special Thanks
_“If I have seen further, it is by standing on the shoulders of Giants.” ~Isaac Newton_

MuseScore Studio developers, wherever they may roam.

Phil Xan, developer of the [ScoreTimecode](https://github.com/philxan/ScoreTimecode) plugin. 

## Release Notes
v1.0 6/11/25 Initial release.

## Development checks

Run `node --test tests/timecode.test.cjs` with Node.js 18 or newer. The tests exercise the formatting functions directly from the QML source; no MuseScore or npm packages are required. They cover millisecond boundaries, offsets, literal 999 fps, and conventional frame rates.

For a visual check in MuseScore Studio, open the plugin and try 24, 120, and 1000 in Settings. Verify that the entire timecode and both lower-row buttons fit, and that millisecond mode always has three digits. The display still refreshes on its existing 16 ms timer; three displayed digits do not imply 1 ms refresh accuracy.
