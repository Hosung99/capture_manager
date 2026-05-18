import SwiftUI

struct CaptureRowView: View {
    let item: CaptureItem
    let categories: [Category]
    var onMove: ((CaptureItem, String) -> Void)?
    var onOpenInFinder: ((CaptureItem) -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail
            if let data = item.thumbnailData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let category = item.category {
                        Label(category.localizedName, systemImage: category.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Text(confidenceLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(confidenceColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(confidenceColor.opacity(0.1), in: Capsule())
                }

                Text(item.createdAt, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            if let onOpenInFinder {
                Button("Finder에서 열기") {
                    onOpenInFinder(item)
                }
            }

            if let onMove {
                Menu("이동...") {
                    ForEach(categories, id: \.name) { category in
                        if category.name != item.category?.name {
                            Button(category.localizedName) {
                                onMove(item, category.name)
                            }
                        }
                    }
                }
            }
        }
    }

    private var confidenceLabel: String {
        "\(Int(item.confidenceScore * 100))%"
    }

    private var confidenceColor: Color {
        if item.confidenceScore >= 0.7 { return .green }
        if item.confidenceScore >= 0.4 { return .orange }
        return .red
    }
}
