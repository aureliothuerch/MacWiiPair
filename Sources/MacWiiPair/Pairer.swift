// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurelio Thuer

import Foundation
import IOBluetooth

/// Finds a Wii Remote via Bluetooth inquiry and pairs it.
/// The PIN is the reversed Bluetooth address of the host (SYNC button) or of
/// the remote (1 + 2 buttons), as documented on WiiBrew.
final class Pairer: NSObject, ObservableObject {
    @Published private(set) var status = "Ready"
    @Published private(set) var isBusy = false
    @Published private(set) var logLines: [String] = []

    private var inquiry: IOBluetoothDeviceInquiry?
    private var pair: IOBluetoothDevicePair?
    private var target: IOBluetoothDevice?
    private var attempt = 0
    private let maxAttempts = 4

    override init() {
        super.init()
        PairingHook.install { [weak self] in self?.log($0) }
        PairingHook.pinProvider = { [weak self] in self?.pinCandidate() }
    }

    func log(_ line: String) {
        NSLog("MacWiiPair: %@", line)
        FileLog.write(line)
        DispatchQueue.main.async { self.logLines.append(line) }
    }

    func start() {
        guard !isBusy else { return }
        isBusy = true
        attempt = 0
        status = "Searching…"
        inquiry = IOBluetoothDeviceInquiry(delegate: self)
        inquiry?.updateNewDeviceNames = true
        inquiry?.inquiryLength = 30
        let r = inquiry?.start() ?? kIOReturnError
        if r != kIOReturnSuccess { finish("Could not start search (0x\(String(UInt32(bitPattern: r), radix: 16)))") }
    }

    func stop() {
        inquiry?.stop()
        pair?.stop()
        pair = nil
        finish("Ready")
    }

    private func finish(_ message: String) {
        DispatchQueue.main.async {
            self.status = message
            self.isBusy = false
        }
    }

    private func beginPairing(_ device: IOBluetoothDevice) {
        guard let p = IOBluetoothDevicePair(device: device) else { return finish("Pairing unavailable") }
        p.delegate = self
        pair = p
        target = device
        DispatchQueue.main.async { self.status = "Pairing (attempt \(self.attempt + 1)/\(self.maxAttempts))…" }
        log("Pairing \(device.addressString ?? "?") (attempt \(attempt + 1))")
        let r = p.start()
        if r != kIOReturnSuccess { retryOrFail("start failed 0x\(String(UInt32(bitPattern: r), radix: 16))") }
    }

    /// PIN for the current attempt, used by PairingHook to answer the system's PIN request.
    private func pinCandidate() -> PairingHook.PIN? {
        guard isBusy, pair != nil else { return nil }
        let source = WiiRemote.pinSource(forAttempt: attempt)
        let address = source == .host
            ? IOBluetoothHostController.default()?.addressAsString()
            : target?.addressString
        guard let bytes = WiiRemote.reversedAddress(address) else { return nil }
        let key = WiiRemote.pinKey(fromPIN: bytes)
        let label = source == .host ? "host address" : "remote address"
        let peerSelector = NSSelectorFromString("peer")
        let peer = target.flatMap { $0.responds(to: peerSelector) ? $0.perform(peerSelector)?.takeUnretainedValue() : nil }
        return (key, label, peer)
    }

    private func retryOrFail(_ reason: String) {
        log("Failed: \(reason)")
        pair = nil
        attempt += 1
        if attempt < maxAttempts, let device = target {
            beginPairing(device)
        } else {
            finish("Pairing failed – see log")
        }
    }
}

extension Pairer: IOBluetoothDeviceInquiryDelegate {
    func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        consider(device)
    }

    func deviceInquiryDeviceNameUpdated(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!, devicesRemaining: UInt32) {
        consider(device)
    }

    func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        if pair == nil, isBusy, !aborted { finish("No Wii Remote found") }
    }

    private func consider(_ device: IOBluetoothDevice) {
        guard pair == nil, WiiRemote.isWiiRemote(name: device.name) else { return }
        log("Found \(device.name ?? "?") \(device.addressString ?? "?")")
        inquiry?.stop()
        beginPairing(device)
    }
}

extension Pairer: IOBluetoothDevicePairDelegate {
    // Only called on macOS versions where IOBluetooth still forwards the PIN request.
    func devicePairingPINCodeRequest(_ sender: Any!) {
        guard let p = sender as? IOBluetoothDevicePair else { return }
        let host = IOBluetoothHostController.default()?.addressAsString()
        let useHost = WiiRemote.pinSource(forAttempt: attempt) == .host
        let source = useHost ? host : p.device()?.addressString
        guard let bytes = WiiRemote.reversedAddress(source) else { return log("No address for PIN") }
        var pin = BluetoothPINCode()
        withUnsafeMutableBytes(of: &pin.data) { raw in
            for (i, b) in bytes.enumerated() { raw[i] = b }
        }
        log("PIN requested – replying (\(useHost ? "host" : "remote") address)")
        p.replyPINCode(6, pinCode: &pin)
    }

    func devicePairingFinished(_ sender: Any!, error: IOReturn) {
        if error == kIOReturnSuccess {
            log("Paired.")
            pair = nil
            finish("Paired ✓\nYou can quit MacWiiPair now.")
        } else {
            retryOrFail("0x\(String(UInt32(bitPattern: error), radix: 16))")
        }
    }
}
