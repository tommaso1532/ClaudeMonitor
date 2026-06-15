import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var model: AppModel
    var body: some View {
        // Claude starburst + active 5h usage, like a compact weather readout.
        Image("StatusBarIcon")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
        Text(model.menuTitle)
    }
}

struct MenuBarContent: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Claude Accounts")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 6)

            if let d = model.data, !d.accounts.isEmpty {
                ForEach(d.accounts) { a in
                    AccountMenuRow(acc: a, th: d.settings.thresholds) {
                        if !a.active { model.switchTo(a.num) }
                    }
                }
                if d.settings.showInstances != false, !d.instances.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text("\(d.instances.count) running")
                        .font(.caption).foregroundStyle(.secondary)
                        .padding(.horizontal, 12).padding(.bottom, 4)
                }
            } else {
                Text("No data yet…")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12).padding(.bottom, 6)
            }

            Divider().padding(.vertical, 4)

            Button("Settings…") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
            .buttonStyle(.plain).padding(.horizontal, 12).padding(.vertical, 4)

            Button("Reload now") { model.refresh() }
                .buttonStyle(.plain).padding(.horizontal, 12).padding(.vertical, 4)

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain).padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 10)
        }
        .frame(width: 260)
    }
}

private struct AccountMenuRow: View {
    let acc: Account
    let th: Thresholds?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle().fill(acc.active ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 6, height: 6)
                Text(shortName(acc.email)).lineLimit(1)
                Spacer()
                if acc.unavailable {
                    Text("—").foregroundStyle(.secondary)
                } else {
                    Text("\(acc.h5 ?? 0)%").monospacedDigit()
                        .foregroundStyle(Usage.color(acc.h5, th))
                    Text("\(acc.d7 ?? 0)%").monospacedDigit()
                        .foregroundStyle(Usage.color(acc.d7, th))
                }
            }
        }
        .buttonStyle(.plain)
        .help(acc.active ? "Active account" : "Switch to this account")
        .padding(.horizontal, 12).padding(.vertical, 3)
    }
}
