import Foundation
import SwiftData
import AppKit
import ServiceManagement

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var sourceDirectoryPath: String = ""
    @Published var outputDirectoryPath: String = ""
    @Published var autoMoveEnabled: Bool = true
    @Published var confidenceThreshold: Double = 0.6
    @Published var launchAtLogin: Bool = false
    @Published var categories: [Category] = []

    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
        loadCategories()
    }

    func loadSettings() {
        guard let settings = fetchSettings() else { return }
        sourceDirectoryPath = settings.sourceDirectoryPath
        outputDirectoryPath = settings.outputDirectoryPath
        autoMoveEnabled = settings.autoMoveEnabled
        confidenceThreshold = settings.confidenceThreshold
        launchAtLogin = settings.launchAtLogin
    }

    func saveSettings() {
        guard let settings = fetchSettings() else { return }
        settings.sourceDirectoryPath = sourceDirectoryPath
        settings.outputDirectoryPath = outputDirectoryPath
        settings.autoMoveEnabled = autoMoveEnabled
        settings.confidenceThreshold = confidenceThreshold
        settings.launchAtLogin = launchAtLogin
        try? modelContext?.save()

        updateLaunchAtLogin(launchAtLogin)
    }

    func selectSourceDirectory() {
        if let url = showDirectoryPicker(title: "Select Screenshot Source Directory") {
            sourceDirectoryPath = url.path
            saveSettings()
        }
    }

    func selectOutputDirectory() {
        if let url = showDirectoryPicker(title: "Select Output Directory") {
            outputDirectoryPath = url.path
            saveSettings()
        }
    }

    func loadCategories() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        categories = (try? context.fetch(descriptor)) ?? []
    }

    func addCategory(name: String, icon: String, keywords: [String]) {
        guard let context = modelContext else { return }
        let category = Category(
            name: name,
            localizedName: name,
            icon: icon,
            keywords: keywords,
            sortOrder: categories.count
        )
        context.insert(category)
        try? context.save()
        loadCategories()
    }

    func deleteCategory(_ category: Category) {
        guard let context = modelContext, !category.isDefault else { return }
        context.delete(category)
        try? context.save()
        loadCategories()
    }

    func updateCategoryKeywords(_ category: Category, keywords: [String]) {
        category.keywords = keywords
        try? modelContext?.save()
    }

    // MARK: - Private

    private func fetchSettings() -> AppSettings? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<AppSettings>()
        return try? context.fetch(descriptor).first
    }

    private func showDirectoryPicker(title: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        return panel.runModal() == .OK ? panel.url : nil
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[Settings] Launch at login error: \(error)")
            }
        }
    }
}
