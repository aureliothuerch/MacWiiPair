// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurelio Thuer

import SwiftUI

@main
struct MacWiiPairApp: App {
    var body: some Scene {
        WindowGroup("MacWiiPair") { ContentView() }
            .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @StateObject private var pairer = Pairer()

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "gamecontroller.fill").font(.system(size: 42))
            Text(pairer.status).font(.headline).multilineTextAlignment(.center)
            Text("Start Dolphin first. Then click Pair and press SYNC (under the battery cover) on the Wii Remote.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button(pairer.isBusy ? "Stop" : "Pair Wii Remote") {
                pairer.isBusy ? pairer.stop() : pairer.start()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
            ScrollView {
                Text(pairer.logLines.joined(separator: "\n"))
                    .font(.caption.monospaced()).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 130).padding(8)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(24).frame(width: 440)
    }
}
