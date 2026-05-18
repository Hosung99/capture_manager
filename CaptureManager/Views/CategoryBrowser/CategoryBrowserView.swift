import SwiftUI
import SwiftData

struct CategoryBrowserView: View {
    @EnvironmentObject private var viewModel: CategoryBrowserViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var hasSetup = false

    var body: some View {
        NavigationSplitView {
            sidebarView
                .navigationSplitViewColumnWidth(min: 160, ideal: 200)
        } detail: {
            detailView
        }
        .frame(minWidth: 700, minHeight: 450)
        .onAppear {
            if !hasSetup {
                viewModel.setup(modelContext: modelContext)
                hasSetup = true
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        List(selection: Binding(
            get: { viewModel.selectedCategory?.name },
            set: { name in
                let cat = viewModel.categories.first { $0.name == name }
                viewModel.selectCategory(cat)
            }
        )) {
            Section("카테고리") {
                ForEach(viewModel.categories, id: \.name) { category in
                    Label {
                        HStack {
                            Text(category.localizedName)
                            Spacer()
                            Text("\(category.captures.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: category.icon)
                    }
                    .tag(category.name)
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        if viewModel.captures.isEmpty {
            ContentUnavailableView {
                Label("이미지 없음", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text("이 카테고리에 분류된 이미지가 없습니다")
            }
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(viewModel.captures, id: \.originalPath) { item in
                        CaptureGridItemView(item: item, categories: viewModel.categories) { capture, category in
                            viewModel.moveCapture(capture, toCategory: category)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Grid Item

struct CaptureGridItemView: View {
    let item: CaptureItem
    let categories: [Category]
    var onMove: (CaptureItem, Category) -> Void

    var body: some View {
        VStack(spacing: 6) {
            if let data = item.thumbnailData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }

            Text(item.fileName)
                .font(.system(size: 11))
                .lineLimit(1)
                .truncationMode(.middle)

            HStack(spacing: 4) {
                if let cat = item.category {
                    Image(systemName: cat.icon)
                        .font(.system(size: 9))
                }
                Text("\(Int(item.confidenceScore * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(item.confidenceScore >= 0.6 ? .green : .orange)
            }
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .contextMenu {
            Button("Finder에서 열기") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.currentPath)])
            }

            Menu("이동...") {
                ForEach(categories, id: \.name) { category in
                    if category.name != item.category?.name {
                        Button(category.localizedName) {
                            onMove(item, category)
                        }
                    }
                }
            }
        }
    }
}
