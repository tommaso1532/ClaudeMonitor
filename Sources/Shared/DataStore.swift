import Foundation

// Under App Sandbox, homeDirectoryForCurrentUser is this process's own container
// (…/Library/Containers/<bundle-id>/Data). The unsandboxed LaunchAgent writes
// data.json into that exact dir, so the sandboxed widget/app can read it without
// an App Group (which a free Personal Team can't provision).
enum DataStore {
    static var fileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("data.json")
    }

    static func load() -> ClaudeData? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(ClaudeData.self, from: data)
    }
}
