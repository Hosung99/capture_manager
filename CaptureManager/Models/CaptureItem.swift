import Foundation
import SwiftData

@Model
final class CaptureItem {
    var originalPath: String
    var currentPath: String
    var fileName: String
    var category: Category?
    var confidenceScore: Double
    var ocrText: String?
    var thumbnailData: Data?
    var fileSize: Int64
    var classifiedAt: Date?
    var createdAt: Date
    var isMoved: Bool

    init(
        originalPath: String,
        currentPath: String? = nil,
        fileName: String,
        category: Category? = nil,
        confidenceScore: Double = 0,
        ocrText: String? = nil,
        thumbnailData: Data? = nil,
        fileSize: Int64 = 0
    ) {
        self.originalPath = originalPath
        self.currentPath = currentPath ?? originalPath
        self.fileName = fileName
        self.category = category
        self.confidenceScore = confidenceScore
        self.ocrText = ocrText
        self.thumbnailData = thumbnailData
        self.fileSize = fileSize
        self.createdAt = Date()
        self.isMoved = false
    }
}
