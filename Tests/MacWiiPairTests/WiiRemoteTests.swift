// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurelio Thuer

import Testing
@testable import MacWiiPair

@Suite struct WiiRemoteTests {
    @Test func recognisesNintendoNames() {
        #expect(WiiRemote.isWiiRemote(name: "Nintendo RVL-CNT-01"))
        #expect(WiiRemote.isWiiRemote(name: "Nintendo RVL-CNT-01-TR"))
        #expect(WiiRemote.isWiiRemote(name: "Nintendo RVL-WBC-01"))
    }

    @Test func rejectsOtherDevices() {
        #expect(!WiiRemote.isWiiRemote(name: "AirPods Pro"))
        #expect(!WiiRemote.isWiiRemote(name: "Nintendo Switch Pro Controller"))
        #expect(!WiiRemote.isWiiRemote(name: ""))
        #expect(!WiiRemote.isWiiRemote(name: nil))
    }

    @Test func reversesDashSeparatedAddress() {
        #expect(WiiRemote.reversedAddress("e8-4e-ce-52-ce-70") == [0x70, 0xce, 0x52, 0xce, 0x4e, 0xe8])
    }

    @Test func reversesColonSeparatedAndUppercaseAddress() {
        #expect(WiiRemote.reversedAddress("00:11:22:AA:BB:CC") == [0xCC, 0xBB, 0xAA, 0x22, 0x11, 0x00])
    }

    @Test func rejectsMalformedAddresses() {
        #expect(WiiRemote.reversedAddress(nil) == nil)
        #expect(WiiRemote.reversedAddress("") == nil)
        #expect(WiiRemote.reversedAddress("e8-4e-ce-52-ce") == nil)        // too short
        #expect(WiiRemote.reversedAddress("e8-4e-ce-52-ce-70-01") == nil)   // too long
        #expect(WiiRemote.reversedAddress("zz-4e-ce-52-ce-70") == nil)      // not hex
        #expect(WiiRemote.reversedAddress("e84e-ce-52-ce-70") == nil)       // wrong grouping
    }

    @Test func pinSourceAlternatesStartingWithHost() {
        #expect(WiiRemote.pinSource(forAttempt: 0) == .host)
        #expect(WiiRemote.pinSource(forAttempt: 1) == .remote)
        #expect(WiiRemote.pinSource(forAttempt: 2) == .host)
        #expect(WiiRemote.pinSource(forAttempt: 3) == .remote)
    }
}
