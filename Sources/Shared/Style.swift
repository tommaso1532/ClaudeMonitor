import SwiftUI

enum Usage {
    static func color(_ pct: Int?, _ th: Thresholds?) -> Color {
        guard let p = pct else { return Color.gray }
        let crit = th?.crit ?? 80
        let warn = th?.warn ?? 50
        if p >= crit { return Color(red: 1.0, green: 0.36, blue: 0.36) }   // red
        if p >= warn { return Color(red: 1.0, green: 0.70, blue: 0.25) }   // amber
        return Color(red: 0.24, green: 0.86, blue: 0.52)                   // green
    }
}

func shortName(_ email: String) -> String {
    String(email.split(separator: "@").first ?? Substring(email))
}

func active(_ d: ClaudeData) -> Account {
    d.accounts.first(where: { $0.active }) ?? d.accounts[0]
}
