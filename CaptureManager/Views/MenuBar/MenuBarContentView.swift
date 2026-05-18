import SwiftUI
import SwiftData

struct MenuBarContentView: View {
    @EnvironmentObject private var viewModel: MenuBarViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @State private var hasSetup = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            captureListView
            Divider()
            footerView
        }
        .frame(width: 340)
        .onAppear {
            if !hasSetup {
                viewModel.setup(modelContext: modelContext)
                hasSetup = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Circle()
                .fill(viewModel.isMonitoring ? .green : .red)
                .frame(width: 8, height: 8)

            Text(viewModel.isMonitoring ? "모니터링 중" : "일시정지")
                .font(.system(size: 12, weight: .medium))

            Spacer()

            if viewModel.processingCount > 0 {
                ProgressView()
                    .controlSize(.small)
                Text("분류 중...")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.toggleMonitoring()
            } label: {
                Image(systemName: viewModel.isMonitoring ? "pause.circle" : "play.circle")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Capture List

    @ViewBuilder
    private var captureListView: some View {
        if viewModel.recentCaptures.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text("캡처된 이미지가 없습니다")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("스크린샷을 찍으면 자동으로 분류됩니다")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.recentCaptures, id: \.originalPath) { item in
                        CaptureRowView(
                            item: item,
                            categories: fetchCategories(),
                            onMove: { capture, categoryName in
                                viewModel.moveCapture(capture, toCategoryName: categoryName)
                            },
                            onOpenInFinder: { capture in
                                viewModel.openInFinder(capture)
                            }
                        )
                        .padding(.horizontal, 12)

                        if item.originalPath != viewModel.recentCaptures.last?.originalPath {
                            Divider().padding(.leading, 66)
                        }
                    }
                }
            }
            .frame(maxHeight: 360)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button("카테고리 브라우저") {
                openWindow(id: "category-browser")
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))

            Spacer()

            SettingsLink {
                Text("설정")
                    .font(.system(size: 11))
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .help("종료")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func fetchCategories() -> [Category] {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
