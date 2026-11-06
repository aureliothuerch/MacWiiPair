// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurelio Thuer

import Foundation

/// Pure helpers for recognising and pairing Wii Remotes (no Bluetooth calls, so they are unit-testable).
enum WiiRemote {
    enum PINSource: Equatable {
        /// SYNC button: the PIN is the host's Bluetooth address.
        case host
        /// 1 + 2 buttons: the PIN is the Wii Remote's own address.
        case remote
    }

    /// Genuine remotes advertise as "Nintendo RVL-CNT-01" (also -TR and the balance board RVL-WBC-01).
    static func isWiiRemote(name: String?) -> Bool {
        name?.hasPrefix("Nintendo RVL") == true
    }

    /// Parses "aa-bb-cc-dd-ee-ff" (or with ":") into 6 bytes and reverses them. Nil if malformed.
    static func reversedAddress(_ address: String?) -> [UInt8]? {
        guard let address else { return nil }
        let parts = address.split(whereSeparator: { $0 == "-" || $0 == ":" })
        guard parts.count == 6 else { return nil }
        let bytes = parts.compactMap { $0.count == 2 ? UInt8($0, radix: 16) : nil }
        return bytes.count == 6 ? bytes.reversed() : nil
    }

    /// Alternates between the two possible PINs on each retry, starting with SYNC.
    static func pinSource(forAttempt attempt: Int) -> PINSource {
        attempt % 2 == 0 ? .host : .remote
    }

    /// Reads the PIN bytes as one little-endian number, the form the pairing reply expects.
    static func pinKey(fromPIN bytes: [UInt8]) -> UInt64 {
        bytes.enumerated().reduce(UInt64(0)) { $0 | UInt64($1.element) << (8 * UInt64($1.offset)) }
    }
}
