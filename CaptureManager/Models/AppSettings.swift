import Foundation
import SwiftData

@Model
final class AppSettings {
    var sourceDirectoryBookmark: Data?
    var outputDirectoryBookmark: Data?
    var sourceDirectoryPath: String
    var outputDirectoryPath: String
    var autoMoveEnabled: Bool
    var confidenceThreshold: Double
    var launchAtLogin: Bool
    var isMonitoringEnabled: Bool
    var hasCompletedSetup: Bool

    init() {
        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path ?? "~/Desktop"
        self.sourceDirectoryPath = desktopPath
        self.outputDirectoryPath = (desktopPath as NSString).appendingPathComponent(AppConstants.defaultOutputDirectoryName)
        self.autoMoveEnabled = true
        self.confidenceThreshold = AppConstants.defaultConfidenceThreshold
        self.launchAtLogin = false
        self.isMonitoringEnabled = true
        self.hasCompletedSetup = false
    }
}
