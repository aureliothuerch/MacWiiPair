// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurelio Thuer

import Foundation
import ObjectiveC

/// Answers CoreBluetooth's PIN request itself (private API).
///
/// On macOS 27 the system hands the pairing request to CBPairingAgent, and
/// IOBluetooth turns the binary Wii Remote PIN into the key 0, which the remote
/// rejects. The hook replies with pairing type 6 and the PIN as a number instead.
enum PairingHook {
    typealias PIN = (key: UInt64, label: String, peer: AnyObject?)

    /// Returns the PIN for the current attempt, or nil to leave the request to the system.
    static var pinProvider: (() -> PIN?)?

    private static let pinRequestType = 6

    static func install(log: @escaping (String) -> Void) {
        guard let cls = NSClassFromString("CBPairingAgent") else { return log("CBPairingAgent not found") }
        let sel = NSSelectorFromString("handlePairingRequested:")
        guard let method = class_getInstanceMethod(cls, sel) else { return log("handlePairingRequested: not found") }

        typealias Original = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
        let original = unsafeBitCast(method_getImplementation(method), to: Original.self)

        let replacement: @convention(block) (AnyObject, AnyObject?) -> Void = { agent, request in
            log("handlePairingRequested: \(describe(request))")
            if onMain({ handle(request, log: log) }) { return }
            original(agent, sel, request)
        }
        method_setImplementation(method, imp_implementationWithBlock(replacement))
        log("Hook installed")
    }

    /// Returns true when the request is a PIN request we answer ourselves.
    private static func handle(_ request: AnyObject?, log: @escaping (String) -> Void) -> Bool {
        guard let info = request as? [String: Any] else { log("Request is not a dictionary"); return false }
        guard (info["kCBMsgArgPairingType"] as? NSNumber)?.intValue == pinRequestType else { return false }
        guard let pin = pinProvider?() else { log("No PIN for this request, leaving it to the system"); return false }
        guard let coordinator = coordinator() else { log("Coordinator not found"); return false }

        var peer = pin.peer
        if peer == nil, let uuidString = info["kCBMsgArgDeviceUUID"] as? String, let uuid = NSUUID(uuidString: uuidString) {
            peer = coordinator.perform(NSSelectorFromString("peerForIdentifier:"), with: uuid)?.takeUnretainedValue()
        }
        guard let peer else { log("Peer not found"); return false }

        log("Replying with \(pin.label)")
        // bluetoothd expects the reply shortly after the request, not in the same instant.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            send(pin.key, to: peer, via: coordinator, log: log)
        }
        return true
    }

    private static func coordinator() -> AnyObject? {
        guard let cls = NSClassFromString("IOBluetoothCoreBluetoothCoordinator") else { return nil }
        return (cls as AnyObject).perform(NSSelectorFromString("sharedInstance"))?.takeUnretainedValue()
    }

    private static func send(_ key: UInt64, to peer: AnyObject, via coordinator: AnyObject, log: @escaping (String) -> Void) {
        let sel = NSSelectorFromString("pairPeer:forType:withKey:")
        guard let cls = object_getClass(coordinator), let method = class_getInstanceMethod(cls, sel) else {
            return log("pairPeer:forType:withKey: not found")
        }
        typealias Reply = @convention(c) (AnyObject, Selector, AnyObject, Int, AnyObject) -> Void
        let reply = unsafeBitCast(method_getImplementation(method), to: Reply.self)
        reply(coordinator, sel, peer, pinRequestType, NSNumber(value: key))
        log("PIN sent")
    }

    private static func onMain<T>(_ work: () -> T) -> T {
        Thread.isMainThread ? work() : DispatchQueue.main.sync(execute: work)
    }

    private static func describe(_ object: AnyObject?) -> String {
        guard let object else { return "nil" }
        return "\(type(of: object)) \(object)"
    }
}
