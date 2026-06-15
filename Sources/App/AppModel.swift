import SwiftUI
import WidgetKit
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var data: ClaudeData?
    @Published var mode: String {
        didSet { UserDefaults.standard.set(mode, forKey: "mode"); applyMode(); refresh() }
    }
    @Published var refreshSeconds: Int {
        didSet { UserDefaults.standard.set(refreshSeconds, forKey: "refreshSeconds"); startTimer() }
    }

    private var timer: Timer?

    private init() {
        mode = UserDefaults.standard.string(forKey: "mode") ?? "both"
        let r = UserDefaults.standard.integer(forKey: "refreshSeconds")
        refreshSeconds = (r == 0) ? 300 : r
        data = AppModel.loadInitial()
    }

    var showMenuBar: Bool { mode != "widget" }

    var menuTitle: String {
        guard let d = data, let a = d.accounts.first(where: { $0.active }) ?? d.accounts.first,
              !a.unavailable, let h5 = a.h5 else { return "—" }
        return "\(h5)%"
    }

    func setMode(_ m: String) { mode = m }

    // MARK: lifecycle

    func bootstrap() {
        if SMAppService.mainApp.status != .enabled { try? SMAppService.mainApp.register() }
        applyMode()
        refresh()
        startTimer()
    }

    func applyMode() {
        NSApp.setActivationPolicy(mode == "widget" ? .regular : .accessory)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(max(refreshSeconds, 30)), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    // MARK: producing data (off the main thread, results applied on main)

    func refresh() {
        let mode = self.mode
        let rs = self.refreshSeconds
        Task.detached(priority: .utility) {
            let d = AppModel.produce(mode: mode, refresh: rs)
            await MainActor.run {
                self.data = d
                AppModel.writeData(d)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    func switchTo(_ num: String) {
        Task.detached(priority: .userInitiated) {
            if let c = Producer.locateUsageTool(nil) { Producer.run(c, ["--switch-to", num]) }
            await MainActor.run { self.refresh() }
        }
    }

    // MARK: nonisolated helpers

    private static let iso = ISO8601DateFormatter()

    nonisolated static func produce(mode: String, refresh: Int) -> ClaudeData {
        var settings = ClaudeSettings.defaults
        settings.mode = mode
        settings.refreshSeconds = refresh
        guard let cswap = Producer.locateUsageTool(nil) else {
            return ClaudeData(ok: false, ts: iso.string(from: Date()), settings: settings, accounts: [], instances: [])
        }
        settings.cswapPath = cswap
        let text = Producer.run(cswap, ["--list"])
        var (accounts, instances) = Producer.parse(text)
        if settings.showInstances == false { instances = [] }
        let ok = !accounts.isEmpty || !text.contains("[error]")
        return ClaudeData(ok: ok, ts: iso.string(from: Date()), settings: settings, accounts: accounts, instances: instances)
    }

    nonisolated static func writeData(_ data: ClaudeData) {
        guard let blob = try? JSONEncoder().encode(data) else { return }
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dirs = [
            home.appendingPathComponent("Library/Containers/app.claudemonitor.ClaudeMonitor.ClaudeWidget/Data"),
            home.appendingPathComponent("Library/Application Support/ClaudeMonitor"),
        ]
        for dir in dirs {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? blob.write(to: dir.appendingPathComponent("data.json"), options: .atomic)
        }
    }

    nonisolated static func loadInitial() -> ClaudeData? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/ClaudeMonitor/data.json")
        guard let d = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ClaudeData.self, from: d)
    }
}
