import Foundation

enum FileOrganizerError: LocalizedError {
    case sourceNotFound
    case directoryCreationFailed(String)
    case moveFailed(String)
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .sourceNotFound:
            return "Source file not found."
        case .directoryCreationFailed(let path):
            return "Failed to create directory: \(path)"
        case .moveFailed(let detail):
            return "Failed to move file: \(detail)"
        case .copyFailed(let detail):
            return "Failed to copy file: \(detail)"
        }
    }
}

final class FileOrganizer {
    private let fileManager = FileManager.default

    /// Ensures the category subdirectory exists under the output directory.
    func ensureCategoryDirectory(outputDir: URL, categoryName: String) throws -> URL {
        let categoryDir = outputDir.appendingPathComponent(categoryName)
        if !fileManager.fileExists(atPath: categoryDir.path) {
            do {
                try fileManager.createDirectory(at: categoryDir, withIntermediateDirectories: true)
            } catch {
                throw FileOrganizerError.directoryCreationFailed(categoryDir.path)
            }
        }
        return categoryDir
    }

    /// Moves a file to the target category directory, returning the new URL.
    @discardableResult
    func moveFile(from source: URL, to categoryDir: URL) throws -> URL {
        guard fileManager.fileExists(atPath: source.path) else {
            throw FileOrganizerError.sourceNotFound
        }

        var destination = categoryDir.appendingPathComponent(source.lastPathComponent)
        destination = resolveNameConflict(destination)

        do {
            try fileManager.moveItem(at: source, to: destination)
        } catch {
            throw FileOrganizerError.moveFailed(error.localizedDescription)
        }

        return destination
    }

    /// Copies a file to the target category directory, returning the new URL.
    @discardableResult
    func copyFile(from source: URL, to categoryDir: URL) throws -> URL {
        guard fileManager.fileExists(atPath: source.path) else {
            throw FileOrganizerError.sourceNotFound
        }

        var destination = categoryDir.appendingPathComponent(source.lastPathComponent)
        destination = resolveNameConflict(destination)

        do {
            try fileManager.copyItem(at: source, to: destination)
        } catch {
            throw FileOrganizerError.copyFailed(error.localizedDescription)
        }

        return destination
    }

    /// Re-classifies: moves a file from its current location to a new category directory.
    @discardableResult
    func reclassifyFile(from currentPath: URL, outputDir: URL, newCategoryName: String) throws -> URL {
        let newCategoryDir = try ensureCategoryDirectory(outputDir: outputDir, categoryName: newCategoryName)
        return try moveFile(from: currentPath, to: newCategoryDir)
    }

    // MARK: - Private

    private func resolveNameConflict(_ url: URL) -> URL {
        guard fileManager.fileExists(atPath: url.path) else { return url }

        let directory = url.deletingLastPathComponent()
        let nameWithoutExt = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 1
        var newURL: URL
        repeat {
            let newName = ext.isEmpty ? "\(nameWithoutExt) (\(counter))" : "\(nameWithoutExt) (\(counter)).\(ext)"
            newURL = directory.appendingPathComponent(newName)
            counter += 1
        } while fileManager.fileExists(atPath: newURL.path)

        return newURL
    }
}
