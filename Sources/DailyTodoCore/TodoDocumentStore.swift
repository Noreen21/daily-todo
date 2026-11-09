import Darwin
import Foundation

public struct TodoDocumentStore {
    private let fileURL: URL
    private let legacyFileURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    public static let privateDirectoryPermissions: Int = 0o700
    public static let privateFilePermissions: Int = 0o600

    public init(
        fileURL: URL,
        legacyFileURL: URL? = TodoDocumentStore.legacyFileURL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.legacyFileURL = legacyFileURL
        self.fileManager = fileManager
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Pre-sandbox location used by older builds and non-sandboxed launches.
    public static var legacyFileURL: URL? {
        guard let home = realUserHomeDirectoryURL() else { return nil }
        return home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("DailyTodo", isDirectory: true)
            .appendingPathComponent("daily-todo.json", isDirectory: false)
    }

    public func load() -> TodoDocument {
        let primaryDocument = decodeDocument(at: fileURL)
        guard let legacyURL = legacyFileURL,
              legacyURL.standardizedFileURL != fileURL.standardizedFileURL else {
            return primaryDocument ?? TodoDocument()
        }

        let legacyDocument = decodeDocument(at: legacyURL)
        let mergedDocument = Self.merge(primary: primaryDocument, legacy: legacyDocument)

        if let mergedDocument,
           mergedDocument != primaryDocument {
            try? save(mergedDocument)
            return mergedDocument
        }

        return primaryDocument ?? legacyDocument ?? TodoDocument()
    }

    public func save(_ document: TodoDocument) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        try applyPOSIXPermissions(
            TodoDocumentStore.privateDirectoryPermissions,
            to: directoryURL
        )
        let data = try encoder.encode(document)
        try writePrivateFile(data, to: fileURL)
    }

    public static func merge(
        primary: TodoDocument?,
        legacy: TodoDocument?
    ) -> TodoDocument? {
        switch (primary, legacy) {
        case (nil, nil):
            return nil
        case (let primary?, nil):
            return primary
        case (nil, let legacy?):
            return legacy
        case (let primary?, let legacy?):
            var mergedItemsByID = Dictionary(
                uniqueKeysWithValues: legacy.items.map { ($0.id, $0) }
            )
            for item in primary.items {
                mergedItemsByID[item.id] = item
            }

            var merged = primary
            merged.items = mergedItemsByID.values.sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            if merged.lastReminderDayKey == nil {
                merged.lastReminderDayKey = legacy.lastReminderDayKey
            }
            return merged
        }
    }

    private func decodeDocument(at url: URL) -> TodoDocument? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        do {
            return try decoder.decode(TodoDocument.self, from: data)
        } catch {
            let backupURL = url.appendingPathExtension("invalid")
            try? fileManager.removeItem(at: backupURL)
            try? writePrivateFile(data, to: backupURL)
            return nil
        }
    }

    private func writePrivateFile(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
        try applyPOSIXPermissions(TodoDocumentStore.privateFilePermissions, to: url)
    }

    private func applyPOSIXPermissions(_ permissions: Int, to url: URL) throws {
        try fileManager.setAttributes(
            [.posixPermissions: permissions],
            ofItemAtPath: url.path
        )
    }

    private static func realUserHomeDirectoryURL() -> URL? {
        guard let passwd = getpwuid(getuid()), let home = passwd.pointee.pw_dir else {
            return nil
        }
        return URL(fileURLWithPath: String(cString: home), isDirectory: true)
    }
}
