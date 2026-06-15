import Foundation

// cswap interaction + parsing. Used by the (unsandboxed) app to produce data.
// Compiled into the widget too but unused there.
enum Producer {
    static func locateUsageTool(_ configured: String?) -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            configured,
            home.appendingPathComponent(".local/bin/cswap").path,
            "/opt/homebrew/bin/cswap",
            "/usr/local/bin/cswap",
        ].compactMap { $0 }
        for c in candidates where FileManager.default.isExecutableFile(atPath: c) { return c }
        return nil
    }

    @discardableResult
    static func run(_ path: String, _ args: [String]) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            let out = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            return String(data: out, encoding: .utf8) ?? ""
        } catch {
            return "[error] \(error.localizedDescription)"
        }
    }

    private static func firstMatch(_ pattern: String, _ line: String) -> [String?]? {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let m = re.firstMatch(in: line, range: range) else { return nil }
        var groups: [String?] = []
        for i in 0..<m.numberOfRanges {
            if let r = Range(m.range(at: i), in: line) { groups.append(String(line[r])) }
            else { groups.append(nil) }
        }
        return groups
    }

    static func parse(_ text: String) -> ([Account], [Instance]) {
        var accounts: [Account] = []
        var instances: [Instance] = []
        var section = "accounts"
        var cur: Account?
        func flush() { if let c = cur { accounts.append(c); cur = nil } }

        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw).replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
            if line.hasPrefix("Accounts:") { section = "accounts"; continue }
            if line.hasPrefix("Running instances:") { flush(); section = "instances"; continue }

            if section == "instances" {
                if let g = firstMatch(#"^\s*[●•]\s+(\S+)\s+(.+?)\s+\((.+?)\)\s*$"#, line) {
                    instances.append(Instance(kind: g[1] ?? "", path: (g[2] ?? "").trimmingCharacters(in: .whitespaces), meta: g[3] ?? ""))
                }
                continue
            }

            if let g = firstMatch(#"^\s*(\d+):\s+(.*)$"#, line) {
                flush()
                var rest = g[2] ?? ""
                let activeFlag = rest.range(of: #"\(active\)\s*$"#, options: .regularExpression) != nil
                rest = rest.replacingOccurrences(of: #"\s*\(active\)\s*$"#, with: "", options: .regularExpression)
                var org: String? = nil
                if let om = firstMatch(#"^(.*)\s*\[(.+)\]\s*$"#, rest) {
                    org = om[2]
                    rest = (om[1] ?? "")
                }
                cur = Account(num: g[1] ?? "", email: rest.trimmingCharacters(in: .whitespaces),
                              org: org?.trimmingCharacters(in: .whitespaces), active: activeFlag,
                              h5: nil, d7: nil, h5reset: nil, h5in: nil,
                              d7reset: nil, d7in: nil, unavailable: false)
                continue
            }
            guard cur != nil else { continue }
            if line.range(of: "usage unavailable", options: .caseInsensitive) != nil { cur?.unavailable = true; continue }

            if let g = firstMatch(#"5h:\s*(\d+)%(?:\s+resets\s+(.+?)\s{2,}in\s+(.+?))?\s*$"#, line) {
                cur?.h5 = Int(g[1] ?? "")
                if let r = g[2] { cur?.h5reset = r.trimmingCharacters(in: .whitespaces); cur?.h5in = g[3]?.trimmingCharacters(in: .whitespaces) }
                continue
            }
            if let g = firstMatch(#"7d:\s*(\d+)%(?:\s+resets\s+(.+?)\s{2,}in\s+(.+?))?\s*$"#, line) {
                cur?.d7 = Int(g[1] ?? "")
                if let r = g[2] { cur?.d7reset = r.trimmingCharacters(in: .whitespaces); cur?.d7in = g[3]?.trimmingCharacters(in: .whitespaces) }
                continue
            }
        }
        flush()
        return (accounts, instances)
    }
}
