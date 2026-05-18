import Foundation
import Vision
import AppKit

struct ClassificationResult {
    let categoryName: String
    let confidence: Double
    let ocrText: String
}

final class VisionClassifier {
    /// Performs OCR on the image and classifies based on keyword matching.
    func classify(imageURL: URL, categories: [(name: String, keywords: [String])]) async -> ClassificationResult {
        let ocrText = await performOCR(on: imageURL)

        guard !ocrText.isEmpty else {
            return ClassificationResult(categoryName: "Other", confidence: 0.1, ocrText: "")
        }

        let lowerText = ocrText.lowercased()
        var bestCategory = "Other"
        var bestScore: Double = 0

        for category in categories where !category.keywords.isEmpty {
            var matchCount = 0
            for keyword in category.keywords {
                if lowerText.contains(keyword.lowercased()) {
                    matchCount += 1
                }
            }

            guard matchCount > 0 else { continue }

            // Score = matched keywords / total keywords, weighted by match count
            let ratio = Double(matchCount) / Double(category.keywords.count)
            let countBonus = min(Double(matchCount) * 0.1, 0.3)
            let score = min(ratio + countBonus, 1.0)

            if score > bestScore {
                bestScore = score
                bestCategory = category.name
            }
        }

        // Normalize confidence to a meaningful range
        let confidence = bestScore > 0 ? min(bestScore * 1.5, 1.0) : 0.1

        return ClassificationResult(
            categoryName: bestCategory,
            confidence: confidence,
            ocrText: String(ocrText.prefix(2000))
        )
    }

    private func performOCR(on imageURL: URL) async -> String {
        await withCheckedContinuation { continuation in
            guard let image = NSImage(contentsOf: imageURL),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continuation.resume(returning: "")
                return
            }

            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}
