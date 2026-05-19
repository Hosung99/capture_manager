import FlutterMacOS
import Vision
import AppKit

class VisionOCRPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.capturemanager/ocr",
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(VisionOCRPlugin(), channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "recognizeText",
              let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String
        else {
            result(FlutterMethodNotImplemented)
            return
        }

        let url = URL(fileURLWithPath: filePath)
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = NSImage(contentsOf: url),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
            else {
                result("")
                return
            }

            let request = VNRecognizeTextRequest { req, error in
                guard error == nil,
                      let observations = req.results as? [VNRecognizedTextObservation]
                else {
                    result("")
                    return
                }
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                result(text)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                result("")
            }
        }
    }
}
