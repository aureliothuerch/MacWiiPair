// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurelio Thuer

import Foundation

// Log file for bug reports: ~/Library/Logs/MacWiiPair.log
enum FileLog {
    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/MacWiiPair.log")

    private static let queue = DispatchQueue(label: "MacWiiPair.FileLog")
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func write(_ line: String) {
        let entry = "\(formatter.string(from: Date())) \(line)\n"
        queue.async {
            guard let data = entry.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: url)
            }
        }
    }
}
