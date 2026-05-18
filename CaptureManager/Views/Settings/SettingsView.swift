import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var hasSetup = false

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .environmentObject(viewModel)
                .tabItem { Label("일반", systemImage: "gear") }

            CategorySettingsTab()
                .environmentObject(viewModel)
                .tabItem { Label("카테고리", systemImage: "folder") }

            AISettingsTab()
                .environmentObject(viewModel)
                .tabItem { Label("AI", systemImage: "brain") }
        }
        .frame(width: 480, height: 360)
        .onAppear {
            if !hasSetup {
                viewModel.setup(modelContext: modelContext)
                hasSetup = true
            }
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @EnvironmentObject private var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("디렉토리") {
                HStack {
                    Text("소스 (스크린샷)")
                        .frame(width: 110, alignment: .trailing)
                    Text(viewModel.sourceDirectoryPath)
                        .truncationMode(.head)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                    Button("변경") {
                        viewModel.selectSourceDirectory()
                    }
                }

                HStack {
                    Text("출력 (분류)")
                        .frame(width: 110, alignment: .trailing)
                    Text(viewModel.outputDirectoryPath)
                        .truncationMode(.head)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                    Button("변경") {
                        viewModel.selectOutputDirectory()
                    }
                }
            }

            Section("동작") {
                Toggle("자동 이동", isOn: $viewModel.autoMoveEnabled)
                    .onChange(of: viewModel.autoMoveEnabled) { _, _ in
                        viewModel.saveSettings()
                    }

                Toggle("로그인 시 실행", isOn: $viewModel.launchAtLogin)
                    .onChange(of: viewModel.launchAtLogin) { _, _ in
                        viewModel.saveSettings()
                    }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Category Settings

struct CategorySettingsTab: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    @State private var showingAddSheet = false
    @State private var selectedCategory: Category?

    var body: some View {
        VStack {
            List(viewModel.categories, id: \.name, selection: Binding(
                get: { selectedCategory?.name },
                set: { name in
                    selectedCategory = viewModel.categories.first { $0.name == name }
                }
            )) { category in
                HStack {
                    Image(systemName: category.icon)
                        .frame(width: 20)
                    Text(category.localizedName)
                    Spacer()
                    Text("\(category.keywords.count) keywords")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if category.isDefault {
                        Text("기본")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }
                .tag(category.name)
            }

            HStack {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }

                Button(action: {
                    if let cat = selectedCategory {
                        viewModel.deleteCategory(cat)
                        selectedCategory = nil
                    }
                }) {
                    Image(systemName: "minus")
                }
                .disabled(selectedCategory == nil || (selectedCategory?.isDefault ?? true))

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCategorySheet { name, icon, keywords in
                viewModel.addCategory(name: name, icon: icon, keywords: keywords)
            }
        }
    }
}

// MARK: - AI Settings

struct AISettingsTab: View {
    @EnvironmentObject private var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Vision OCR (v1)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("신뢰도 임계값: \(Int(viewModel.confidenceThreshold * 100))%")
                    Slider(value: $viewModel.confidenceThreshold, in: 0.3...0.9, step: 0.05)
                        .onChange(of: viewModel.confidenceThreshold) { _, _ in
                            viewModel.saveSettings()
                        }
                    Text("이 값 이상의 신뢰도일 때만 자동 이동합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("GPT-4o-mini (v2 - 추후 지원)") {
                Text("Vision OCR 신뢰도가 낮을 때 GPT-4o-mini로 폴백하는 기능은 추후 업데이트에서 지원됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = "folder"
    @State private var keywordsText = ""

    var onAdd: (String, String, [String]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("새 카테고리 추가")
                .font(.headline)

            Form {
                TextField("이름", text: $name)
                TextField("아이콘 (SF Symbol)", text: $icon)
                TextField("키워드 (쉼표로 구분)", text: $keywordsText)
            }

            HStack {
                Button("취소") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("추가") {
                    let keywords = keywordsText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    onAdd(name, icon, keywords)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 360)
    }
}
