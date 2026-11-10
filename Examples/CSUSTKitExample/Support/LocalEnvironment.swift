import Foundation

enum LocalEnvironment {
    static func value(for key: String) -> String? {
        ProcessInfo.processInfo.environment[key] ?? fileValues[key]
    }

    private static let fileValues: [String: String] = {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".env")
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }

        var values: [String: String] = [:]
        for line in content.split(whereSeparator: \.isNewline) where !line.hasPrefix("#") {
            let parts = line.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            if parts.count == 2, !parts[0].isEmpty {
                values[parts[0]] = parts[1]
            }
        }
        return values
    }()
}
