import Foundation
import SwiftData

/// Orchestrates classification pipeline. v1: Vision OCR only. v2: GPT fallback.
final class AIClassifier {
    private let visionClassifier = VisionClassifier()

    func classify(
        imageURL: URL,
        categories: [(name: String, keywords: [String])],
        confidenceThreshold: Double
    ) async -> ClassificationResult {
        // Stage 1: Apple Vision OCR + keyword heuristic
        let result = await visionClassifier.classify(imageURL: imageURL, categories: categories)

        // v2 TODO: If result.confidence < confidenceThreshold, call GPT-4o-mini fallback

        return result
    }
}
