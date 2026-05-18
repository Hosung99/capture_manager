import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var name: String
    var localizedName: String
    var icon: String
    var keywords: [String]
    var sortOrder: Int
    var isDefault: Bool
    var directoryName: String

    @Relationship(deleteRule: .nullify, inverse: \CaptureItem.category)
    var captures: [CaptureItem] = []

    var createdAt: Date

    init(
        name: String,
        localizedName: String,
        icon: String,
        keywords: [String],
        sortOrder: Int,
        isDefault: Bool = false,
        directoryName: String? = nil
    ) {
        self.name = name
        self.localizedName = localizedName
        self.icon = icon
        self.keywords = keywords
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.directoryName = directoryName ?? name
        self.createdAt = Date()
    }
}
