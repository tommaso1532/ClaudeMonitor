import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ClaudeMonitor").font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Display").font(.headline)
                    Spacer()
                    Picker("Display", selection: Binding(get: { model.mode }, set: { model.setMode($0) })) {
                        Text("Desktop widget").tag("widget")
                        Text("Menu bar").tag("menubar")
                        Text("Both").tag("both")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 180)
                }
                Text(hint).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("Refresh every").font(.headline)
                Spacer()
                Stepper(value: Binding(get: { model.refreshSeconds },
                                       set: { model.refreshSeconds = $0 }),
                        in: 60...1800, step: 60) {
                    Text("\(model.refreshSeconds)s").monospacedDigit()
                }
            }

            Divider()

            if let d = model.data, !d.accounts.isEmpty {
                VStack(spacing: 0) {
                    ForEach(d.accounts) { a in
                        AccountSettingsRow(acc: a, th: d.settings.thresholds)
                            .padding(.vertical, 12)

                        if a.id != d.accounts.last?.id {
                            Divider()
                        }
                    }
                }
            } else {
                Text("Loading…").foregroundStyle(.secondary)
            }

            HStack {
                Button("Reload now") { model.refresh() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(24)
        .frame(width: 540)
    }

    private var hint: String {
        switch model.mode {
        case "widget":  return "Add it from the desktop → Edit Widgets → “ClaudeMonitor”. Menu bar icon hidden; the app keeps the widget updated in the background."
        case "menubar": return "Lives in the menu bar only (no Dock icon)."
        default:        return "Shows in the menu bar and is available as a desktop widget."
        }
    }
}

private struct AccountSettingsRow: View {
    let acc: Account
    let th: Thresholds?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Circle()
                    .fill(acc.active ? Color(red: 0.24, green: 0.86, blue: 0.52) : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)

                Text(acc.email)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 12)

                if acc.active {
                    Text("Active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.24, green: 0.86, blue: 0.52))
                }
            }

            if acc.unavailable {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                    Text("Usage unavailable")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 17)
            } else {
                HStack(alignment: .top, spacing: 16) {
                    AccountUsageMetric(
                        label: "5h",
                        value: percent(acc.h5),
                        tint: Usage.color(acc.h5, th),
                        reset: acc.h5in
                    )

                    Divider().frame(height: 34)

                    AccountUsageMetric(
                        label: "7d",
                        value: percent(acc.d7),
                        tint: Usage.color(acc.d7, th),
                        reset: acc.d7in
                    )
                }
                .padding(.leading, 17)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct AccountUsageMetric: View {
    let label: String
    let value: String
    let tint: Color
    let reset: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body.weight(.semibold).monospacedDigit())
                    .foregroundStyle(tint)
            }

            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(resetText)
                    .lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resetText: String {
        guard let reset, !reset.isEmpty else { return "reset unavailable" }
        return "reset in \(reset)"
    }
}

private func percent(_ value: Int?) -> String {
    value.map { "\($0)%" } ?? "-"
}
