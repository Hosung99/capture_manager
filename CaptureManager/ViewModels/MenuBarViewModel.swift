import Foundation
import SwiftData
import AppKit
import Combine

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published var recentCaptures: [CaptureItem] = []
    @Published var isMonitoring = false
    @Published var processingCount = 0

    private let monitor = ScreenshotMonitor()
    private let classifier = AIClassifier()
    private let organizer = FileOrganizer()
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedDefaultCategoriesIfNeeded()

        monitor.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isMonitoring)

        monitor.onNewScreenshot = { [weak self] url in
            Task { @MainActor in
                await self?.processScreenshot(url: url)
            }
        }

        startMonitoring()
        loadRecentCaptures()
    }

    func startMonitoring() {
        guard let settings = fetchSettings() else { return }
        let sourceDir = URL(fileURLWithPath: settings.sourceDirectoryPath)
        monitor.startMonitoring(directory: sourceDir)
    }

    func stopMonitoring() {
        monitor.stopMonitoring()
    }

    func toggleMonitoring() {
        if isMonitoring {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }

    func processScreenshot(url: URL) async {
        guard let context = modelContext else { return }

        processingCount += 1
        defer { processingCount -= 1 }

        let categories = fetchCategories()
        let categoryTuples = categories.map { ($0.name, $0.keywords) }
        let settings = fetchSettings()
        let threshold = settings?.confidenceThreshold ?? AppConstants.defaultConfidenceThreshold

        let result = await classifier.classify(
            imageURL: url,
            categories: categoryTuples,
            confidenceThreshold: threshold
        )

        // Generate thumbnail
        let thumbnailData = NSImage(contentsOf: url)?.thumbnailData()

        // Find matching category
        let matchedCategory = categories.first { $0.name == result.categoryName }

        // Get file size
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        // Create capture item
        let item = CaptureItem(
            originalPath: url.path,
            fileName: url.lastPathComponent,
            category: matchedCategory,
            confidenceScore: result.confidence,
            ocrText: result.ocrText,
            thumbnailData: thumbnailData,
            fileSize: fileSize
        )
        item.classifiedAt = Date()

        // Move file if auto-move is enabled and confidence meets threshold
        if let settings, settings.autoMoveEnabled, result.confidence >= threshold {
            let outputDir = URL(fileURLWithPath: settings.outputDirectoryPath)
            do {
                let categoryDir = try organizer.ensureCategoryDirectory(
                    outputDir: outputDir,
                    categoryName: result.categoryName
                )
                let newURL = try organizer.moveFile(from: url, to: categoryDir)
                item.currentPath = newURL.path
                item.isMoved = true
            } catch {
                print("[MenuBarViewModel] Failed to move file: \(error)")
            }
        }

        context.insert(item)
        try? context.save()

        loadRecentCaptures()
    }

    func loadRecentCaptures() {
        guard let context = modelContext else { return }

        var descriptor = FetchDescriptor<CaptureItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 20

        recentCaptures = (try? context.fetch(descriptor)) ?? []
    }

    func moveCapture(_ item: CaptureItem, toCategoryName: String) {
        guard let settings = fetchSettings() else { return }
        let outputDir = URL(fileURLWithPath: settings.outputDirectoryPath)
        let currentURL = URL(fileURLWithPath: item.currentPath)

        do {
            let newURL = try organizer.reclassifyFile(
                from: currentURL,
                outputDir: outputDir,
                newCategoryName: toCategoryName
            )
            item.currentPath = newURL.path
            item.isMoved = true

            let categories = fetchCategories()
            item.category = categories.first { $0.name == toCategoryName }

            try? modelContext?.save()
            loadRecentCaptures()
        } catch {
            print("[MenuBarViewModel] Reclassify failed: \(error)")
        }
    }

    func openInFinder(_ item: CaptureItem) {
        let url = URL(fileURLWithPath: item.currentPath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - Private

    private func fetchSettings() -> AppSettings? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<AppSettings>()
        return try? context.fetch(descriptor).first
    }

    private func fetchCategories() -> [Category] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private func seedDefaultCategoriesIfNeeded() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Category>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (index, def) in DefaultCategories.all.enumerated() {
            let category = Category(
                name: def.name,
                localizedName: def.localizedName,
                icon: def.icon,
                keywords: def.keywords,
                sortOrder: index,
                isDefault: true
            )
            context.insert(category)
        }

        // Create default settings
        let settings = AppSettings()
        context.insert(settings)

        try? context.save()
        print("[MenuBarViewModel] Seeded \(DefaultCategories.all.count) default categories")
    }
}
