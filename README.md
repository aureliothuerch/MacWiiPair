# MacWiiPair

Pairs Wii Remotes and other Wii Bluetooth devices, like the Balance Board, with your Mac on macOS 27 so you can use them in Dolphin.

[Download the latest release](https://github.com/aureliothuerch/MacWiiPair/releases/latest)

<p align="center"><img src="docs/screenshot.png" alt="The MacWiiPair window" width="480"></p>

## Why

The old pairing tools stopped working on macOS 27. The system never passes the Wii Remote's PIN request on to the app, so pairing just times out (people see `(os/kern) default set`). MacWiiPair answers that request itself.

## Install

You need an Apple silicon Mac on macOS 27, [Dolphin](https://dolphin-emu.org) and a Wii Remote or another supported device (see below).

Download the DMG from the [latest release](https://github.com/aureliothuerch/MacWiiPair/releases/latest), drag MacWiiPair onto the Applications shortcut and open it. The app is signed and notarized. macOS may ask once whether you want to open it, click Open.

To build it yourself you need Xcode or the Command Line Tools:

```sh
git clone https://github.com/aureliothuerch/MacWiiPair.git
cd MacWiiPair
./build.sh
open build/MacWiiPair.app
```

## Usage

Order matters here.

1. Start Dolphin and leave it running.
2. Open MacWiiPair and click Pair Wii Remote.
3. Hold SYNC (under the battery cover) until the window says Paired.
4. Quit MacWiiPair. The remote shows up in Dolphin's controller settings.

You can connect up to four Wii Remotes at the same time, the limit Dolphin sets. Repeat steps 2 and 3 for each remote.

From then on Dolphin connects the remotes on its own. You only need MacWiiPair again if you remove the remote in the Bluetooth settings.

## Troubleshooting

- The LEDs keep blinking and macOS lists the remote as connected: that is normal until a program like Dolphin takes over the connection. Start Dolphin.
- "No Wii Remote found": hold SYNC while the search runs. If the search ended first, click Pair again and press SYNC again.
- Nothing happens and there was no Bluetooth prompt: allow Bluetooth for MacWiiPair under System Settings > Privacy & Security.
- Pairing fails: open an issue and attach `~/Library/Logs/MacWiiPair.log`.

## How it works

The app looks for devices named `Nintendo RVL-*` with an IOBluetooth inquiry and starts the pairing. The PIN is the reversed Bluetooth address of your Mac (SYNC button) or of the remote (1 + 2 buttons), as described on [WiiBrew](https://wiibrew.org/wiki/Wiimote). The app tries both.

On macOS 27, IOBluetooth passes that binary PIN on as the key 0 and the remote rejects it. So a small hook (`PairingHook`) answers the system's PIN request first, with pairing type 6 and the PIN as a little-endian number.

The hook uses private CoreBluetooth and IOBluetooth interfaces that Apple does not document. A macOS update can break it. I maintain the app and will fix it when that happens.

## Supported devices

MacWiiPair pairs every Bluetooth device that advertises itself as `Nintendo RVL-*`.

Tested:
- Wii Remote (RVL-CNT-01) on macOS 27.0.1, Mac16,5

Untested, should work:
- Wii Remote Plus (RVL-CNT-01-TR)
- Wii Balance Board (RVL-WBC-01), pair it with its red SYNC button
- Several remotes in a row. Dolphin takes up to four.

Untested, may not work:
- Third-party remotes
- Wii U Pro Controller
- macOS versions other than 27.0.1

If you try one of these, open an issue with your result and the log file.

## Development

```sh
swift test                              # unit tests
./package.sh                            # build the release DMG
tools/make-icns.sh                      # rebuild the app icon
swift tools/dump-classes.swift Pairing  # list Objective-C classes by name
```

For a signed and notarized DMG set `SIGN_ID="Developer ID Application: ..."` and `NOTARY_PROFILE=<keychain profile>` before running `package.sh`.

## Contributing

Issues and pull requests are welcome. Contributions fall under GPL-3.0-or-later. MacWiiPair is an independent implementation, so please don't send code copied from [dolphin-emu/WiimotePair](https://github.com/dolphin-emu/WiimotePair) or its forks.

## Credits

[MaxfieldKassel/WiimotePair#1](https://github.com/MaxfieldKassel/WiimotePair/pull/1) found the macOS 27 root cause. MacWiiPair shares no code with it. [WiiBrew](https://wiibrew.org/wiki/Wiimote) documents the PIN scheme.

MacWiiPair is not affiliated with Nintendo or the Dolphin project.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
