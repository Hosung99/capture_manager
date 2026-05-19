import FlutterMacOS
import Foundation

/// Manages security-scoped bookmarks for sandbox-compatible persistent directory access.
/// Without this, file_picker-selected paths are only valid during the current session.
class BookmarkPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.capturemanager/bookmark",
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(BookmarkPlugin(), channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "saveBookmark":
            saveBookmark(call: call, result: result)
        case "restoreAccess":
            restoreAccess(call: call, result: result)
        case "stopAccess":
            stopAccess(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func saveBookmark(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let key = args["key"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "path and key required", details: nil))
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: "bookmark_\(key)")
            result(true)
        } catch {
            result(FlutterError(code: "BOOKMARK_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    private func restoreAccess(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let bookmark = UserDefaults.standard.data(forKey: "bookmark_\(key)")
        else {
            result(nil)
            return
        }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            guard url.startAccessingSecurityScopedResource() else {
                result(nil)
                return
            }
            result(url.path)
        } catch {
            result(nil)
        }
    }

    private func stopAccess(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String
        else {
            result(nil)
            return
        }
        URL(fileURLWithPath: path).stopAccessingSecurityScopedResource()
        result(true)
    }
}
