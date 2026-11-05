# MacWiiPair

Small native macOS app that pairs Wii Remotes on recent macOS versions
(work in progress; developed against macOS 27).

## Build

Needs Xcode or the Command Line Tools.

    ./build.sh        # produces build/MacWiiPair.app
    swift test        # runs the unit tests

## Usage

Order matters:

1. **Start Dolphin first** and leave it running. This is required.
2. Open MacWiiPair.
3. Click **Pair Wii Remote**, then hold the **SYNC** button (under the battery
   cover) until pairing finishes.
4. The Wii Remote now shows up in Dolphin's controller settings.

Note: without Dolphin running, the Wii Remote shows up as connected in macOS
Bluetooth settings but its LEDs keep blinking. That is expected: it keeps
blinking until an application such as Dolphin takes over the connection.

## Status

**Maintained.** I update it when a new macOS version breaks pairing.
Issues and pull requests are welcome. Tested on macOS 27.0.1 (Mac16,5).

v0.1: UI and device discovery work. A genuine Wii Remote (RVL-CNT-01) connects
and stays paired once Dolphin takes over, tested on macOS 27.0.1. The status
text in the app does not report the final result. `tools/dump-classes.swift`
lists Objective-C classes of system frameworks through the public runtime API.

## Background

Since macOS 27, IOBluetooth answers the Wii Remote's PIN request itself and
never calls the app's delegate, so the classic approach times out. The root
cause comes from the pull request
[MaxfieldKassel/WiimotePair#1](https://github.com/MaxfieldKassel/WiimotePair/pull/1)
on a fork of [dolphin-emu/WiimotePair](https://github.com/dolphin-emu/WiimotePair).
MacWiiPair is an independent implementation and shares no code with either.

## License

GPL-3.0-or-later, see [LICENSE](LICENSE).
