import Foundation

enum ScreenshotPathResolver {
    /// Resolves the macOS screenshot save directory.
    /// Checks `defaults read com.apple.screencapture location` first, falls back to Desktop.
    static func resolve() -> URL {
        if let customPath = readScreencaptureLocation(), !customPath.isEmpty {
            let url = URL(fileURLWithPath: (customPath as NSString).expandingTildeInPath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")
    }

    private static func readScreencaptureLocation() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", "com.apple.screencapture", "location"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
