import Foundation
import SwiftData

@MainActor
final class CategoryBrowserViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var captures: [CaptureItem] = []

    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCategories()
    }

    func loadCategories() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        categories = (try? context.fetch(descriptor)) ?? []
    }

    func selectCategory(_ category: Category?) {
        selectedCategory = category
        loadCaptures()
    }

    func loadCaptures() {
        guard let context = modelContext else { return }

        if let selected = selectedCategory {
            let categoryName = selected.name
            let descriptor = FetchDescriptor<CaptureItem>(
                predicate: #Predicate<CaptureItem> { item in
                    item.category?.name == categoryName
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            captures = (try? context.fetch(descriptor)) ?? []
        } else {
            let descriptor = FetchDescriptor<CaptureItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            captures = (try? context.fetch(descriptor)) ?? []
        }
    }

    func moveCapture(_ item: CaptureItem, toCategory: Category) {
        guard let context = modelContext else { return }

        let organizer = FileOrganizer()
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        guard let settings = try? context.fetch(settingsDescriptor).first else { return }

        let outputDir = URL(fileURLWithPath: settings.outputDirectoryPath)
        let currentURL = URL(fileURLWithPath: item.currentPath)

        do {
            let newURL = try organizer.reclassifyFile(
                from: currentURL,
                outputDir: outputDir,
                newCategoryName: toCategory.name
            )
            item.currentPath = newURL.path
            item.category = toCategory
            item.isMoved = true
            try? context.save()
            loadCaptures()
        } catch {
            print("[CategoryBrowser] Move failed: \(error)")
        }
    }
}
