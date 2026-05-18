import SwiftUI
import SwiftData

@main
struct CaptureManagerApp: App {
    @StateObject private var menuBarVM = MenuBarViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var browserVM = CategoryBrowserViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            CaptureItem.self,
            AppSettings.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(menuBarVM)
                .modelContainer(sharedModelContainer)
        } label: {
            Image(systemName: "camera.viewfinder")
        }
        .menuBarExtraStyle(.window)

        Window("카테고리 브라우저", id: "category-browser") {
            CategoryBrowserView()
                .environmentObject(browserVM)
                .modelContainer(sharedModelContainer)
        }

        Settings {
            SettingsView()
                .environmentObject(settingsVM)
                .modelContainer(sharedModelContainer)
        }
    }
}
