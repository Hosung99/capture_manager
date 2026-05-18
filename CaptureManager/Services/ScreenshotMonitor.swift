import Foundation
import Combine

final class ScreenshotMonitor: ObservableObject {
    @Published var isMonitoring = false

    private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let monitorQueue = DispatchQueue(label: "com.capturemanager.monitor", qos: .utility)
    private var knownFiles: Set<String> = []
    private var debounceWorkItem: DispatchWorkItem?

    var onNewScreenshot: ((URL) -> Void)?

    private let screenshotRegexes: [NSRegularExpression] = {
        AppConstants.screenshotPatterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [])
        }
    }()

    func startMonitoring(directory: URL) {
        stopMonitoring()

        let path = directory.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("[ScreenshotMonitor] Failed to open directory: \(path)")
            return
        }

        // Snapshot current files
        knownFiles = Set(
            (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
        )

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: monitorQueue
        )

        source.setEventHandler { [weak self] in
            self?.handleDirectoryChange(at: directory)
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        dispatchSource = source
        source.resume()

        DispatchQueue.main.async {
            self.isMonitoring = true
        }
        print("[ScreenshotMonitor] Monitoring: \(path)")
    }

    func stopMonitoring() {
        debounceWorkItem?.cancel()
        dispatchSource?.cancel()
        dispatchSource = nil

        DispatchQueue.main.async {
            self.isMonitoring = false
        }
    }

    private func handleDirectoryChange(at directory: URL) {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.detectNewScreenshots(in: directory)
        }

        debounceWorkItem = workItem
        monitorQueue.asyncAfter(
            deadline: .now() + AppConstants.fileEventDebounceInterval,
            execute: workItem
        )
    }

    private func detectNewScreenshots(in directory: URL) {
        guard let currentFiles = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return }

        let currentSet = Set(currentFiles)
        let newFiles = currentSet.subtracting(knownFiles)
        knownFiles = currentSet

        for fileName in newFiles {
            guard isScreenshot(fileName: fileName) else { continue }

            let fileURL = directory.appendingPathComponent(fileName)

            // Verify the file exists and is not a temp file
            guard FileManager.default.fileExists(atPath: fileURL.path),
                  !fileName.hasPrefix(".") else { continue }

            // Check file has image extension
            let ext = fileURL.pathExtension.lowercased()
            guard ["png", "jpg", "jpeg", "tiff", "heic"].contains(ext) else { continue }

            DispatchQueue.main.async { [weak self] in
                self?.onNewScreenshot?(fileURL)
            }
        }
    }

    private func isScreenshot(fileName: String) -> Bool {
        let name = (fileName as NSString).deletingPathExtension
        let range = NSRange(location: 0, length: name.utf16.count)
        return screenshotRegexes.contains { regex in
            regex.firstMatch(in: name, options: [], range: range) != nil
        }
    }

    deinit {
        stopMonitoring()
    }
}
