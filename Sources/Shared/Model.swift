import Foundation

// Mirrors the usage JSON produced from the cswap CLI.

struct ClaudeData: Codable {
    var ok: Bool
    var ts: String
    var settings: ClaudeSettings
    var accounts: [Account]
    var instances: [Instance]
}

struct ClaudeSettings: Codable {
    var cswapPath: String?
    var mode: String?            // "widget" | "menubar" | "both" (app-only)
    var refreshSeconds: Int?
    var show5h: Bool?
    var show7d: Bool?
    var showResetTimers: Bool?
    var showInstances: Bool?
    var thresholds: Thresholds?

    static let defaults = ClaudeSettings(
        cswapPath: nil, mode: "both", refreshSeconds: 300,
        show5h: true, show7d: true, showResetTimers: true, showInstances: true,
        thresholds: Thresholds(warn: 50, crit: 80)
    )
}

struct Thresholds: Codable {
    var warn: Int
    var crit: Int
}

struct Account: Codable, Identifiable {
    var num: String
    var email: String
    var org: String?
    var active: Bool
    var h5: Int?
    var d7: Int?
    var h5reset: String?
    var h5in: String?
    var d7reset: String?
    var d7in: String?
    var unavailable: Bool
    var id: String { num }
}

struct Instance: Codable, Identifiable {
    var kind: String
    var path: String
    var meta: String
    var id: String { kind + "|" + path }
}
