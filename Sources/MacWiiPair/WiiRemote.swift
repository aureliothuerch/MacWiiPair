// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurelio Thuer

import Foundation

// Kept free of Bluetooth calls so it can be unit tested.
enum WiiRemote {
    enum PINSource: Equatable {
        // SYNC button: PIN is the host's address
        case host
        // 1 + 2 buttons: PIN is the remote's own address
        case remote
    }

    // Genuine remotes show up as "Nintendo RVL-CNT-01" (also -TR, and RVL-WBC-01 for the balance board)
    static func isWiiRemote(name: String?) -> Bool {
        name?.hasPrefix("Nintendo RVL") == true
    }

    // "aa-bb-cc-dd-ee-ff" or "aa:bb:..." as bytes in reverse order, which is the PIN byte order
    static func reversedAddress(_ address: String?) -> [UInt8]? {
        guard let address else { return nil }
        let parts = address.split(whereSeparator: { $0 == "-" || $0 == ":" })
        guard parts.count == 6 else { return nil }
        let bytes = parts.compactMap { $0.count == 2 ? UInt8($0, radix: 16) : nil }
        return bytes.count == 6 ? bytes.reversed() : nil
    }

    // Retries alternate between the two PINs, SYNC first
    static func pinSource(forAttempt attempt: Int) -> PINSource {
        attempt % 2 == 0 ? .host : .remote
    }

    // The pairing reply wants the PIN as one little-endian number
    static func pinKey(fromPIN bytes: [UInt8]) -> UInt64 {
        bytes.enumerated().reduce(UInt64(0)) { $0 | UInt64($1.element) << (8 * UInt64($1.offset)) }
    }
}
