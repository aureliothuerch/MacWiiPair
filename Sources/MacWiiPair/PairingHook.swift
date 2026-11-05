// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurelio Thuer

import Foundation
import ObjectiveC

/// Observes CoreBluetooth's pairing agent (private API). Currently diagnostic
/// only: it logs what the system hands us so the reply can be built from facts.
enum PairingHook {
    static func install(log: @escaping (String) -> Void) {
        guard let cls = NSClassFromString("CBPairingAgent") else { return log("CBPairingAgent not found") }
        let sel = NSSelectorFromString("handlePairingRequested:")
        guard let method = class_getInstanceMethod(cls, sel) else { return log("handlePairingRequested: not found") }

        typealias Original = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
        let original = unsafeBitCast(method_getImplementation(method), to: Original.self)

        let replacement: @convention(block) (AnyObject, AnyObject?) -> Void = { agent, request in
            log("handlePairingRequested: \(describe(request))")
            original(agent, sel, request)
        }
        method_setImplementation(method, imp_implementationWithBlock(replacement))
        log("Hook installed")
    }

    private static func describe(_ object: AnyObject?) -> String {
        guard let object else { return "nil" }
        var out = "\(type(of: object)) \(object)"
        var count: UInt32 = 0
        if let props = class_copyPropertyList(type(of: object), &count) {
            defer { free(props) }
            let names = (0..<Int(count)).map { String(cString: property_getName(props[$0])) }
            out += " props=\(names)"
        }
        return out
    }
}
