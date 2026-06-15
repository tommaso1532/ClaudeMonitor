import WidgetKit
import SwiftUI

// Weather-style background: deep blue glass gradient (system adds desktop blur).
struct WidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.13, green: 0.22, blue: 0.34),
                     Color(red: 0.06, green: 0.10, blue: 0.17)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

struct ClaudeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClaudeEntry

    var body: some View {
        if let data = entry.data, !data.accounts.isEmpty {
            switch family {
            case .systemSmall: SmallView(data: data)
            case .systemLarge: LargeView(data: data)
            default:           MediumView(data: data)
            }
        } else {
            UnavailableView()
        }
    }
}

// MARK: - Small (mirrors weather "current" tile)

struct SmallView: View {
    let data: ClaudeData
    var body: some View {
        let a = active(data)
        let th = data.settings.thresholds
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(shortName(a.email))
                    .font(.headline).fontWeight(.semibold).lineLimit(1)
                    .foregroundStyle(.white)
                Spacer()
                Image("ClaudeMenuBar")
                    .resizable().renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Usage.color(a.h5, th))
            }
            Spacer(minLength: 2)
            Text(a.unavailable ? "—" : "\(a.h5 ?? 0)%")
                .font(.system(size: 46, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
            Text("5h usage")
                .font(.caption2).foregroundStyle(.white.opacity(0.6))
            Spacer(minLength: 2)
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text("7d \(a.d7.map { "\($0)%" } ?? "—")")
                Spacer()
                if let r = a.h5in { Text(r) }
            }
            .font(.caption2).foregroundStyle(.white.opacity(0.75))
        }
    }
}

// MARK: - Medium (active on left, other accounts as "forecast" rows)

struct MediumView: View {
    let data: ClaudeData
    var body: some View {
        let a = active(data)
        let others = data.accounts.filter { $0.num != a.num }
        let th = data.settings.thresholds
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(shortName(a.email))
                    .font(.subheadline).fontWeight(.semibold).lineLimit(1)
                    .foregroundStyle(.white)
                Text(a.unavailable ? "—" : "\(a.h5 ?? 0)%")
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                Text("5h usage")
                    .font(.caption2).foregroundStyle(.white.opacity(0.6))
                Spacer(minLength: 4)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text("7d \(a.d7.map { "\($0)%" } ?? "—")")
                }
                .font(.caption2).foregroundStyle(.white.opacity(0.75))
                if let r = a.h5reset {
                    Text("resets \(r)")
                        .font(.caption2).foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 7) {
                ForEach(others.prefix(4)) { AccountRow(acc: $0, th: th) }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Large (header + every account + running instances)

struct LargeView: View {
    let data: ClaudeData
    var body: some View {
        let a = active(data)
        let th = data.settings.thresholds
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(shortName(a.email)).font(.headline).foregroundStyle(.white)
                    Text(a.unavailable ? "—" : "\(a.h5 ?? 0)%")
                        .font(.system(size: 50, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                    Text("5h usage · 7d \(a.d7.map { "\($0)%" } ?? "—")")
                        .font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image("ClaudeMenuBar")
                    .resizable().renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Usage.color(a.h5, th))
            }
            Divider().overlay(Color.white.opacity(0.15))
            ForEach(data.accounts) { AccountRow(acc: $0, th: th) }
            if data.settings.showInstances != false, !data.instances.isEmpty {
                Divider().overlay(Color.white.opacity(0.15))
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill").font(.caption2)
                    Text("\(data.instances.count) running")
                        .font(.caption2).foregroundStyle(.white.opacity(0.7))
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Shared row

struct AccountRow: View {
    let acc: Account
    let th: Thresholds?
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(acc.active ? Color(red: 0.24, green: 0.86, blue: 0.52) : Color.white.opacity(0.25))
                .frame(width: 6, height: 6)
            Text(shortName(acc.email))
                .font(.caption).foregroundStyle(.white).lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if acc.unavailable {
                Text("—").font(.caption).foregroundStyle(.white.opacity(0.4))
            } else {
                Text("\(acc.h5 ?? 0)%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Usage.color(acc.h5, th))
                    .frame(width: 36, alignment: .trailing)
                Text("\(acc.d7 ?? 0)%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Usage.color(acc.d7, th))
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }
}

struct UnavailableView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.slash.fill").foregroundStyle(.white.opacity(0.6))
            Text("No data").font(.caption).foregroundStyle(.white.opacity(0.75))
            Text("Open ClaudeMonitor app").font(.caption2).foregroundStyle(.white.opacity(0.45))
        }
    }
}
